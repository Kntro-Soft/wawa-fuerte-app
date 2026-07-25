/// Where the hosted nutrition agent lives, and whether we are allowed to call
/// it at all (ADR-0015).
///
/// OWNER: P1 (@sharvel-irigoyen).
///
/// **The API key is never committed.** It is supplied at build time, the same
/// way the Gemma checkpoint path is:
///
/// ```
/// flutter run \
///   --dart-define=QONPANIA_API_KEY=qpa_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
/// ```
///
/// With no key the app is [isConfigured] `false` and never opens a socket — it
/// falls back to on-device inference and behaves exactly as it did under
/// ADR-0002. That default is what keeps `flutter test`, CI, and the airplane-mode
/// demo working without anybody holding a credential.
///
/// A `--dart-define` is **not a secret store**: the value ends up in the
/// compiled binary and can be read out of an APK. It is a deployment
/// convenience, not protection. The key is a channel credential scoped to this
/// app, and rotating it is a panel operation — treat a shipped build as having
/// published it.
library;

class QonpaniaConfig {
  const QonpaniaConfig({required this.baseUrl, required this.apiKey});

  /// Reads the build-time configuration. Safe to call anywhere: with no key it
  /// simply reports [isConfigured] `false`.
  factory QonpaniaConfig.fromEnvironment() => QonpaniaConfig(
    baseUrl: Uri.parse(
      const String.fromEnvironment(
        'QONPANIA_BASE_URL',
        defaultValue: defaultBaseUrl,
      ),
    ),
    apiKey: const String.fromEnvironment('QONPANIA_API_KEY'),
  );

  static const String defaultBaseUrl = 'https://agents.qonpania.com/api/v1/app';

  /// Root of the mobile channel API, without a trailing slash.
  final Uri baseUrl;

  /// The channel credential sent as `X-Api-Key` on **every** request — the
  /// session call and the message call alike. It identifies the app; the
  /// Sanctum token identifies the user, and one never replaces the other.
  final String apiKey;

  /// Whether a remote call may be attempted. No key means no network, ever.
  bool get isConfigured => apiKey.isNotEmpty;

  Uri get sessionsEndpoint => _endpoint('sessions');
  Uri get messagesEndpoint => _endpoint('messages');

  /// Tolerates a configured base URL with or without a trailing slash.
  Uri _endpoint(String path) {
    final root = baseUrl.path.replaceAll(RegExp(r'/+$'), '');
    return baseUrl.replace(path: '$root/$path');
  }
}
