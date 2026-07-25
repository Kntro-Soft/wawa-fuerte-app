/// Entry point.
///
/// OWNER: P1 (@sharvel-irigoyen).
///
/// Two things happen before the first frame, and both are deliberate:
///
/// 1. The recipe corpus is loaded, so the plan screen never has to wait on it.
/// 2. The saved profiles are read, so we know whether this is a first run. That
///    decides `initialRoute` — onboarding once, home forever after — which keeps
///    the app at exactly four routes with no "splash" or "gate" screen in
///    between.
///
/// The model is **not** warmed up here. `InferenceService.warmUp` loads a
/// multi-gigabyte model into memory, and blocking startup on it would give a
/// low-end phone a black screen for a very long time. It is triggered lazily by
/// the first generation, which already has a proper full-screen waiting state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/routes.dart';
import 'core/rag/fake_recipe_retriever.dart';
import 'core/storage/in_memory_repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // flutter_gemma registers NO inference engine by default — they are fully
  // opt-in, and without this the first generation fails with "FlutterGemma not
  // initialized". Cheap: it only registers the engine, it does not touch the
  // weights, so startup stays fast even though the model is over half a gigabyte.
  if (gemmaModelPath.isNotEmpty) {
    await FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]);
  }

  // Constructed here so startup can read from them before the tree exists, then
  // handed to AppProviders — one instance each, no shadowing (ADR-0009).
  final profiles = InMemoryProfileRepository();
  final plans = InMemoryPlanRepository();
  final retriever = FakeRecipeRetriever();

  await retriever.load();
  final registered = await profiles.findAll();

  runApp(
    AppProviders(
      profiles: profiles,
      plans: plans,
      retriever: retriever,
      child: WawaFuerteApp(
        initialRoute: registered.isEmpty ? Routes.onboarding : Routes.home,
      ),
    ),
  );
}
