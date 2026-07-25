/// Generation through the hosted nutrition agent (ADR-0015).
///
/// OWNER: P1 (@sharvel-irigoyen).
///
/// The third implementation of [InferenceService], and the reason that seam was
/// worth having: `GenerateWeeklyPlan` does not learn that a plan can now come
/// off the device. What changes is only *where* the text is generated — the
/// grounding prompt is the same one Gemma gets (`plan_prompt_builder.dart`) and
/// the iron arithmetic is still local (ADR-0005).
///
/// It asks for a different **response format** than Gemma does, because it can:
/// the hosted agent is a far larger model and holds a strict-JSON envelope
/// reliably, which carries ingredients and preparation steps a bare numbered
/// list cannot. [QonpaniaPlanParser] is the matching reader.
library;

import '../remote/qonpania_client.dart';
import 'inference_service.dart';
import 'plan_prompt_builder.dart';

class QonpaniaInferenceService implements InferenceService {
  QonpaniaInferenceService(this._client);

  final QonpaniaClient _client;

  @override
  bool get isReady => _client.hasSession;

  @override
  ActiveInferenceMode get activeMode => ActiveInferenceMode.cloud;

  /// Opens the session. Cheap next to loading a 557 MB checkpoint, but still
  /// worth doing off the critical path: it turns the first generation from two
  /// round trips into one.
  @override
  Future<void> warmUp() => _client.openSession();

  @override
  Future<String> generatePlanText(PlanPrompt prompt) =>
      _client.sendMessage(buildPrompt(prompt));

  @override
  Future<String> generateText(String prompt) => _client.sendMessage(prompt);

  @override
  Future<void> dispose() async => _client.close();

  /// Builds the grounded prompt, asking for the JSON envelope
  /// [QonpaniaPlanParser] reads back.
  ///
  /// Exposed for testing: prompt wording is load-bearing (ADR-0005), so it is
  /// verified without touching the network.
  static String buildPrompt(PlanPrompt prompt) =>
      buildGroundedPlanPrompt(prompt, responseFormat: _responseFormat);

  /// The envelope. `titulo_plato` **must** repeat an INS recipe name verbatim:
  /// that string is what the parser matches on to attach real, sourced iron
  /// figures to the day. A dish the agent renamed loses its nutrition data and
  /// counts as zero, which is why the instruction is stated twice.
  static const String _responseFormat = '''
Responde ÚNICAMENTE con un objeto JSON válido, sin texto antes ni después y sin bloques de código.
Usa exactamente esta forma, con 7 elementos en "menu_semanal" (uno por día, "dia" del 1 al 7):
{
  "mensaje_motivacional": "una frase corta para la madre",
  "menu_semanal": [
    {
      "dia": 1,
      "titulo_plato": "el nombre EXACTO de una receta de la lista, copiado tal cual",
      "ingredientes": [{"nombre": "Papa", "cantidad": "1 unidad mediana"}],
      "preparacion": ["Paso 1.", "Paso 2."]
    }
  ]
}
No cambies ni una letra de "titulo_plato": debe coincidir exactamente con un nombre de la lista de recetas oficiales.''';
}
