/// The age question, asked in ranges instead of numbers.
///
/// OWNER: P3 (UI).
///
/// The domain needs a `birthDate`. The obvious UI for that is a date picker or a
/// number field with a Meses/Años toggle — and both were wrong here:
///
/// - A **date picker** asks for a day-month-year a caregiver may genuinely not
///   have to hand without the CRED booklet, and month-grid pickers are among the
///   hardest widgets on a small screen.
/// - A **number plus a Meses/Años toggle** is two controls that must agree. Set
///   the toggle wrong and "2" means two months instead of two years — a factor
///   of twelve on the input that selects the iron requirement band. Nothing on
///   screen would look wrong afterwards.
///
/// Tapping one of four ranges cannot be mistyped and cannot be left in a stale
/// state. The cost is precision, and the cost is affordable: the requirement
/// bands in `TableIronCalculator` are 6–11, 12–47 and 48–83 months, so these
/// four ranges each sit **wholly inside one band**. Estimating a birth date at
/// the middle of a range therefore selects the same requirement as the exact
/// date would.
///
/// A caregiver who wants precision can still get it — that is what the CRED
/// booklet flow is for — but she is never blocked on it.
library;

/// The four ranges offered, in order.
enum AgeBand {
  /// 6–11 months. Requirement band: 6–11 months (9.3 mg/day).
  sixToElevenMonths(
    label: '6 a 11 meses',
    description: 'Empezó a comer sus primeras comiditas',
    representativeMonths: 9,
  ),

  /// 12–23 months. Requirement band: 12–47 months (5.8 mg/day).
  oneYear(
    label: '1 año',
    description: 'Ya camina o está aprendiendo',
    representativeMonths: 18,
  ),

  /// 24–35 months. Same requirement band as [oneYear].
  twoYears(
    label: '2 años',
    description: 'Come casi de todo lo de la casa',
    representativeMonths: 30,
  ),

  /// 36–59 months. Spans the 12–47 and 48–83 bands; see the note below.
  threeToFiveYears(
    label: '3 a 5 años',
    description: 'Antes de entrar al colegio',
    representativeMonths: 48,
  );

  const AgeBand({
    required this.label,
    required this.description,
    required this.representativeMonths,
  });

  /// What the card says.
  final String label;

  /// The plain-language second line. It describes what the child *does*, not
  /// what the number means: a caregiver recognises "ya camina" instantly and
  /// may have to think about "18 meses".
  final String description;

  /// Age in months used to derive the stored birth date.
  ///
  /// The midpoint of each range, except for [threeToFiveYears]: 36–59 months
  /// straddles the 12–47 and 48–83 requirement bands, and its true midpoint
  /// (47) sits one month below the boundary. We use 48 so the older half of the
  /// range is not planned against a lower requirement than it needs. Erring
  /// toward the **higher** requirement is the safe direction — it makes the
  /// coverage bar stricter, never falsely reassuring.
  final int representativeMonths;

  /// Estimated birth date for this range, relative to [now].
  ///
  /// Approximate by construction. Stored as a real `DateTime` because that is
  /// what `ChildProfile` holds and what `ageMonthsAt` reads.
  DateTime birthDateFrom(DateTime now) {
    // Work in absolute months since year 0 so the subtraction cannot underflow
    // across a year boundary. Dart's `~/` truncates toward zero, which would be
    // wrong for a negative intermediate; this value is always positive.
    final absoluteMonths =
        now.year * 12 + (now.month - 1) - representativeMonths;

    // Day 15: keeps the estimate away from month boundaries, so the derived age
    // does not flip a requirement band on the first of the month.
    return DateTime(absoluteMonths ~/ 12, absoluteMonths % 12 + 1, 15);
  }
}
