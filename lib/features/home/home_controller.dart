/// State for the Home screen (Flow E).
///
/// OWNER: P3 (UI). Same `ChangeNotifier` shape as the other two controllers.
///
/// The domain supports **any number of children** and Home is where that shows.
/// Nothing here caps the list or treats the first child as special: a family
/// with three registered children sees three cards and picks one.
library;

import 'package:flutter/foundation.dart';

import '../../core/domain/child_profile.dart';
import '../../core/domain/weekly_plan.dart';
import '../../core/storage/repositories.dart';

class HomeController extends ChangeNotifier {
  HomeController({required this.profiles, required this.plans});

  final ProfileRepository profiles;
  final PlanRepository plans;

  List<ChildProfile> _children = const [];
  List<ChildProfile> get children => _children;

  final Map<String, WeeklyPlan?> _latestPlans = {};

  bool _loading = true;
  bool get isLoading => _loading;

  /// True when there is nobody registered yet — Home's empty state.
  bool get isEmpty => !_loading && _children.isEmpty;

  /// This child's most recent plan, or null if she has never generated one.
  WeeklyPlan? planFor(String childId) => _latestPlans[childId];

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _children = await profiles.findAll();

    // Home shows each child's week status inline, so the plans are fetched up
    // front rather than per card. The list is a handful of children on a local
    // database; there is nothing to paginate.
    _latestPlans.clear();
    for (final child in _children) {
      _latestPlans[child.id] = await plans.latestFor(child.id);
    }

    _loading = false;
    notifyListeners();
  }
}
