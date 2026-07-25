/// Typed arguments for the two routes that take any.
///
/// OWNER: P3 (UI).
///
/// `Navigator`'s `arguments` is an `Object?`, so these classes exist to keep the
/// cast in exactly one place (`onGenerateRoute`) instead of at every push site.
library;

import '../core/domain/child_profile.dart';
import '../core/domain/weekly_plan.dart';
import '../features/plan/plan_controller.dart';

/// Arguments for `Routes.onboarding`: which child is being edited, if any.
///
/// Editing reuses the registration form rather than adding a fifth route
/// (`Routes` documents why there are four). The questions are the same
/// questions; only their starting answers differ, and a second screen asking
/// them again in a different order would be a second thing to learn.
///
/// Null — or no arguments at all — means registering a new child.
class OnboardingArguments {
  const OnboardingArguments({this.child});

  final ChildProfile? child;
}

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


/// Arguments for `Routes.planHistory`: which child's history to show.
class PlanHistoryArguments {
  const PlanHistoryArguments({required this.child});

  final ChildProfile child;
}

/// Arguments for `Routes.planHistoryDetail`: which saved plan and child to show.
class PlanHistoryDetailArguments {
  const PlanHistoryDetailArguments({
    required this.plan,
    required this.child,
  });

  final WeeklyPlan plan;
  final ChildProfile child;
}
