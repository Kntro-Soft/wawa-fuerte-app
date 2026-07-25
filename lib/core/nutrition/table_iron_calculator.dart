/// Table-driven [IronCalculator] backed by official requirement figures.
///
/// OWNER: P2 (@jhosepmyr).
///
/// **Every number in this file is copied from a published source and carries
/// the citation next to it.** Nothing here is estimated, interpolated or
/// rounded by hand: the coverage percentage is what a caregiver feeds a child
/// on, so an invented figure would be a clinical defect, not a cosmetic one.
/// See [ADR-0012](../../../docs/adr/0012-iron-requirement-tables.md).
library;

import '../domain/child_profile.dart';
import '../domain/recipe.dart';
import '../domain/weekly_plan.dart';
import 'iron_calculator.dart';

/// Iron requirements from the INS/FAO/WHO age bands, with coverage computed in
/// plain Dart arithmetic (ADR-0005 — this number is never model output).
class TableIronCalculator implements IronCalculator {
  const TableIronCalculator();

  /// Youngest age with a published dietary iron requirement.
  ///
  /// The FAO/WHO table starts at 0.5 years; below that the requirement is met
  /// by fetal iron stores and breast milk, so no *dietary* intake figure is
  /// published at all. It also coincides with the age at which MINSA/INS start
  /// preventive supplementation and complementary feeding in Peru, which is why
  /// Wawa Fuerte targets 6–59 months.
  ///
  /// Source: INS — «Suplementación con micronutrientes para niños de 6 a 35
  /// meses de edad», https://anemia.ins.gob.pe/suplementacion-con-micronutrientes-para-ninos-de-6-35-meses-de-edad
  static const int minSupportedAgeMonths = 6;

  /// Oldest age this table covers: the end of the FAO/WHO "7–10 years" band.
  ///
  /// From 11 years the published figures split by sex *and* by menarche status,
  /// which this app cannot know and does not need — its population is 6–59
  /// months. Rather than guess, ages above this report no requirement.
  static const int maxSupportedAgeMonths = 131; // 10 years, 11 months.

  /// Bioavailability assumption behind the figures in [_bands].
  ///
  /// The FAO/WHO consultation publishes the same requirement at 5%, 10%, 12%
  /// and 15% dietary iron bioavailability and states: "For developing countries,
  /// it may be realistic to use the figures of 5 percent and 10 percent."
  /// (FAO/WHO, chapter 13, p. 208). Peru's INS reprints exactly those columns as
  /// Alta (15%) / Moderada (10%) / Baja (5%).
  ///
  /// We use **10% (Moderada)**, the more optimistic of the two levels FAO/WHO
  /// endorses for developing countries, because the corpus this app plans from
  /// is the INS anti-anemia recipe book, which is built around heme iron
  /// (sangrecita, hígado, bazo) plus ascorbic-acid-rich accompaniments — the
  /// exact combination FAO/WHO lists as raising absorption above the 5% floor.
  static const double assumedBioavailability = 0.10;

