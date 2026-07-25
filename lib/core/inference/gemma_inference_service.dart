/// Real on-device inference through `flutter_gemma` (ADR-0004).
///
/// OWNER: P1.
///
/// The weights are never bundled in the repository (ADR-0004) — this service is
/// handed an absolute path to a `.litertlm` file already present on the device.
/// If that file is missing, [warmUp] throws and the caller is expected to fall
/// back to [FakeInferenceService] rather than leave the user with a dead screen.
library;

import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';

import 'inference_service.dart';
import 'plan_prompt_builder.dart';

class GemmaInferenceService implements InferenceService {
  GemmaInferenceService({
    required this.modelPath,
    this.maxTokens = 1024,
    this.preferredBackend,
  });

  /// Absolute path to the `.litertlm` checkpoint on this device.
  final String modelPath;

  final int maxTokens;

  /// Leave null to let the platform choose. macOS and Android reach the GPU;
  /// the iOS Simulator is CPU-only (Metal there caps a single allocation at
  /// 256 MB), so expect it to be slow rather than fast.
  final PreferredBackend? preferredBackend;

  InferenceModel? _model;

  @override
  bool get isReady => _model != null;

  @override
  Future<void> warmUp() async {
    if (_model != null) return;

    if (!File(modelPath).existsSync()) {
      throw StateError(
        'Gemma weights not found at $modelPath. The .litertlm file is shared '
        'out-of-band and is never committed (ADR-0004).',
      );
    }

    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    ).fromFile(modelPath).install();

    _model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: preferredBackend,
    );
  }

  @override
  Future<String> generatePlanText(PlanPrompt prompt) =>
      generateText(buildPrompt(prompt));

  @override
  Future<String> generateText(String prompt) async {
    await warmUp();
    final model = _model;
    if (model == null) {
      throw StateError('The model failed to load.');
    }

    // A fresh session per request: each call here is one-shot, and carrying
    // conversation history across unrelated requests would only spend context
    // on nothing.
    final session = await model.createSession();
    try {
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      return await session.getResponse();
    } finally {
      await session.close();
    }
  }

  @override
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }

  /// Builds the grounded prompt, asking for the numbered list
  /// [SimplePlanParser] reads back.
  ///
  /// Exposed for testing: prompt wording is load-bearing (ADR-0005), so it is
  /// verified without loading a model.
  static String buildPrompt(PlanPrompt prompt) =>
      buildGroundedPlanPrompt(prompt, responseFormat: _responseFormat);

  /// A bare numbered list. Gemma 3 1B is small enough that asking it for
  /// structured JSON costs accuracy on the part that matters — picking the
  /// right recipes — so the format stays as cheap as the parser allows.
  static const String _responseFormat =
      'Responde solo con 7 líneas numeradas del 1 al 7, una receta por línea, '
      'sin explicaciones ni texto adicional.\n'
      'Ejemplo del formato exacto:\n'
      '1. Nombre de la receta';
}
