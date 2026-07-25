/// State for the single onboarding screen (old Flow 0 + Flow A).
///
/// OWNER: P3 (UI). Follows the `ChangeNotifier` shape fixed by ADR-0009.
///
/// ## The hemoglobin field is the safety-critical part of this class
///
/// The prototype shipped the hemoglobin input **prefilled with `11`** and the
/// age input prefilled with `0`. That is not a cosmetic default. A caregiver who
/// does not have her CRED booklet — the exact case ADR-0007 exists for — scrolls
/// past a field that already looks answered, and the app then generates a plan,
/// and reports a coverage percentage, against a number nobody ever measured.
/// The output is indistinguishable from a real personalised plan.
///
/// So: [hemoglobinText] starts empty, its input shows a grey placeholder that is
/// visibly not a value, and [hemoglobin] returns **`null`** for anything that is
/// not a number the user actually typed. `ChildProfile.hemoglobin` is nullable
/// for this reason and the whole app already handles null by producing a
/// standard age-based preventive plan.
///
/// **This holds in edit mode too.** Editing a registered child prefills her
/// name, age, region and sex — but *never* the hemoglobin input. A reading
/// already on file is shown beside the field as read-only text with its date,
/// and the field itself stays empty: what is typed there is a **new** reading
/// from a new CRED check-up, which is the number that actually changes. Leaving
/// it empty keeps the stored reading untouched; it never clears it and never
/// re-saves an old number as if it were today's.
library;

import 'package:flutter/foundation.dart';

import '../../core/domain/child_profile.dart';
import '../../core/settings/caregiver_repository.dart';
import '../../core/storage/repositories.dart';
import 'age_band.dart';

/// Answer to "do you have the CRED booklet at hand?".
enum CredAnswer {
  yes('Sí, lo tengo aquí'),
  no('No lo tengo ahora'),

  /// ADR-0007 requires this third answer explicitly. Without it, a caregiver who
  /// has never heard the booklet called by that name has to guess, and guessing
  /// "no" is the answer that quietly closes a door.
  unknown('No sé qué es eso');

  const CredAnswer(this.label);

  final String label;
}

class OnboardingController extends ChangeNotifier {
  OnboardingController({
    required this.profiles,
    required this.caregivers,
    this.existing,
    DateTime? now,
  }) {
    final child = existing;
    if (child == null) return;

    // Edit mode. Everything the caregiver already told us comes back on the
    // form — except the hemoglobin reading. See the class doc.
    childName = child.name;
    region = child.region;
    sex = child.sex;
    _initialAgeBand = AgeBandMatch.forAgeMonths(
      child.ageMonthsAt(now ?? DateTime.now()),
    );
    ageBand = _initialAgeBand;
    // The field is only on screen when the booklet is at hand, and updating the
    // reading is the main reason to reopen this form, so a child who already
    // has one starts with the question answered "yes" — with the field empty.
    credAnswer = child.hasHemoglobin ? CredAnswer.yes : CredAnswer.unknown;
  }

  final ProfileRepository profiles;
  final CaregiverRepository caregivers;

  /// The child being edited, or null when registering a new one.
  final ChildProfile? existing;

  bool get isEditing => existing != null;

  /// The band derived from the stored birth date, so an untouched age question
  /// can leave the original date alone instead of rounding it to a midpoint.
  AgeBand? _initialAgeBand;

  // --- Answers. ---------------------------------------------------------------

  String childName = '';

  /// Null until the caregiver taps a card. There is no default age: an unpicked
  /// age must block the CTA, not silently become "0 months".
  AgeBand? ageBand;

  /// Optional (Flow A step 3). Null means "prefer not to say", which is stored
  /// as [Sex.unspecified] and changes nothing in the calculation — no iron table
  /// splits by sex before 11 years (ADR-0012).
  Sex? sex;

  Region? region;

  CredAnswer credAnswer = CredAnswer.unknown;

  /// Raw text, never a number, and never prefilled. See the class doc.
  String hemoglobinText = '';

  /// Last, and explicitly optional. The old build gave this its own full screen
  /// to personalise a greeting; a whole screen is too high a price for a
  /// salutation, so it is one field at the bottom of the scroll.
  String caregiverName = '';

  bool _saving = false;
  bool get isSaving => _saving;

  /// Whether the caregiver's own name still has to be asked for.
  ///
  /// **It is asked once and never again.** After the first child exists, the
  /// place to see or change it is the dialog on the Home header — repeating an
  /// optional question every time a sibling is registered is a tax on the
  /// families who have most children to register.
  ///
  /// Starts false so the question cannot flash onto the screen and then vanish
  /// when [load] resolves.
  bool _asksCaregiverName = false;
  bool get asksCaregiverName => _asksCaregiverName;

