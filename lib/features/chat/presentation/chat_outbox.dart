import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/offline_cache.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/storage/local_store.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';

/// Un mensaje "Por enviar" ya salio ([sent]) o la API lo rechazo ([failure]:
/// moderacion, bloqueo) y se quita.
@immutable
class OutboxEvent {
  const new({
    required this.localId,
    required this.conversationId,
    this.sent,
    this.failure,
  });

  final String localId;
  final String conversationId;
  final ChatMessage? sent;
  final ApiFailure? failure;
}

/// Errores de red con los que un mensaje queda "Por enviar" (no los que
/// responde la API: esos se muestran al momento).
bool isOfflineFailure(ApiFailure failure) => switch (failure.code) {
  ApiFailure.networkOffline ||
  ApiFailure.networkTimeout ||
  ApiFailure.networkUnknown => true,
  _ => false,
};

/// Mensajes escritos sin conexion (HU-63): se guardan en SQLite ("Por
/// enviar") y salen solos al volver la red, en el orden en que se escribieron.
/// Se reintenta cada [retryEvery] mientras haya pendientes y en cuanto una
/// peticion vuelve a llegar a la API.
class ChatOutbox {
  new(this._ref);

  /// Cada cuanto se reintenta con mensajes pendientes.
  static const retryEvery = Duration(seconds: 15);

  final Ref _ref;
  final _events = StreamController<OutboxEvent>.broadcast();
  Timer? _timer;
  bool _flushing = false;
  var _n = 0;

  /// Lo que paso con cada pendiente (lo escucha el chat abierto).
  Stream<OutboxEvent> get events => _events.stream;

  String? get _userId => switch (_ref.read(sessionControllerProvider)) {
    SignedIn(:final tokens) => tokens.userId,
    Visitor() => null,
  };

  /// Arranca: si quedaron pendientes de antes, los intenta enviar.
  Future<void> start() async {
    _ref.listen(offlineProvider, (previous, offline) {
      if (previous == true && !offline) unawaited(flush());
    });
    final userId = _userId;
    if (userId != null &&
        (await _ref.read(localStoreProvider).outbox(userId)).isNotEmpty) {
      _schedule();
    }
  }

  /// Guarda [text] para [conversationId] y devuelve su burbuja "Por enviar".
  Future<ChatMessage?> enqueue(String conversationId, String text) async {
    final userId = _userId;
    if (userId == null) return null;
    final now = _ref.read(clockProvider)().toUtc();
    final item = OutboxItem(
      id: 'local-${now.microsecondsSinceEpoch}-${_n++}',
      userId: userId,
      conversationId: conversationId,
      text: text,
      createdAt: now,
    );
    await _ref.read(localStoreProvider).enqueue(item);
    _schedule();
    return _bubble(item);
  }

  /// Las burbujas "Por enviar" de una conversacion.
  Future<List<ChatMessage>> pending(String conversationId) async {
    final userId = _userId;
    if (userId == null) return const [];
    return [
      for (final item in await _ref.read(localStoreProvider).outbox(userId))
        if (item.conversationId == conversationId) _bubble(item),
    ];
  }

  /// Intenta enviar los pendientes, del mas viejo al mas nuevo. Sin red se
  /// detiene y espera al siguiente intento.
  Future<void> flush() async {
    final userId = _userId;
    if (_flushing || userId == null) return;
    _flushing = true;
    try {
      final store = _ref.read(localStoreProvider);
      final repository = _ref.read(chatRepositoryProvider);
      for (final item in await store.outbox(userId)) {
        try {
          final sent = await repository.send(item.conversationId, item.text);
          await store.dequeue(item.id);
          _events.add(
            OutboxEvent(
              localId: item.id,
              conversationId: item.conversationId,
              sent: sent,
            ),
          );
        } on ApiFailure catch (failure) {
          if (isOfflineFailure(failure)) return;
          // La API lo rechazo (moderacion, bloqueo): no se vuelve a intentar.
          await store.dequeue(item.id);
          _events.add(
            OutboxEvent(
              localId: item.id,
              conversationId: item.conversationId,
              failure: failure,
            ),
          );
        }
      }
      _timer?.cancel();
      _timer = null;
    } finally {
      _flushing = false;
    }
  }

  void _schedule() {
    _timer ??= Timer.periodic(retryEvery, (_) => unawaited(flush()));
  }

  ChatMessage _bubble(OutboxItem item) => ChatMessage(
    id: item.id,
    conversationId: item.conversationId,
    senderId: item.userId,
    text: item.text,
    sentAt: item.createdAt,
    pending: true,
  );

  void dispose() {
    _timer?.cancel();
    unawaited(_events.close());
  }
}

/// Ver [ChatOutbox]. Lo enciende `MusubiApp`, como los avisos push.
final chatOutboxProvider = Provider<ChatOutbox>((ref) {
  final outbox = ChatOutbox(ref);
  ref.onDispose(outbox.dispose);
  unawaited(outbox.start());
  return outbox;
});

/// Los eventos del buzon, para el chat abierto.
final StreamProvider<OutboxEvent> chatOutboxEventsProvider =
    StreamProvider<OutboxEvent>((ref) => ref.watch(chatOutboxProvider).events);
