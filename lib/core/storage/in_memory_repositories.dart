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
  final Map<String, WeeklyPlan> _byChildId = {};

  @override
  Future<WeeklyPlan?> latestFor(String childId) async => _byChildId[childId];

  @override
  Future<void> save(WeeklyPlan plan) async {
    _byChildId[plan.childId] = plan;
  }

  @override
  Future<void> markPrepared({
    required String childId,
    required DateTime weekStart,
    required int dayIndex,
    required bool prepared,
  }) async {
    final plan = _byChildId[childId];
    if (plan == null || plan.weekStart != weekStart) return;

    _byChildId[childId] = WeeklyPlan(
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
