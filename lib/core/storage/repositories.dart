/// Local persistence. There is no server and nothing syncs (ADR-0002).
///
/// OWNER: P4 (@Eric396).
///
/// This holds health data about minors, which is precisely why it never leaves
/// the device.
library;

import '../domain/child_profile.dart';
import '../domain/weekly_plan.dart';

abstract interface class ProfileRepository {
  /// Every child registered on this phone. A family may register several
  /// children; there is no limit.
  Future<List<ChildProfile>> findAll();

  Future<ChildProfile?> findById(String id);

  Future<void> save(ChildProfile profile);

  Future<void> delete(String id);
}

abstract interface class PlanRepository {
  /// Most recent plan for a child, or null if none was ever generated.
  Future<WeeklyPlan?> latestFor(String childId);

  /// All historical plans for a child, ordered by weekStart descending.
  Future<List<WeeklyPlan>> findAllFor(String childId);

  Future<void> save(WeeklyPlan plan);

  /// Records whether a given day's recipe was actually prepared. Feeds the
  /// weekly follow-up (Flow D).
  Future<void> markPrepared({
    required String childId,
    required DateTime weekStart,
    required int dayIndex,
    required bool prepared,
  });
}
