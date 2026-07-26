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
import '../core/inference/connectivity_monitor.dart';
import '../core/inference/hybrid_inference_service.dart';
import '../core/inference/inference_service.dart';
import '../core/inference/inference_status.dart';
import '../core/inference/qonpania_inference_service.dart';
import '../core/nutrition/iron_calculator.dart';
import '../core/nutrition/table_iron_calculator.dart';
import '../core/rag/ins_recipe_retriever.dart';
import '../core/rag/qonpania_plan_parser.dart';
import '../core/rag/recipe_retriever.dart';
import '../core/rag/simple_plan_parser.dart';
import '../core/remote/qonpania_client.dart';
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
    this.qonpania,
    super.key,
  });

  final Widget child;
  final ProfileRepository? profiles;
  final PlanRepository? plans;
  final CaregiverRepository? caregivers;
  final RecipeRetriever? retriever;
  final InferenceService? inference;
  final PlanParser? parser;

  /// Non-null only when a channel key was supplied at build time, and only ever
  /// constructed in `main()` — the tree never opens a socket on its own.
  final QonpaniaClient? qonpania;

  @override
  Widget build(BuildContext context) {
    final profileRepository = profiles ?? InMemoryProfileRepository();
    final planRepository = plans ?? InMemoryPlanRepository();
    final caregiverRepository = caregivers ?? InMemoryCaregiverRepository();
    final recipeRetriever = retriever ?? InsRecipeRetriever();
    final pipeline = defaultPlanPipeline(qonpania: qonpania);
    // Overriding one half is allowed: a widget test injecting the fake service
    // against `QonpaniaPlanParser` still works, because that parser falls back
    // to `SimplePlanParser` on anything that is not its JSON envelope.
    final inferenceService = inference ?? pipeline.inference;
    final planParser = parser ?? pipeline.parser;
    const calculator = TableIronCalculator();

    return MultiProvider(
      providers: [
        // --- Stateless collaborators, constructed once. ---------------------
        Provider<ProfileRepository>.value(value: profileRepository),
        Provider<PlanRepository>.value(value: planRepository),
        Provider<CaregiverRepository>.value(value: caregiverRepository),
        Provider<RecipeRetriever>.value(value: recipeRetriever),
        Provider<InferenceService>.value(value: inferenceService),
        // The listenable view the shell rebuilds on. Always present, whatever
        // the service is, so the status indicator is never frozen.
        ChangeNotifierProvider<InferenceStatus>(
          create: (_) => InferenceStatus(inferenceService),
        ),
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

/// Default public URL to download the Gemma .litertlm model when no path is passed at build time.
const defaultGemmaModelUrl =
    'https://huggingface.co/litert-community/gemma-2b-it-litertlm/resolve/main/gemma-2b-it-cpu-int4.litertlm';

/// Path or URL to the Gemma checkpoint, supplied at build time:
///
/// ```
/// flutter run --dart-define=GEMMA_MODEL_PATH=https://.../model.litertlm
/// ```
///
/// Defaults to [defaultGemmaModelUrl] so Android builds automatically download
/// and cache the weights on first run instead of falling back to FakeInferenceService.
const gemmaModelPath = String.fromEnvironment(
  'GEMMA_MODEL_PATH',
  defaultValue: defaultGemmaModelUrl,
);

/// Where a plan comes from, and how its text is read back.
///
/// The two travel together on purpose. Each generator is asked for a different
/// response format — Gemma for a numbered list, the hosted agent for a JSON
/// envelope — and pairing the wrong parser with a generator does not throw, it
/// silently produces a week of padding. Making the pair one value means the
/// choice is made once, here.
class PlanPipeline {
  const PlanPipeline({required this.inference, required this.parser});

  final InferenceService inference;
  final PlanParser parser;
}

/// The best available generator: the hosted agent if a key was supplied
/// (ADR-0015), on-device Gemma if a checkpoint was, the fake otherwise.
///
/// The fake stays the default so that `flutter test`, CI, and any developer
/// with neither a key nor the 557 MB file still get a running app — which is
/// the whole reason [InferenceService] is an interface (ADR-0004).
PlanPipeline defaultPlanPipeline({
  QonpaniaClient? qonpania,
  ConnectivityMonitor? connectivity,
}) {
  final localInference = gemmaModelPath.isEmpty
      ? FakeInferenceService()
      : GemmaInferenceService(modelPath: gemmaModelPath);

  // Always hybrid, even with no hosted key. Two reasons, both learned the hard
  // way on a real phone:
  //
  // 1. It is the only `InferenceService` that is a `ChangeNotifier`, and
  //    without one the status indicator is computed once and then frozen —
  //    it kept reading "Nube" after the signal was gone.
  // 2. It owns the connectivity subscription, so the mode follows the radio
  //    rather than waiting for a request to fail.
  return PlanPipeline(
    inference: HybridInferenceService(
      primary: qonpania == null ? null : QonpaniaInferenceService(qonpania),
      fallback: localInference,
      connectivity: connectivity ?? ConnectivityMonitor(),
    ),
    parser: qonpania == null
        ? const SimplePlanParser()
        : const QonpaniaPlanParser(),
  );
}
