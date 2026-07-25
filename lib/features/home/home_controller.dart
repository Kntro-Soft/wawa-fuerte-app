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
import '../../core/settings/caregiver_repository.dart';
import '../../core/storage/repositories.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required this.profiles,
    required this.plans,
    required this.caregivers,
  });

  final ProfileRepository profiles;
  final PlanRepository plans;
  final CaregiverRepository caregivers;

  List<ChildProfile> _children = const [];
  List<ChildProfile> get children => _children;

  /// The caregiver's own name, or null when she never gave one. Null is a
  /// supported case everywhere: the greeting simply drops the name rather than
  /// addressing her as "Usuario".
  String? _caregiverName;
  String? get caregiverName => _caregiverName;

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
    _caregiverName = await caregivers.read();

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

  /// Stores the caregiver's name. Empty clears it — see [CaregiverRepository].
  Future<void> setCaregiverName(String? name) async {
    await caregivers.write(name);
    _caregiverName = await caregivers.read();
    notifyListeners();
  }

  /// Removes a child and everything recorded about her.
  ///
  /// **Irreversible, and the UI must confirm before calling this.** In SQLite
  /// the profile row cascades to the child's plans and their days (ADR-0013),
  /// so this erases her health data completely — which is the intended
  /// behaviour, not a side effect.
  Future<void> deleteChild(String childId) async {
    await profiles.delete(childId);
    _latestPlans.remove(childId);
    _children = await profiles.findAll();
    notifyListeners();
  }
}
