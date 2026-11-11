import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/chat/data/http_chat_repository.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/domain/chat_repository.dart';

/// Abre un WebSocket (en pruebas, uno falso).
typedef WebSocketConnector = Future<WebSocket> Function(Uri uri);

/// Token vigente para conectarse, o `null` sin sesion. Puede renovar la
/// sesion antes de devolverlo.
typedef AccessTokenReader = Future<String?> Function();

/// Cliente minimo del protocolo JSON de SignalR para `/hubs/chat` (HU-20).
///
/// Solo lo que la API usa: WebSockets sin negociar (`skipNegotiation`), el
/// token en `?access_token=` y el evento `messageCreated`. La app no llama
/// metodos del hub (los mensajes se envian por REST). Sin paquete: el
/// protocolo son mensajes JSON separados por `0x1E` (00-01: sin dependencias
/// nuevas).
class SignalRChatRealtime implements ChatRealtime {
  new({
    required this._apiBaseUrl,
    required this._readToken,
    WebSocketConnector? connect,
    this._pingInterval = const Duration(seconds: 15),
  }) : _connect = connect ?? ((uri) => WebSocket.connect(uri.toString()));

  final Uri _apiBaseUrl;
  final AccessTokenReader _readToken;
  final WebSocketConnector _connect;
  final Duration _pingInterval;
  final _messages = StreamController<ChatMessage>.broadcast();
  final _agreements = StreamController<String>.broadcast();

  WebSocket? _socket;
  Timer? _ping;
  Timer? _retry;
  int _attempt = 0;
  bool _running = false;

  /// Esperas entre reintentos (la ultima se repite).
  static const backoff = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  @override
  Stream<ChatMessage> get messages => _messages.stream;

  @override
  Stream<String> get agreementChanges => _agreements.stream;

  @override
  void start() {
    if (_running) return;
    _running = true;
    unawaited(_open());
  }

  @override
  Future<void> stop() async {
    _running = false;
    _retry?.cancel();
    _ping?.cancel();
    final socket = _socket;
    _socket = null;
    await socket?.close();
  }

  /// URL del hub con el esquema de WebSocket (`wss` con `https`).
  @visibleForTesting
  static Uri hubUri(Uri apiBaseUrl, String token) => apiBaseUrl.replace(
    scheme: apiBaseUrl.scheme == 'https' ? 'wss' : 'ws',
    path: ApiPaths.chatHub,
    queryParameters: {'access_token': token},
  );

  Future<void> _open() async {
    if (!_running) return;
    try {
      final token = await _readToken();
      if (token == null || !_running) return;
      final socket = await _connect(hubUri(_apiBaseUrl, token));
      if (!_running) {
        await socket.close();
        return;
      }
      _socket = socket;
      socket
        ..add('{"protocol":"json","version":1}$recordSeparator')
        ..listen(
          (data) =>
              _onData(data is String ? data : utf8.decode(data as List<int>)),
          onDone: _scheduleRetry,
          onError: (_) => _scheduleRetry(),
          cancelOnError: true,
        );
      // El servidor cierra a los 30 s sin noticias del cliente.
      _ping = Timer.periodic(
        _pingInterval,
        (_) => _socket?.add('{"type":6}$recordSeparator'),
      );
    } on Object {
      // Sin red, token vencido o servidor caido: se reintenta con espera.
      _scheduleRetry();
    }
  }

  void _onData(String data) {
    for (final frame in parseFrames(data)) {
      switch (frame) {
        case {
          'type': 1,
          'target': 'messageCreated',
          'arguments': [final Map<String, dynamic> message, ...],
        }:
          _attempt = 0;
          _messages.add(messageFromJson(message));
        case {
          'type': 1,
          'target': 'agreementChanged',
          'arguments': [{'conversationId': final String id}, ...],
        }:
          _attempt = 0;
          _agreements.add(id);
        case {'type': 7}:
          // El servidor cierra (por ejemplo, el token vencio): se reconecta.
          unawaited(_socket?.close());
        case final Map<String, dynamic> handshake when handshake.isEmpty:
          _attempt = 0;
        default:
          break;
      }
    }
  }

  void _scheduleRetry() {
    _ping?.cancel();
    _socket = null;
    if (!_running) return;
    _retry?.cancel();
    final wait = backoff[_attempt.clamp(0, backoff.length - 1)];
    _attempt++;
    _retry = Timer(wait, () => unawaited(_open()));
  }

  /// Separador de mensajes del protocolo JSON de SignalR.
  static const recordSeparator = '\u001e';

  /// Mensajes JSON de un bloque (pueden venir varios juntos).
  @visibleForTesting
  static List<Map<String, dynamic>> parseFrames(String data) => [
    for (final raw in data.split(recordSeparator))
      if (raw.trim().isNotEmpty)
        if (jsonDecode(raw) case final Map<String, dynamic> frame) frame,
  ];
}
