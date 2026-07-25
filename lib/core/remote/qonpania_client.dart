/// The hosted nutrition agent's two-step protocol, in one class (ADR-0015).
///
/// OWNER: P1 (@sharvel-irigoyen).
///
/// The API has two independent levels of authentication and needs **both** on a
/// message call:
///
/// 1. `POST /sessions` with `X-Api-Key` registers this device and returns a
///    Sanctum token for the contact.
/// 2. `POST /messages` with `X-Api-Key` **and** `Authorization: Bearer <token>`
///    sends the turn and, on a synchronous channel, returns the agent's replies
///    in the same response.
///
/// Callers never see step 1. [sendMessage] opens a session when it needs one,
/// reuses it while it is valid, and re-opens it once on a 401 — a token that
/// expired between two screens is not something a caregiver should have to
/// understand.
library;

import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'qonpania_config.dart';

/// Anything that went wrong talking to the agent.
///
/// Deliberately one type: `PlanController` turns any failure into the same
/// caregiver-facing message, so splitting this into a hierarchy would buy
/// nothing. [statusCode] is null for transport failures and timeouts.
class QonpaniaException implements Exception {
  const QonpaniaException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => statusCode == null
      ? 'QonpaniaException: $message'
      : 'QonpaniaException($statusCode): $message';
}

class QonpaniaClient {
  QonpaniaClient({
    required this.config,
    required this.userReference,
    this.deviceName = 'android',
    this.caregiverName,
    this.phone,
    this.timeout = const Duration(seconds: 90),
    http.Client? httpClient,
    Random? random,
  }) : _http = httpClient ?? http.Client(),
       _random = random ?? Random();

  final QonpaniaConfig config;

  /// Stable identifier for this install, so the agent keeps one contact per
  /// device instead of creating a new one on every launch. Never the child's
  /// name or any health data — see [ADR-0015] on what may cross the wire.
  final String userReference;

  final String deviceName;

  /// The caregiver's own name, when she gave one (Flow 0). Personalises the
  /// agent's greeting; optional everywhere, like everything else about her.
  final String? caregiverName;

  final String? phone;

  /// Generation on a busy channel is slow. This bounds it so a hung request
  /// surfaces as a retryable failure instead of a spinner that never ends.
  final Duration timeout;

  final http.Client _http;
  final Random _random;

  String? _token;
  DateTime? _tokenExpiry;

  /// Whether a usable token is already in hand.
  bool get hasSession => _validToken != null;

  /// Opens the session eagerly. Optional — [sendMessage] does it on demand —
  /// but worth doing off the critical path so the first generation does not pay
  /// for two round trips.
  Future<void> openSession() async {
    await _ensureToken();
  }

  /// Sends one turn and returns the agent's first reply, verbatim.
  ///
  /// Verbatim is the contract: on this channel the reply is a JSON document
  /// carried inside a string field, and deciding what it means belongs to the
  /// parser, not here.
  Future<String> sendMessage(String message) async {
    var token = await _ensureToken();

    var response = await _postMessage(message, token);

    // One retry, and only on 401. A token can expire between the moment we
    // checked it and the moment the server read it; anything else is a real
    // failure and retrying it would just double the caregiver's wait.
    if (response.statusCode == 401) {
      _clearToken();
      token = await _ensureToken();
      response = await _postMessage(message, token);
    }

    final body = _decode(response, 'enviar el mensaje');
    return _firstReply(body);
  }

  /// Releases the underlying connection pool.
  void close() {
    _http.close();
    _clearToken();
  }

  // --- Session ---------------------------------------------------------------

  String? get _validToken {
    final token = _token;
    if (token == null) return null;

    // No expiry means "unknown", not "expired": the 401 retry is the real
    // safety net, so we would rather use the token than throw it away.
    final expiry = _tokenExpiry;
    if (expiry == null) return token;

    // Treated as expired a minute early: a token that dies mid-flight costs a
    // full extra round trip.
    final cutoff = expiry.subtract(const Duration(minutes: 1));
    return DateTime.now().toUtc().isAfter(cutoff) ? null : token;
  }

