/// The hosted agent's two-step protocol, over a mocked transport (ADR-0015).
///
/// No socket is opened here: `MockClient` answers in-process, so these run in
/// CI and on a plane like the rest of the suite.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wawafuerte/core/remote/qonpania_client.dart';
import 'package:wawafuerte/core/remote/qonpania_config.dart';

void main() {
  final config = QonpaniaConfig(
    baseUrl: Uri.parse(QonpaniaConfig.defaultBaseUrl),
    apiKey: 'qpa_test_key',
  );

  /// Records every request, and answers `/sessions` and `/messages` from the
  /// callbacks a test supplies.
  ({QonpaniaClient client, List<http.Request> requests}) clientWith({
    http.Response Function(http.Request)? onSession,
    http.Response Function(http.Request)? onMessage,
  }) {
    final requests = <http.Request>[];

    final mock = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/sessions')) {
        return (onSession ?? _okSession)(request);
      }
      return (onMessage ?? _okMessage)(request);
    });

    return (
      client: QonpaniaClient(
        config: config,
        userReference: 'device-1',
        caregiverName: 'María',
        httpClient: mock,
      ),
      requests: requests,
    );
  }

  group('opening the session', () {
    test('happens before the first message, and only once', () async {
      final (:client, :requests) = clientWith();

      await client.sendMessage('hola');
      await client.sendMessage('otra vez');

      expect(requests.map((r) => r.url.path), [
        '/api/v1/app/sessions',
        '/api/v1/app/messages',
        // No second /sessions: the token from the first call is reused.
        '/api/v1/app/messages',
      ]);
    });

    test('sends the API key and the identifying fields', () async {
      final (:client, :requests) = clientWith();

      await client.sendMessage('hola');

      final session = requests.first;
      expect(session.headers['X-Api-Key'], 'qpa_test_key');
      expect(jsonDecode(session.body), {
        'user_reference': 'device-1',
        'device_name': 'android',
        'name': 'María',
      });
    });

    test('a session without a token is an error, not a silent no-op', () async {
      final (:client, requests: _) = clientWith(
        onSession: (_) => http.Response('{"expires_at": null}', 200),
      );

      await expectLater(
        client.sendMessage('hola'),
        throwsA(isA<QonpaniaException>()),
      );
    });
  });

  group('sending a message', () {
    test('carries both the API key and the bearer token', () async {
      final (:client, :requests) = clientWith();

      await client.sendMessage('hola');

      final message = requests.last;
      expect(message.headers['X-Api-Key'], 'qpa_test_key');
      expect(message.headers['Authorization'], 'Bearer test-token-1');
    });

    test('returns the first reply verbatim, accents intact', () async {
      final (:client, requests: _) = clientWith();

      // The agent's reply is a JSON document inside a string field; the client
      // must not try to interpret it.
      expect(await client.sendMessage('hola'), '{"titulo": "Puré de papá"}');
    });

    test('gives every message a distinct client_message_id', () async {
      final (:client, :requests) = clientWith();

      await client.sendMessage('uno');
      await client.sendMessage('dos');

      final ids = requests
          .where((r) => r.url.path.endsWith('/messages'))
          .map((r) => jsonDecode(r.body)['client_message_id'] as String)
          .toSet();

      expect(ids, hasLength(2), reason: 'a resend must not look like a retry');
    });
  });

  group('failures', () {
    test('re-opens the session once on a 401 and succeeds', () async {
      var messageCalls = 0;
      final (:client, :requests) = clientWith(
        onMessage: (request) {
          messageCalls++;
          // The token expired between the check and the server reading it.
          return messageCalls == 1
              ? http.Response('{"message": "Unauthenticated."}', 401)
              : _okMessage(request);
        },
      );

      expect(await client.sendMessage('hola'), isNotEmpty);
      expect(requests.map((r) => r.url.path), [
        '/api/v1/app/sessions',
        '/api/v1/app/messages',
        '/api/v1/app/sessions', // re-opened
        '/api/v1/app/messages',
      ]);
    });

    test('does not retry anything other than a 401', () async {
      var messageCalls = 0;
      final (:client, requests: _) = clientWith(
        onMessage: (_) {
          messageCalls++;
          return http.Response('{"message": "Server error"}', 500);
        },
      );

      await expectLater(
        client.sendMessage('hola'),
        throwsA(
          isA<QonpaniaException>().having((e) => e.statusCode, 'status', 500),
        ),
      );
      expect(messageCalls, 1, reason: 'retrying doubles the caregiver’s wait');
    });

    test('an empty replies array reports a misconfigured channel', () async {
      final (:client, requests: _) = clientWith(
        onMessage: (_) => http.Response('{"status": "ok", "replies": []}', 200),
      );

      await expectLater(
        client.sendMessage('hola'),
        throwsA(
          isA<QonpaniaException>().having(
            (e) => e.message,
            'message',
            contains('síncrono'),
          ),
        ),
      );
    });

    test('a transport failure surfaces as QonpaniaException', () async {
      final client = QonpaniaClient(
        config: config,
        userReference: 'device-1',
        httpClient: MockClient((_) async => throw const SocketishError()),
      );

      await expectLater(
        client.sendMessage('hola'),
        throwsA(isA<QonpaniaException>()),
      );
    });
  });
}

http.Response _okSession(http.Request request) => http.Response(
  jsonEncode({
    'token': 'test-token-1',
    'expires_at': DateTime.now()
        .toUtc()
        .add(const Duration(days: 30))
        .toIso8601String(),
    'contact': {'id': 'contact-1', 'name': 'María'},
  }),
  200,
);

/// Mirrors the documented shape: `content` is a **string** holding JSON.
http.Response _okMessage(http.Request request) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'status': 'ok',
      'message': {'id': 'msg-1', 'content': 'hola', 'type': 'text'},
      'replies': [
        {
          'id': 'msg-2',
          'content': '{"titulo": "Puré de papá"}',
          'type': 'text',
        },
      ],
    }),
  ),
  200,
  // No charset, which is exactly when `http` would fall back to latin-1 and
  // mangle the accents the client has to decode as UTF-8 itself.
  headers: {'content-type': 'application/json'},
);

/// Stands in for a dropped connection: any non-HTTP error out of the transport.
class SocketishError implements Exception {
  const SocketishError();
}
