/// Typed arguments for the two routes that take any.
///
/// OWNER: P3 (UI).
///
/// `Navigator`'s `arguments` is an `Object?`, so these classes exist to keep the
/// cast in exactly one place (`onGenerateRoute`) instead of at every push site.
library;

import '../core/domain/child_profile.dart';
import '../features/plan/plan_controller.dart';

/// Arguments for `Routes.plan`: which child the week is for.
class PlanArguments {
  const PlanArguments({required this.child});

  final ChildProfile child;
}

/// Arguments for `Routes.recipe`: which day of the open plan to show.
///
/// The [controller] is passed by reference rather than looked up from the widget
/// tree because the recipe route is pushed *on top of* the plan route, and the
/// plan's `ChangeNotifierProvider` sits below the pushed page in the navigator
/// stack, not above it. Handing the controller over keeps the "Ya lo preparé"
/// toggle writing to the same instance the plan screen is reading from, so
/// popping back shows the change already applied.
class RecipeArguments {
  const RecipeArguments({required this.controller, required this.dayIndex});

  final PlanController controller;

  /// 0 = Monday … 6 = Sunday, matching `PlanDay.dayIndex`.
  final int dayIndex;
}
