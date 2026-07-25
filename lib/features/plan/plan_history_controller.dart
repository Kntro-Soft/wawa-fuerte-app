/// State for the Plan History screen (Flow D / Histórico).
///
/// OWNER: P3 (UI).
library;

import "package:flutter/foundation.dart";

import "../../core/domain/child_profile.dart";
import "../../core/domain/weekly_plan.dart";
import "../../core/storage/repositories.dart";

class PlanHistoryController extends ChangeNotifier {
  PlanHistoryController({
    required this.plans,
    required this.child,
  }) {
    load();
  }

  final PlanRepository plans;
  final ChildProfile child;

  bool _loading = true;
  bool get isLoading => _loading;

  List<WeeklyPlan> _history = const [];
  List<WeeklyPlan> get history => _history;

  bool get isEmpty => !_loading && _history.isEmpty;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _history = await plans.findAllFor(child.id);

    _loading = false;
    notifyListeners();
  }
}
