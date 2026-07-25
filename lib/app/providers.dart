/// The dependency graph, assembled in exactly one place.
///
/// OWNER: P1 (`main.dart`) with P3.
///
/// ADR-0009 requires this: Provider resolves by runtime type, so registering two
/// providers of the same type anywhere in the tree silently shadows one of them
/// and the bug shows up as a screen reading the wrong instance. Keeping the
/// whole graph here makes that impossible to do by accident.
///
/// Real by default: [InsRecipeRetriever] reads the bundled INS corpus
/// (ADR-0011) and [TableIronCalculator] uses the published INS/FAO-WHO figures
/// (ADR-0012) — faking the clinically meaningful parts would defeat the point
/// of having sourced them. Inference stays behind [defaultInferenceService]:
/// real Gemma needs its `.litertlm` checkpoint, which is never committed
/// (ADR-0004), so it only activates when `GEMMA_MODEL_PATH` is supplied and
/// falls back to `FakeInferenceService` otherwise — the reason `flutter test`
/// and any developer without the 557 MB file still get a running app.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/domain/generate_weekly_plan.dart';
import '../core/inference/fake_inference_service.dart';
import '../core/inference/gemma_inference_service.dart';
import '../core/inference/inference_service.dart';
import '../core/nutrition/iron_calculator.dart';
import '../core/nutrition/table_iron_calculator.dart';
import '../core/rag/ins_recipe_retriever.dart';
import '../core/rag/recipe_retriever.dart';
import '../core/rag/simple_plan_parser.dart';
import '../core/settings/caregiver_repository.dart';
import '../core/storage/in_memory_repositories.dart';
import '../core/storage/repositories.dart';
import '../features/home/home_controller.dart';

/// Builds the app-wide providers.
///
/// Optional parameters exist so widget tests can inject their own doubles
/// without going through `main()`.
class AppProviders extends StatelessWidget {
  const AppProviders({
    required this.child,
    this.profiles,
    this.plans,
    this.caregivers,
    this.retriever,
    this.inference,
    this.parser,
    super.key,
  });

  final Widget child;
  final ProfileRepository? profiles;
  final PlanRepository? plans;
  final CaregiverRepository? caregivers;
  final RecipeRetriever? retriever;
  final InferenceService? inference;
  final PlanParser? parser;

  @override
  Widget build(BuildContext context) {
    final profileRepository = profiles ?? InMemoryProfileRepository();
    final planRepository = plans ?? InMemoryPlanRepository();
    final caregiverRepository = caregivers ?? InMemoryCaregiverRepository();
    final recipeRetriever = retriever ?? InsRecipeRetriever();
    final inferenceService = inference ?? defaultInferenceService();
    final planParser = parser ?? const SimplePlanParser();
    const calculator = TableIronCalculator();

    return MultiProvider(
      providers: [
        // --- Stateless collaborators, constructed once. ---------------------
        Provider<ProfileRepository>.value(value: profileRepository),
        Provider<PlanRepository>.value(value: planRepository),
        Provider<CaregiverRepository>.value(value: caregiverRepository),
        Provider<RecipeRetriever>.value(value: recipeRetriever),
        Provider<InferenceService>.value(value: inferenceService),
        Provider<PlanParser>.value(value: planParser),
        Provider<IronCalculator>.value(value: calculator),

        // --- The one place all four modules meet. ---------------------------
        Provider<GenerateWeeklyPlan>(
          create: (_) => GenerateWeeklyPlan(
            retriever: recipeRetriever,
            inference: inferenceService,
            calculator: calculator,
            plans: planRepository,
            parser: planParser,
          ),
        ),

        // --- Feature controllers. -------------------------------------------
        //
        // Home is app-scoped because it is returned to constantly and its list
        // must survive a pop. Onboarding and Plan are route-scoped instead —
        // both should start clean every time they are opened, and Plan needs a
        // `ChildProfile` that only exists once a child has been picked.
        ChangeNotifierProvider<HomeController>(
          create: (_) => HomeController(
            profiles: profileRepository,
            plans: planRepository,
            caregivers: caregiverRepository,
          ),
        ),
      ],
      child: child,
    );
  }
}

/// Path to the Gemma checkpoint, supplied at build time:
///
/// ```
/// flutter run --dart-define=GEMMA_MODEL_PATH=/absolute/path/model.litertlm
/// ```
///
/// The weights are never committed (ADR-0004), so there is no sensible default.
const gemmaModelPath = String.fromEnvironment('GEMMA_MODEL_PATH');

/// Real inference when a checkpoint was supplied, the fake otherwise.
///
/// This keeps the fake as the default so that `flutter test`, CI, and any
/// developer without the 557 MB file still get a running app — which is the
/// whole reason [InferenceService] is an interface (ADR-0004).
InferenceService defaultInferenceService() {
  if (gemmaModelPath.isEmpty) return FakeInferenceService();
  return GemmaInferenceService(modelPath: gemmaModelPath);
}
