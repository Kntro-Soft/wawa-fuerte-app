/// A date written the way it is said in Spanish.
///
/// OWNER: P3 (UI).
///
/// `intl` is not a dependency and adding one for a single format string is not
/// worth the merge conflict on `pubspec.yaml` (AGENTS.md). More to the point,
/// `intl`'s locale data would have to be loaded, and this app runs offline on
/// low-end phones where every asset costs.
///
/// **"12 de marzo de 2026", never "12/03/2026".** A numeric date is ambiguous
/// between day-first and month-first and it has to be decoded; the month's name
/// is read.
library;

const List<String> _months = <String>[
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'setiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String spanishDate(DateTime date) {
  final month = _months[(date.month - 1) % 12];
  return '${date.day} de $month de ${date.year}';
}