  Future<String> _ensureToken() async {
    final existing = _validToken;
    if (existing != null) return existing;

    final response = await _send(
      () => _http.post(
        config.sessionsEndpoint,
        headers: _headers(),
        body: jsonEncode({
          'user_reference': userReference,
          'device_name': deviceName,
          if (caregiverName != null) 'name': caregiverName,
          if (phone != null) 'phone': phone,
        }),
      ),
      'abrir la sesión',
    );

    final body = _decode(response, 'abrir la sesión');
    final token = body['token'];
    if (token is! String || token.isEmpty) {
      throw const QonpaniaException('La sesión no devolvió un token.');
    }

    _token = token;
    _tokenExpiry = _parseExpiry(body['expires_at']);
    return token;
  }

  void _clearToken() {
    _token = null;
    _tokenExpiry = null;
  }

  static DateTime? _parseExpiry(Object? raw) {
    if (raw is! String) return null;
    // An unparseable expiry means "unknown", not "expired": the 401 retry is
    // the real safety net, so we would rather use the token than discard it.
    return DateTime.tryParse(raw)?.toUtc();
  }

  // --- Messages --------------------------------------------------------------

  Future<http.Response> _postMessage(String message, String token) => _send(
    () => _http.post(
      config.messagesEndpoint,
      headers: _headers(token: token),
      body: jsonEncode({
        'message': message,
        // Idempotency key: if the request is retried after a timeout, the
        // server recognises the resend instead of queueing a second turn.
        'client_message_id': _newMessageId(),
      }),
    ),
    'enviar el mensaje',
  );

  /// The agent's first reply.
  ///
  /// An empty `replies` array is the asynchronous-channel shape: the turn was
  /// accepted and the answer will arrive over a webhook we do not listen to.
  /// That is a configuration error for this app, so it is reported as one
  /// rather than silently producing an empty plan.
  static String _firstReply(Map<String, dynamic> body) {
    final replies = body['replies'];
    if (replies is! List || replies.isEmpty) {
      throw const QonpaniaException(
        'El agente no devolvió una respuesta. Revisa que el canal esté '
        'configurado en modo síncrono.',
      );
    }

    final first = replies.first;
    final content = first is Map<String, dynamic> ? first['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw const QonpaniaException('La respuesta del agente llegó vacía.');
    }
    return content;
  }

  // --- Transport -------------------------------------------------------------

  Map<String, String> _headers({String? token}) => {
    'X-Api-Key': config.apiKey,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// Runs one request with the timeout applied and every transport-level
  /// failure — no signal, DNS, TLS, timeout — folded into [QonpaniaException].
  Future<http.Response> _send(
    Future<http.Response> Function() request,
    String action,
  ) async {
    try {
      return await request().timeout(timeout);
    } on QonpaniaException {
      rethrow;
    } catch (error) {
      throw QonpaniaException('No se pudo $action: $error');
    }
  }

  /// Decodes a JSON object body, turning any non-2xx into a [QonpaniaException].
  ///
  /// The body is carried on the exception for `debugPrint`, never for display:
  /// a server error message is written for us, not for a caregiver.
  static Map<String, dynamic> _decode(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw QonpaniaException(
        'No se pudo $action.',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    try {
      // utf8.decode, not `response.body`: http falls back to latin-1 when the
      // server omits a charset, which mangles every accent in the recipes.
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      return decoded;
    } on FormatException catch (error) {
      throw QonpaniaException(
        'La respuesta del servidor no es JSON válido: $error',
        statusCode: response.statusCode,
      );
    }
  }

  /// A unique id per outgoing message. Not a real UUID — it does not need to
  /// be, it needs to be unique per device, and the device is already scoped by
  /// [userReference].
  String _newMessageId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final salt = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '$userReference-$now-$salt';
  }
}
