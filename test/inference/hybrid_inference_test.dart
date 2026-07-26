import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/inference/fake_inference_service.dart';
import 'package:wawafuerte/core/inference/connectivity_monitor.dart';
import 'package:wawafuerte/core/inference/hybrid_inference_service.dart';
import 'package:wawafuerte/core/inference/inference_service.dart';
import 'package:wawafuerte/core/domain/recipe.dart';

class FailingInferenceService implements InferenceService {
  @override
  bool get isReady => true;

  @override
  bool get isDownloading => false;

  @override
  int? get downloadProgress => null;

  @override
  ActiveInferenceMode get activeMode => ActiveInferenceMode.cloud;

  @override
  Future<void> warmUp() async {
    throw Exception('Network unreachable');
  }

  @override
  Future<String> generatePlanText(PlanPrompt prompt) async {
    throw Exception('Network timeout');
  }

  @override
  Future<String> generateText(String prompt) async {
    throw Exception('Network timeout');
  }

  @override
  Future<void> dispose() async {}
}

/// Lets a test drive the radio directly. The real monitor subscribes to the OS
/// stream, which a unit test has no way to move.
// ignore_for_file: prefer_initializing_formals
class TestConnectivityMonitor extends ConnectivityMonitor {
  TestConnectivityMonitor({bool online = false}) : _online = online;

  bool _online;

  @override
  bool get isOnline => _online;

  @override
  Future<void> start() async {}

  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    notifyListeners();
  }
}

void main() {
  _modeTests();
  test(
    'HybridInferenceService falls back to secondary when primary fails',
    () async {
      final primary = FailingInferenceService();
      final fallback = FakeInferenceService();

      final hybrid = HybridInferenceService(
        primary: primary,
        fallback: fallback,
        connectivity: TestConnectivityMonitor(online: true),
      );
      await hybrid.warmUp();

      const prompt = PlanPrompt(
        candidateRecipes: [
          Recipe(
            id: 1,
            name: 'Sangrecita con papa',
            ingredients: ['sangrecita', 'papa'],
            preparation: 'Paso 1...',
            ironMg: 8.5,
            minAgeMonths: 6,
            referenceCostPen: 4.5,
          ),
        ],
        ageMonths: 12,
        region: Region.highlands,
        availableIngredients: ['sangrecita'],
        weeklyBudgetPen: 30,
      );

      final text = await hybrid.generatePlanText(prompt);
      expect(text, contains('Sangrecita con papa'));
    },
  );
}

/// A fallback that reports itself loaded, standing in for Gemma once its
/// weights are on disk.
class ReadyLocalService extends FakeInferenceService {
  @override
  bool get isReady => true;

  @override
  ActiveInferenceMode get activeMode => ActiveInferenceMode.gemma;
}

/// A hosted client that is configured but whose readiness says nothing about
/// whether the phone actually has signal — which is exactly the confusion that
/// left the status indicator reading "Nube" while offline.
class ConfiguredCloudService extends FakeInferenceService {
  @override
  bool get isReady => true;

  @override
  ActiveInferenceMode get activeMode => ActiveInferenceMode.cloud;
}

void _modeTests() {
  group('the reported mode follows the radio', () {
    test('online with a hosted session reports cloud', () {
      final hybrid = HybridInferenceService(
        primary: ConfiguredCloudService(),
        fallback: ReadyLocalService(),
        connectivity: TestConnectivityMonitor(online: true),
      );

      expect(hybrid.activeMode, ActiveInferenceMode.cloud);
    });

    test('losing signal switches to on-device Gemma', () {
      final connectivity = TestConnectivityMonitor(online: true);
      final hybrid = HybridInferenceService(
        primary: ConfiguredCloudService(),
        fallback: ReadyLocalService(),
        connectivity: connectivity,
      );
      expect(hybrid.activeMode, ActiveInferenceMode.cloud);

      connectivity.setOnline(false);

      expect(
        hybrid.activeMode,
        ActiveInferenceMode.gemma,
        reason: 'A configured key is not signal. This was the actual bug.',
      );
    });

    test('regaining signal switches back to cloud', () {
      final connectivity = TestConnectivityMonitor();
      final hybrid = HybridInferenceService(
        primary: ConfiguredCloudService(),
        fallback: ReadyLocalService(),
        connectivity: connectivity,
      );
      expect(hybrid.activeMode, ActiveInferenceMode.gemma);

      connectivity.setOnline(true);

      expect(hybrid.activeMode, ActiveInferenceMode.cloud);
    });

    test('offline with no weights yet falls all the way to demo', () {
      final hybrid = HybridInferenceService(
        primary: ConfiguredCloudService(),
        fallback: FakeInferenceService(),
        connectivity: TestConnectivityMonitor(),
      );

      expect(hybrid.activeMode, ActiveInferenceMode.demo);
    });

    test('no hosted key at all still reports gemma when loaded', () {
      final hybrid = HybridInferenceService(
        fallback: ReadyLocalService(),
        connectivity: TestConnectivityMonitor(online: true),
      );

      expect(
        hybrid.activeMode,
        ActiveInferenceMode.gemma,
        reason: 'Being online does not mean there is a hosted agent to use',
      );
    });

    test('a change in signal notifies listeners', () {
      final connectivity = TestConnectivityMonitor(online: true);
      final hybrid = HybridInferenceService(
        primary: ConfiguredCloudService(),
        fallback: ReadyLocalService(),
        connectivity: connectivity,
      );

      var notifications = 0;
      hybrid.addListener(() => notifications++);

      connectivity.setOnline(false);

      expect(
        notifications,
        greaterThan(0),
        reason: 'Without this the indicator never rebuilds and stays frozen',
      );
    });
  });
}
