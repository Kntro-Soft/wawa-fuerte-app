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
library;

import 'package:flutter/foundation.dart';

import '../../core/domain/child_profile.dart';
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
  OnboardingController({required this.profiles});

  final ProfileRepository profiles;

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
  Future<ChildProfile?> submit({DateTime? now}) async {
    if (!canSubmit || _saving) return null;

    _saving = true;
    notifyListeners();

    try {
      final today = now ?? DateTime.now();
      final profile = ChildProfile(
        id: 'child-${today.microsecondsSinceEpoch}',
        name: childName.trim(),
        birthDate: ageBand!.birthDateFrom(today),
        region: region!,
        sex: sex,
        // Null unless she actually gave us a reading. This is the line the
        // class doc is about.
        hemoglobin: hemoglobin,
        hemoglobinDate: hemoglobin == null ? null : today,
      );

      await profiles.save(profile);
      return profile;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
