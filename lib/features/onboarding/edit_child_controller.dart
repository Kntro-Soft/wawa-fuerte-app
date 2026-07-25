import 'package:flutter/foundation.dart';

import '../../core/domain/child_profile.dart';
import '../../core/storage/repositories.dart';
import 'age_band.dart';
import 'onboarding_controller.dart';

class EditChildController extends ChangeNotifier {
  EditChildController({
    required this.profiles,
    required this.child,
    DateTime? now,
  }) {
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
  final ChildProfile child;

  AgeBand? _initialAgeBand;

  // --- Answers. ---------------------------------------------------------------

  String childName = '';
  AgeBand? ageBand;
  Sex? sex;
  Region? region;
  CredAnswer credAnswer = CredAnswer.unknown;
  String hemoglobinText = '';

  bool _saving = false;
  bool get isSaving => _saving;

  bool _deleting = false;
  bool get isDeleting => _deleting;

  // --- Derived. ---------------------------------------------------------------

  double? get hemoglobin {
    if (credAnswer != CredAnswer.yes) return null;

    final raw = hemoglobinText.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;

    final parsed = double.tryParse(raw);
    if (parsed == null) return null;

    if (parsed <= 0 || parsed > 25) return null;

    return parsed;
  }

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
    sex = sex == value ? null : value;
    notifyListeners();
  }

  void setRegion(Region value) {
    region = value;
    notifyListeners();
  }

  void setCredAnswer(CredAnswer value) {
    credAnswer = value;
    if (value != CredAnswer.yes) hemoglobinText = '';
    notifyListeners();
  }

  void setHemoglobinText(String value) {
    hemoglobinText = value;
    notifyListeners();
  }

  // --- Save / Delete. ---------------------------------------------------------

  Future<ChildProfile?> submit({DateTime? now}) async {
    if (!canSubmit || _saving) return null;

    _saving = true;
    notifyListeners();

    try {
      final today = now ?? DateTime.now();
      final typedHemoglobin = hemoglobin;

      final profile = ChildProfile(
        id: child.id,
        name: childName.trim(),
        birthDate: _resolveBirthDate(today),
        region: region!,
        sex: sex,
        hemoglobin: typedHemoglobin ?? child.hemoglobin,
        hemoglobinDate: typedHemoglobin != null ? today : child.hemoglobinDate,
      );

      await profiles.save(profile);
      return profile;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> delete() async {
    if (_saving || _deleting) return false;

    _deleting = true;
    notifyListeners();

    try {
      await profiles.delete(child.id);
      return true;
    } finally {
      _deleting = false;
      notifyListeners();
    }
  }

  DateTime _resolveBirthDate(DateTime today) {
    if (ageBand == _initialAgeBand) return child.birthDate;
    return ageBand!.birthDateFrom(today);
  }
}