  /// Reads what the app already knows, so the form does not re-ask it.
  Future<void> load() async {
    if (isEditing) return;

    final registered = await profiles.findAll();
    final storedName = await caregivers.read();
    _asksCaregiverName = registered.isEmpty && storedName == null;
    notifyListeners();
  }

  // --- Derived. ---------------------------------------------------------------

  /// The parsed hemoglobin reading, or **null**.
  ///
  /// Null whenever the caregiver did not give us a usable reading — field left
  /// empty, whitespace only, unparseable, or the booklet not at hand. Never a
  /// fallback number.
  double? get hemoglobin {
    // If she told us she has no booklet, anything left in the field is stale.
    if (credAnswer != CredAnswer.yes) return null;

    final raw = hemoglobinText.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;

    final parsed = double.tryParse(raw);
    if (parsed == null) return null;

    // Outside any physiologically plausible range this is a typo, not a
    // reading. Discarding it beats planning against it.
    if (parsed <= 0 || parsed > 25) return null;

    return parsed;
  }

  /// Only the genuinely required answers gate the CTA.
  ///
  /// Name, age and region — the three the plan cannot be built without. Sex,
  /// hemoglobin and the caregiver's own name are all optional and none of them
  /// may ever block this flow.
  bool get canSubmit =>
      childName.trim().isNotEmpty && ageBand != null && region != null;

  // --- Mutations. -------------------------------------------------------------

  void setChildName(String value) {
    childName = value;
    notifyListeners();
  }

  void setAgeBand(AgeBand value) {
    ageBand = value;
    notifyListeners();
  }

  void setSex(Sex? value) {
    // Tapping the selected card again clears it: "prefer not to say" must be
    // reachable after a mis-tap without restarting the form.
    sex = sex == value ? null : value;
    notifyListeners();
  }

  void setRegion(Region value) {
    region = value;
    notifyListeners();
  }

  void setCredAnswer(CredAnswer value) {
    credAnswer = value;
    // Answering anything but "yes" drops whatever was typed, so a stale digit
    // cannot survive a change of mind.
    if (value != CredAnswer.yes) hemoglobinText = '';
    notifyListeners();
  }

  void setHemoglobinText(String value) {
    hemoglobinText = value;
    notifyListeners();
  }

  void setCaregiverName(String value) {
    caregiverName = value;
    notifyListeners();
  }

  // --- Save. ------------------------------------------------------------------

  /// Persists the child and returns the saved profile, or null if the form is
  /// incomplete.
  ///
  /// In edit mode this writes back over the same id, so the child keeps her
  /// plans: `ProfileRepository.save` upserts.
  Future<ChildProfile?> submit({DateTime? now}) async {
    if (!canSubmit || _saving) return null;

    _saving = true;
    notifyListeners();

    try {
      final today = now ?? DateTime.now();
      final child = existing;

      // Only a *typed* reading. Null when the field was left empty, when the
      // booklet is not at hand, or when what was typed is not a plausible
      // number — this is the line the class doc is about.
      final typedHemoglobin = hemoglobin;

      final profile = ChildProfile(
        id: child?.id ?? 'child-${today.microsecondsSinceEpoch}',
        name: childName.trim(),
        birthDate: _resolveBirthDate(today),
        region: region!,
        sex: sex,
        // A new reading replaces the old one and carries today's date. No new
        // reading leaves whatever was on file exactly as it was — an edit that
        // skipped this field is not a statement that the old reading is wrong.
        hemoglobin: typedHemoglobin ?? child?.hemoglobin,
        hemoglobinDate: typedHemoglobin != null ? today : child?.hemoglobinDate,
      );

      await profiles.save(profile);

      if (_asksCaregiverName) {
        // Null-safe by construction: the repository stores nothing for a name
        // that is blank, so skipping the question stores nothing.
        await caregivers.write(caregiverName);
      }

      return profile;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// The stored birth date when the age answer was not touched, a fresh
  /// estimate when it was.
  ///
  /// The age question is asked in ranges (see [AgeBand]), so re-deriving the
  /// date on every save would drag a real birth date to the midpoint of its
  /// band for no reason — a caregiver correcting a spelling mistake must not
  /// silently change her child's age.
  DateTime _resolveBirthDate(DateTime today) {
    final child = existing;
    if (child != null && ageBand == _initialAgeBand) return child.birthDate;
    return ageBand!.birthDateFrom(today);
  }
}
