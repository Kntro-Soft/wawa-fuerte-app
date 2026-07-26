/// Picks between the hosted agent and on-device Gemma, and **tells the UI when
/// that choice changes**.
///
/// The previous version exposed `activeMode` as a plain getter over
/// `primary.isReady`. Two things were wrong with that, and both were visible on
/// a real phone:
///
/// 1. `isReady` on the hosted client means "a key was compiled in", not "there
///    is signal". Walking out of Wi-Fi range did not change the reported mode.
/// 2. Nothing notified anyone, so even a correct change never reached the
///    widget tree. The chip was frozen from first build.
///
/// This is a [ChangeNotifier] driven by [ConnectivityMonitor], so the mode
/// follows the radio rather than the last failed request.
library;

import 'package:flutter/foundation.dart';

import 'connectivity_monitor.dart';
import 'inference_service.dart';

class HybridInferenceService extends ChangeNotifier
    implements InferenceService {
  HybridInferenceService({
    required this.fallback,
    required this.connectivity,
    this.primary,
  }) {
    connectivity.addListener(_onConnectivityChanged);
  }

  /// The hosted agent, or null when no key was compiled in. Null is the normal
  /// case: it means this build is the offline-only one described in ADR-0002.
  final InferenceService? primary;

  final InferenceService fallback;
  final ConnectivityMonitor connectivity;

  ActiveInferenceMode? _lastNotifiedMode;

  void _onConnectivityChanged() {
    final mode = activeMode;
    if (mode == _lastNotifiedMode) return;
    _lastNotifiedMode = mode;
    notifyListeners();
  }

  /// Call after anything that can change readiness — a finished download, a
  /// warm-up, a failed generation — so the chip stops lying.
  void refresh() => _onConnectivityChanged();

  @override
  bool get isReady => (primary?.isReady ?? false) || fallback.isReady;

  @override
  bool get isDownloading =>
      (primary?.isDownloading ?? false) || fallback.isDownloading;

  @override
  int? get downloadProgress =>
      fallback.downloadProgress ?? primary?.downloadProgress;

  /// Cloud only when there is **both** a session and actual connectivity.
  /// Otherwise on-device Gemma if its weights are loaded, and the canned demo
  /// as the last resort.
  @override
  ActiveInferenceMode get activeMode {
    if (connectivity.isOnline && (primary?.isReady ?? false)) {
      return ActiveInferenceMode.cloud;
    }
    if (fallback.isReady) return ActiveInferenceMode.gemma;
    return ActiveInferenceMode.demo;
  }

  @override
  Future<void> warmUp() async {
    try {
      await primary?.warmUp();
    } catch (_) {
      // A dead hosted channel is not fatal; that is what the fallback is for.
    }

    try {
      await fallback.warmUp();
    } catch (_) {
      // Missing weights are expected on a fresh install, before the download
      // finishes. The demo service still answers.
    }

    refresh();
  }

  @override
  Future<String> generatePlanText(PlanPrompt prompt) async {
    final cloud = primary;
    if (connectivity.isOnline && cloud != null) {
      try {
        final result = await cloud.generatePlanText(prompt);
        refresh();
        return result;
      } catch (_) {
        // Reachable but unusable — captive portal, dead uplink, server error.
        // Fall through rather than surface a network error to a caregiver.
      }
    }

    final result = await fallback.generatePlanText(prompt);
    refresh();
    return result;
  }

  @override
  Future<String> generateText(String prompt) async {
    final cloud = primary;
    if (connectivity.isOnline && cloud != null) {
      try {
        final result = await cloud.generateText(prompt);
        refresh();
        return result;
      } catch (_) {
        // Same reasoning as above.
      }
    }

    final result = await fallback.generateText(prompt);
    refresh();
    return result;
  }

  @override
  Future<void> dispose() async {
    connectivity.removeListener(_onConnectivityChanged);
    await primary?.dispose();
    await fallback.dispose();
    super.dispose();
  }
}
