/// Weekday names in Spanish, indexed the way the domain indexes them.
///
/// OWNER: P3 (UI).
///
/// `PlanDay.dayIndex` is documented as 0 = Monday … 6 = Sunday, so this list is
/// ordered to match and is looked up directly by that index.
///
/// **The UI says "Lunes", never "Día 1".** A caregiver does not plan her week in
/// ordinals — she knows what today is, and she needs to find today's row without
/// counting. "Día 3" also forces the question "day 3 counting from when?", which
/// is exactly the kind of small doubt that stops someone from using an app while
/// a pot is on the fire.
library;

abstract final class DayNames {
  static const List<String> _names = <String>[
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  /// Name for a `PlanDay.dayIndex`. Wraps defensively rather than throwing:
  /// a bad index should not take down the plan screen.
  static String of(int dayIndex) => _names[dayIndex % _names.length];
}
