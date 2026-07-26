/// A `ChangeNotifier` view over whichever [InferenceService] is in use.
///
/// `InferenceService` is deliberately not a `ChangeNotifier`: it is a plain
/// contract that a fake, an on-device model and a hosted client all satisfy,
/// and dragging Flutter's change notification into it would put the UI
/// framework inside `core`.
///
/// The UI still needs to rebuild when the answer changes, though — that was the
/// actual bug behind a status indicator that read "Nube" long after the signal
/// was gone. This adapter is the seam: it always exists, and it forwards
/// notifications from the service when the service happens to emit them.
library;

import 'package:flutter/foundation.dart';

import 'inference_service.dart';

class InferenceStatus extends ChangeNotifier {
  InferenceStatus(this.service) {
    final Object source = service;
    if (source is Listenable) {
      _source = source;
      source.addListener(notifyListeners);
    }
  }

  final InferenceService service;
  Listenable? _source;

  ActiveInferenceMode get mode => service.activeMode;
  bool get isDownloading => service.isDownloading;
  int? get downloadProgress => service.downloadProgress;
  bool get isReady => service.isReady;

  @override
  void dispose() {
    _source?.removeListener(notifyListeners);
    super.dispose();
  }
}
