/// Watches the network continuously so the app can switch modes on its own.
///
/// Before this existed the app only discovered it was offline by *failing* a
/// request: the status chip was computed from "is there an API key", which is
/// true whether or not the phone has signal. A caregiver walking out of Wi-Fi
/// range saw "Nube" until something broke.
///
/// This listens to the OS connectivity stream instead, so the switch happens
/// when the signal changes rather than when a request dies.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityMonitor extends ChangeNotifier {
  ConnectivityMonitor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = false;
  bool _started = false;

  /// Whether the OS reports any usable network interface.
  ///
  /// This is reachability, not a guarantee: a captive portal or a dead uplink
  /// still reports connected. Callers must keep their error path — this only
  /// decides which path to *try first*.
  bool get isOnline => _isOnline;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    // Seed with the current state so the first frame is already correct rather
    // than defaulting to offline and flickering a moment later.
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (_) {
      _isOnline = false;
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      _apply,
      onError: (_) {
        // Losing the stream is not a reason to claim we are online.
        if (_isOnline) {
          _isOnline = false;
          notifyListeners();
        }
      },
    );
  }

  void _apply(List<ConnectivityResult> results) {
    final online =
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);

    if (online == _isOnline) return;
    _isOnline = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
