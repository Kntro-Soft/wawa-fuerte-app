/// The root [MaterialApp] and the route table.
///
/// OWNER: P1 (`main.dart`) with P3.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/domain/generate_weekly_plan.dart';
import '../core/inference/inference_service.dart';
import '../core/settings/caregiver_repository.dart';
import '../core/storage/repositories.dart';
import '../core/theme/app_theme.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/plan/plan_controller.dart';
import '../features/plan/plan_screen.dart';
import '../features/recipe/recipe_screen.dart';
import '../features/plan/plan_history_controller.dart';
import '../features/plan/plan_history_detail_screen.dart';
import '../features/plan/plan_history_screen.dart';
import 'route_arguments.dart';
import 'routes.dart';

class WawaFuerteApp extends StatelessWidget {
  const WawaFuerteApp({required this.initialRoute, super.key});

  /// [Routes.onboarding] on first run, [Routes.home] once a child exists.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wawa Fuerte',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: initialRoute,
      onGenerateRoute: _onGenerateRoute,
      builder: (context, child) {
        // The app must survive `textScaleFactor` up to 1.5×, so it is clamped
        // there rather than left unbounded: above 1.5 the 88 dp cards and the
        // 64 dp CTA stop fitting side by side on a small screen, and a layout
        // that overflows helps nobody. Below 1.0 is clamped too — a caregiver
        // who has shrunk her system font for a messaging app should not get
        // 14 sp instructions here.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.5,
            ),
          ),
          child: Consumer<InferenceService>(
            builder: (context, inference, body) {
              return Stack(
                children: [
                  body ?? const SizedBox.shrink(),
                  if (inference.isDownloading)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: LinearProgressIndicator(
                          value: (inference.downloadProgress ?? 0) > 0
                              ? (inference.downloadProgress! / 100.0)
                              : null,
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            child: child,
          ),
        );
      },
    );
  }

  /// One cast per route, here and nowhere else.
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.onboarding:
        // Optional: no arguments means "register a new child", which is what
        // the first run and the "Agregar otro niño o niña" button both pass.
        final args = settings.arguments as OnboardingArguments?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            // Route-scoped: adding a second child must start from a blank form,
            // and editing must start from that child's answers.
            create: (context) => OnboardingController(
              profiles: context.read<ProfileRepository>(),
              caregivers: context.read<CaregiverRepository>(),
              existing: args?.child,
            )..load(),
            child: const OnboardingScreen(),
          ),
        );

      case Routes.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );

      case Routes.plan:
        final args = settings.arguments as PlanArguments;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            create: (context) => PlanController(
              generatePlan: context.read<GenerateWeeklyPlan>(),
              plans: context.read<PlanRepository>(),
              child: args.child,
            ),
            child: const PlanScreen(),
          ),
        );

      case Routes.recipe:
        final args = settings.arguments as RecipeArguments;
        // No provider here: the recipe screen is handed the live PlanController
        // through its arguments, because it is pushed above the plan route
        // rather than inside it. See RecipeArguments.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RecipeScreen(arguments: args),
        );

      case Routes.planHistory:
        final args = settings.arguments as PlanHistoryArguments;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            create: (context) => PlanHistoryController(
              plans: context.read<PlanRepository>(),
              child: args.child,
            ),
            child: const PlanHistoryScreen(),
          ),
        );

      case Routes.planHistoryDetail:
        final args = settings.arguments as PlanHistoryDetailArguments;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PlanHistoryDetailScreen(arguments: args),
        );

      default:
        return null;
    }
  }
}
