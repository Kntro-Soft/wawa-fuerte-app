/// The app's four destinations.
///
/// OWNER: P3 (UI).
///
/// **Four named routes over `Navigator`, and no router package.** `go_router`
/// buys URL parsing, deep links and nested shells; this app has no network, no
/// links to receive, and one linear stack. Adding it would mean a second
/// navigation idiom for four developers to learn in a six-hour sprint, plus a
/// dependency, in exchange for nothing that ships.
///
/// The flows in `docs/FLOWS.md` collapse onto these four:
///
/// - Flow 0 + Flow A → [onboarding], one scrollable screen.
/// - Flow E → [home].
/// - Flow B + Flow D → [plan]: the form, the generating state and the result are
///   one route, because they are one task. A caregiver who waited a minute for
///   the model has not "gone somewhere new" when it finishes.
/// - The per-day detail → [recipe].
library;

abstract final class Routes {
  /// First run only. Merges the old welcome screen into the child's details.
  static const String onboarding = '/onboarding';

  /// Child selector plus this week's status.
  static const String home = '/home';

  /// Form → generating → result, in one route. Expects a [PlanArguments].
  static const String plan = '/plan';

  /// One day's recipe: ingredients, steps, and the listen button. Expects a
  /// [RecipeArguments].
  static const String recipe = '/receta';

  /// History of past weekly plans for a child. Expects a [PlanHistoryArguments].
  static const String planHistory = '/historial';

  /// Detail of a past saved weekly plan. Expects a [PlanHistoryDetailArguments].
  static const String planHistoryDetail = '/historial-detalle';
}