  /// Daily dietary iron requirement per age band, in mg/day.
  ///
  /// PRIMARY SOURCE (Peruvian): Instituto Nacional de Salud — «Requerimientos
  /// nutricionales» → "Recomendaciones para el consumo de Minerales para la
  /// Población Infantil de 0 a 11 años", column «HIERRO (mg/día)», sub-column
  /// «10% (Moderada)».
  /// https://alimentacionsaludable.ins.gob.pe/ninos-y-ninas/requerimientos-nutricionales
  ///
  /// UPSTREAM SOURCE (identical figures, used to resolve the band edges the INS
  /// page renders in years): FAO/WHO expert consultation on human vitamin and
  /// mineral requirements, 2nd ed., chapter 13 "Iron", Table 40 "The recommended
  /// nutrient intakes for iron based on varying dietary iron bio-availabilities",
  /// p. 197. https://www.fao.org/4/y2809e/y2809e13.pdf
  ///
  /// The INS page labels the first band "7 a 11 meses"; FAO/WHO Table 40 gives
  /// it as "0.5–1" years, i.e. it starts at 6 months. We follow the upstream
  /// FAO/WHO boundary so that a 6-month-old — the age at which INS begins
  /// complementary feeding and supplementation — is covered.
  static const List<_RequirementBand> _bands = <_RequirementBand>[
    // FAO/WHO Table 40, "Children 0.5–1" years (mean body weight 9 kg):
    // 15% = 6.2 · 12% = 7.7 · 10% = 9.3 · 5% = 18.6 mg/day.
    // Table 40 brackets this row with footnote b: "Bio-availability of dietary
    // iron during this period varies greatly."
    _RequirementBand(minAgeMonths: 6, maxAgeMonths: 11, dailyMg: 9.3),

    // FAO/WHO Table 40, "Children 1–3" years (13.3 kg):
    // 15% = 3.9 · 12% = 4.8 · 10% = 5.8 · 5% = 11.6 mg/day.
    _RequirementBand(minAgeMonths: 12, maxAgeMonths: 47, dailyMg: 5.8),

    // FAO/WHO Table 40, "Children 4–6" years (19.2 kg):
    // 15% = 4.2 · 12% = 5.3 · 10% = 6.3 · 5% = 12.6 mg/day.
    _RequirementBand(minAgeMonths: 48, maxAgeMonths: 83, dailyMg: 6.3),

    // FAO/WHO Table 40, "Children 7–10" years (28.1 kg):
    // 15% = 5.9 · 12% = 7.4 · 10% = 8.9 · 5% = 17.8 mg/day.
    // Outside the app's 6–59 month population; kept so an over-aged sibling
    // entered by mistake still gets a sourced figure instead of a wrong one.
    _RequirementBand(minAgeMonths: 84, maxAgeMonths: 131, dailyMg: 8.9),
  ];

  /// Whether an official figure exists for [ageMonths].
  ///
  /// False below 6 months and above 10 years — see [minSupportedAgeMonths] and
  /// [maxSupportedAgeMonths]. Callers that display a coverage percentage should
  /// check this first: outside the range the calculator reports a requirement of
  /// zero, which means "not published", **not** "needs no iron".
  bool hasOfficialRequirement(int ageMonths) => _bandFor(ageMonths) != null;

  /// Daily dietary iron requirement in mg, or 0 when no official figure exists.
  double dailyRequirementMg(int ageMonths, [Sex? sex]) =>
      _bandFor(ageMonths)?.dailyMg ?? 0;

  @override
  double weeklyRequirementMg(int ageMonths, Sex? sex) {
    // [sex] is deliberately ignored. Neither the INS table nor FAO/WHO Table 40
    // splits iron requirements by sex before 11 years of age; the split appears
    // only once menstrual losses enter the calculation. Honouring the parameter
    // with a fabricated adjustment would be worse than ignoring it. The
    // parameter stays in the interface because the profile may carry it and
    // future age bands would need it.
    return dailyRequirementMg(ageMonths, sex) * 7;
  }

  @override
  IronCoverage coverageOf({
    required List<Recipe> recipes,
    required int ageMonths,
    Sex? sex,
  }) {
    // Pure arithmetic over the nutrient data bundled with each INS recipe.
    // One serving per recipe, one recipe per day of the plan (ADR-0005).
    final providedMg = recipes.fold<double>(
      0,
      (total, recipe) => total + recipe.ironMg,
    );

    return IronCoverage(
      providedMg: providedMg,
      requiredMg: weeklyRequirementMg(ageMonths, sex),
    );
  }

  static _RequirementBand? _bandFor(int ageMonths) {
    for (final band in _bands) {
      if (ageMonths >= band.minAgeMonths && ageMonths <= band.maxAgeMonths) {
        return band;
      }
    }
    return null;
  }
}

/// One row of the official requirement table, in whole months.
class _RequirementBand {
  const _RequirementBand({
    required this.minAgeMonths,
    required this.maxAgeMonths,
    required this.dailyMg,
  });

  /// Inclusive lower bound, in whole months.
  final int minAgeMonths;

  /// Inclusive upper bound, in whole months.
  final int maxAgeMonths;

  /// Dietary iron, mg/day, at [TableIronCalculator.assumedBioavailability].
  final double dailyMg;
}
