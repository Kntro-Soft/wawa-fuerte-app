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
import 'core/rag/ins_recipe_retriever.dart';
import 'core/remote/device_reference.dart';
import 'core/remote/qonpania_client.dart';
import 'core/remote/qonpania_config.dart';
import 'core/settings/caregiver_repository.dart';
import 'core/settings/key_value_store.dart';
import 'core/storage/database.dart';
import 'core/storage/sqlite_repositories.dart';

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
  //
  // SQLite, not the in-memory fakes: everything a caregiver enters has to
  // survive closing the app. The whole multi-child model and the weekly
  // follow-up in Flow D are meaningless if the profiles vanish (ADR-0013).
  final database = await openAppDatabase();
  final settings = SqliteKeyValueStore(database);
  final profiles = SqliteProfileRepository(database);
  final plans = SqlitePlanRepository(database);
  final caregivers = SqliteCaregiverRepository.store(settings);
  final retriever = InsRecipeRetriever();

  await retriever.load();
  final registered = await profiles.findAll();

  final pipeline = defaultPlanPipeline(
    qonpania: await _qonpaniaClient(settings, caregivers),
  );

  // Trigger background model preload/download immediately if connected to internet
  // so Gemma is fetched automatically on launch.
  pipeline.inference.warmUp().ignore();

  runApp(
    AppProviders(
      profiles: profiles,
      plans: plans,
      caregivers: caregivers,
      retriever: retriever,
      inference: pipeline.inference,
      parser: pipeline.parser,
      qonpania: await _qonpaniaClient(settings, caregivers),
      child: WawaFuerteApp(
        initialRoute: registered.isEmpty ? Routes.onboarding : Routes.home,
      ),
    ),
  );
}

/// The hosted-agent client, or null when no channel key was compiled in.
///
/// Null is the normal case and the one that keeps ADR-0002 true: without a key
/// the app never opens a socket, and generation stays on-device. See ADR-0015.
Future<QonpaniaClient?> _qonpaniaClient(
  KeyValueStore settings,
  CaregiverRepository caregivers,
) async {
  final config = QonpaniaConfig.fromEnvironment();
  if (!config.isConfigured) return null;

  return QonpaniaClient(
    config: config,
    // Persisted, so the agent sees one returning contact rather than a new one
    // per launch.
    userReference: await resolveDeviceReference(settings),
    // Her own name, if she gave one (Flow 0). Never the child's name, never a
    // hemoglobin reading — those stay on the device.
    caregiverName: await caregivers.read(),
  );
}
