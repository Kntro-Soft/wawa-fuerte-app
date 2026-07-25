/// The seven-day plan produced for one child, and its iron coverage.
library;

import 'recipe.dart';

class WeeklyPlan {
  const WeeklyPlan({
    required this.childId,
    required this.weekStart,
    required this.days,
    required this.coverage,
  });

  final String childId;
  final DateTime weekStart;

  /// Seven entries, Monday first.
  final List<PlanDay> days;

  final IronCoverage coverage;

  int get preparedCount => days.where((d) => d.prepared).length;
}

class PlanDay {
  const PlanDay({
    required this.dayIndex,
    required this.recipe,
    this.prepared = false,
  });

  /// 0 = Monday … 6 = Sunday.
  final int dayIndex;

  final Recipe recipe;

  /// Ticked by the caregiver. Feeds the follow-up screen (Flow D).
  final bool prepared;

  PlanDay copyWith({bool? prepared}) => PlanDay(
    dayIndex: dayIndex,
    recipe: recipe,
    prepared: prepared ?? this.prepared,
  );
}

/// How much iron the plan supplies against what the child needs.
///
/// This is **arithmetic, never model output** (ADR-0005): the headline number
/// the caregiver acts on must not be hallucinable.
class IronCoverage {
  const IronCoverage({required this.providedMg, required this.requiredMg});

  final double providedMg;
  final double requiredMg;

  /// Percentage of the weekly requirement covered, clamped for display.
  double get percent => requiredMg <= 0
      ? 0
      : (providedMg / requiredMg * 100).clamp(0, 999).toDouble();

  bool get meetsTarget => providedMg >= requiredMg;
}
