/// In-memory repositories for UI development and tests.
///
/// P4 replaces these with the SQLite implementations; until then P3 can build
/// every screen against real types with real behaviour, just without a disk.
library;

import '../domain/child_profile.dart';
import '../domain/weekly_plan.dart';
import 'repositories.dart';

class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository([List<ChildProfile> seed = const []]) {
    for (final p in seed) {
      _byId[p.id] = p;
    }
  }

  final Map<String, ChildProfile> _byId = {};

  @override
  Future<List<ChildProfile>> findAll() async => _byId.values.toList();

  @override
  Future<ChildProfile?> findById(String id) async => _byId[id];

  @override
  Future<void> save(ChildProfile profile) async {
    _byId[profile.id] = profile;
  }

  @override
  Future<void> delete(String id) async {
    _byId.remove(id);
  }
}

class InMemoryPlanRepository implements PlanRepository {
  final Map<String, List<WeeklyPlan>> _byChildId = {};

  @override
  Future<WeeklyPlan?> latestFor(String childId) async {
    final list = _byChildId[childId];
    if (list == null || list.isEmpty) return null;
    final sorted = List<WeeklyPlan>.from(list)
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return sorted.first;
  }

  @override
  Future<List<WeeklyPlan>> findAllFor(String childId) async {
    final list = _byChildId[childId];
    if (list == null || list.isEmpty) return const [];
    final sorted = List<WeeklyPlan>.from(list)
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return sorted;
  }

  @override
  Future<void> save(WeeklyPlan plan) async {
    final list = _byChildId.putIfAbsent(plan.childId, () => []);
    list.removeWhere((p) => p.weekStart == plan.weekStart);
    list.add(plan);
  }

  @override
  Future<void> markPrepared({
    required String childId,
    required DateTime weekStart,
    required int dayIndex,
    required bool prepared,
  }) async {
    final list = _byChildId[childId];
    if (list == null) return;
    final index = list.indexWhere((p) => p.weekStart == weekStart);
    if (index == -1) return;
    final plan = list[index];

    list[index] = WeeklyPlan(
      childId: plan.childId,
      weekStart: plan.weekStart,
      days: [
        for (final day in plan.days)
          day.dayIndex == dayIndex ? day.copyWith(prepared: prepared) : day,
      ],
      coverage: plan.coverage,
    );
  }
}
