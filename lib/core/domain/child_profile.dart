/// The child a plan is generated for.
///
/// Owned by P4 (storage) as a persisted entity, but the type itself is shared:
/// every module reads it, so it lives in `core/domain`.
library;

enum Region { coast, highlands, jungle }

enum Sex { male, female, unspecified }

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.region,
    this.sex,
    this.hemoglobin,
    this.hemoglobinDate,
  });

  final String id;
  final String name;
  final DateTime birthDate;
  final Region region;
  final Sex? sex;

  /// Hemoglobin in g/dL, read by the caregiver from the paper CRED booklet.
  ///
  /// **Always nullable — see ADR-0007.** Not every family has the booklet at
  /// hand, and the iron requirement is derived from age, not from this value.
  /// Code must never assume it is present: when it is null the app produces a
  /// standard age-based preventive plan instead of failing or blocking.
  final double? hemoglobin;

  /// When [hemoglobin] was measured. Shown as a freshness hint to the user.
  final DateTime? hemoglobinDate;

  bool get hasHemoglobin => hemoglobin != null;

  /// Age in whole months, which is what the INS/WHO requirement tables key on.
  int ageMonthsAt(DateTime now) {
    var months =
        (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    if (now.day < birthDate.day) months--;
    return months < 0 ? 0 : months;
  }

  ChildProfile copyWith({
    String? name,
    DateTime? birthDate,
    Region? region,
    Sex? sex,
    double? hemoglobin,
    DateTime? hemoglobinDate,
  }) {
    return ChildProfile(
      id: id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      region: region ?? this.region,
      sex: sex ?? this.sex,
      hemoglobin: hemoglobin ?? this.hemoglobin,
      hemoglobinDate: hemoglobinDate ?? this.hemoglobinDate,
    );
  }
}
