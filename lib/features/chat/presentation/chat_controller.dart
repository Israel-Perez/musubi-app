import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_outbox.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';

/// Que conversacion abrir: una existente (desde `Mensajes`) o la de una
/// publicacion (desde Inicio; la API devuelve la que ya existia).
@immutable
class ChatTarget {
  const new conversation(String this.conversationId)
    : product = null,
      productId = null;

  new product(ProductSummary this.product)
    : productId = product.id,
      conversationId = null;

  final String? conversationId;
  final String? productId;

  /// Tarjeta para mostrar mientras carga (no forma parte de la llave).
  final ProductSummary? product;

  @override
  bool operator ==(Object other) =>
      other is ChatTarget &&
      other.conversationId == conversationId &&
      other.productId == productId;

  @override
  int get hashCode => Object.hash(conversationId, productId);
}

/// Estado de `Chat-Valeria`.
@immutable
class ChatState {
  const new({
    this.conversation,
    this.messages = const [],
    this.nextCursor,
    this.loading = true,
    this.loadingOlder = false,
    this.sending = false,
    this.failure,
    this.sendFailure,
    this.counterpartTyping = false,
  });

  final Conversation? conversation;

  /// Del mas viejo al mas nuevo (como se muestran).
  final List<ChatMessage> messages;
  final String? nextCursor;
  final bool loading;
  final bool loadingOlder;
  final bool sending;

  /// No se pudo abrir la conversacion (`chat.own_product`, sin red...).
  final ApiFailure? failure;

  /// No se pudo enviar el ultimo mensaje (moderacion, limite, red).
  final ApiFailure? sendFailure;

  /// HU-65: la otra persona esta escribiendo ("Valeria está escribiendo…").
  final bool counterpartTyping;

  bool get ownProduct => failure?.code == 'chat.own_product';

  ChatState copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    String? nextCursor,
    bool clearCursor = false,
    bool? loading,
    bool? loadingOlder,
    bool? sending,
    ApiFailure? failure,
    bool clearFailure = false,
    ApiFailure? sendFailure,
    bool clearSendFailure = false,
    bool? counterpartTyping,
  }) => ChatState(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    loading: loading ?? this.loading,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    sending: sending ?? this.sending,
    failure: clearFailure ? null : failure ?? this.failure,
    sendFailure: clearSendFailure ? null : sendFailure ?? this.sendFailure,
    counterpartTyping: counterpartTyping ?? this.counterpartTyping,
  );
}

/// Una conversacion abierta: carga, recibe en tiempo real y envia (HU-20).
class ChatController extends Notifier<ChatState> {
  new(this.target);

  final ChatTarget target;

  @override
  ChatState build() {
    ref
      ..listen(chatIncomingProvider, (_, next) {
        final message = next.value;
        if (message != null) _receive(message);
      })
      // HU-63: un "Por enviar" ya salio (o la API lo rechazo).
      ..listen(chatOutboxEventsProvider, (_, next) {
        final event = next.value;
        if (event != null) _settle(event);
      })
      // HU-65: "Escribiendo…" y "Leído" de la otra persona.
      ..listen(chatTypingProvider, (_, next) {
        final signal = next.value;
        if (signal != null) _typingFrom(signal);
      })
      ..listen(chatReadsProvider, (_, next) {
        final signal = next.value;
        if (signal != null) _readBy(signal);
      })
      ..onDispose(() => _typingTimer?.cancel());
    unawaited(Future.microtask(load));
    return const ChatState();
  }

  /// Abre la conversacion y su historial (tambien "Reintentar").
  Future<void> load() async {
    state = state.copyWith(loading: true, clearFailure: true);
    final repository = ref.read(chatRepositoryProvider);
    try {
      final conversation = target.conversationId != null
          ? await repository.conversation(target.conversationId!)
          : await repository.start(target.productId!);
      final page = await repository.messages(conversation.id);
      final pending = await ref
          .read(chatOutboxProvider)
          .pending(conversation.id);
      if (!ref.mounted) return;
      state = state.copyWith(
        conversation: conversation,
        messages: _merge(state.messages, [...page.items, ...pending]),
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        loading: false,
      );
      unawaited(_markRead());
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, failure: failure);
    }
  }

  /// Mensajes anteriores (al llegar arriba).
  Future<void> loadOlder() async {
    final conversation = state.conversation;
    final cursor = state.nextCursor;
    if (conversation == null || cursor == null || state.loadingOlder) return;
    state = state.copyWith(loadingOlder: true);
    try {
      final page = await ref
          .read(chatRepositoryProvider)
          .messages(conversation.id, cursor: cursor);
      if (!ref.mounted) return;
      state = state.copyWith(
        messages: _merge(state.messages, page.items),
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        loadingOlder: false,
      );
    } on ApiFailure {
      if (!ref.mounted) return;
      state = state.copyWith(loadingOlder: false);
    }
  }

  /// Envia [text]. Devuelve `true` si se guardo (la pantalla limpia la caja).
  Future<bool> send(String text) async {
    final conversation = state.conversation;
    final trimmed = text.trim();
    if (conversation == null || trimmed.isEmpty || state.sending) return false;
    state = state.copyWith(sending: true, clearSendFailure: true);
    try {
      final message = await ref
          .read(chatRepositoryProvider)
          .send(conversation.id, trimmed);
      if (!ref.mounted) return true;
      state = state.copyWith(
        messages: _merge(state.messages, [message]),
        sending: false,
      );
      return true;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return false;
      // HU-63: sin red queda "Por enviar" y sale solo al volver.
      if (isOfflineFailure(failure)) {
        final pending = await ref
            .read(chatOutboxProvider)
            .enqueue(conversation.id, trimmed);
        if (!ref.mounted) return pending != null;
        state = state.copyWith(
          messages: pending == null ? null : _merge(state.messages, [pending]),
          sending: false,
          sendFailure: pending == null ? failure : null,
        );
        return pending != null;
      }
      // HU-57: la otra persona bloqueo (o la bloquee en otro dispositivo).
      final blocked = failure.code == 'chat.blocked';
      state = state.copyWith(
        sending: false,
        sendFailure: failure,
        conversation: blocked ? conversation.blocked() : null,
      );
      return false;
    }
  }

  /// Cuanto dura "Escribiendo…" sin otro aviso.
  static const typingFor = Duration(seconds: 5);

  /// Cada cuanto se avisa, como mucho, que escribo.
  static const typingEvery = Duration(seconds: 3);

  Timer? _typingTimer;
  DateTime? _lastTyped;

  /// HU-65: la persona escribe en la caja: se avisa a la otra, a lo mas cada
  /// [typingEvery] y nunca con un bloqueo.
  void typed() {
    final conversation = state.conversation;
    if (conversation == null || !conversation.canReply) return;
    final now = DateTime.now();
    final last = _lastTyped;
    if (last != null && now.difference(last) < typingEvery) return;
    _lastTyped = now;
    ref.read(chatRealtimeProvider).sendTyping(conversation.id);
  }

  /// HU-65: envia una foto (la API la modera). Devuelve `true` si se guardo.
  Future<bool> sendPhoto(String filePath) async {
    final conversation = state.conversation;
    if (conversation == null || !conversation.canReply || state.sending) {
      return false;
    }
    state = state.copyWith(sending: true, clearSendFailure: true);
    try {
      final message = await ref
          .read(chatRepositoryProvider)
          .sendPhoto(conversation.id, filePath);
      if (!ref.mounted) return true;
      state = state.copyWith(
        messages: _merge(state.messages, [message]),
        sending: false,
      );
      return true;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return false;
      final blocked = failure.code == 'chat.blocked';
      state = state.copyWith(
        sending: false,
        sendFailure: failure,
        conversation: blocked ? conversation.blocked() : null,
      );
      return false;
    }
  }

  void _typingFrom(TypingSignal signal) {
    final conversation = state.conversation;
    if (conversation == null ||
        signal.conversationId != conversation.id ||
        signal.userId == myId ||
        !conversation.canReply) {
      return;
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(typingFor, () {
      if (ref.mounted) state = state.copyWith(counterpartTyping: false);
    });
    state = state.copyWith(counterpartTyping: true);
  }

  void _readBy(ReadSignal signal) {
    final conversation = state.conversation;
    if (conversation == null ||
        signal.conversationId != conversation.id ||
        signal.readerId == myId) {
      return;
    }
    state = state.copyWith(conversation: conversation.readAt(signal.at));
  }

  /// "Bloquear a …" (HU-57): bloquea a la otra persona y cambia la caja de
  /// texto por el aviso. Lanza `ApiFailure` si no se pudo.
  Future<void> blockCounterpart() async {
    final conversation = state.conversation;
    if (conversation == null) return;
    await ref
        .read(reputationRepositoryProvider)
        .block(conversation.counterpart.id);
    if (!ref.mounted) return;
    state = state.copyWith(conversation: conversation.blocked());
  }

  /// Mi id (el `sub` del token), para saber que burbujas son mias.
  String? get myId => switch (ref.read(sessionControllerProvider)) {
    SignedIn(:final tokens) => tokens.userId,
    Visitor() => null,
  };

  void _settle(OutboxEvent event) {
    final messages = [
      for (final m in state.messages)
        if (m.id != event.localId) m,
    ];
    final sent = event.sent;
    state = state.copyWith(
      messages: sent != null && sent.conversationId == state.conversation?.id
          ? _merge(messages, [sent])
          : messages,
      sendFailure: event.failure,
    );
  }

  void _receive(ChatMessage message) {
    final conversation = state.conversation;
    if (conversation == null || message.conversationId != conversation.id) {
      return;
    }
    // HU-65: llego su mensaje, ya no esta escribiendo.
    final fromThem = message.senderId != myId;
    if (fromThem) _typingTimer?.cancel();
    state = state.copyWith(
      messages: _merge(state.messages, [message]),
      counterpartTyping: fromThem ? false : null,
    );
    // Llega con la conversacion abierta: ya esta leido.
    if (message.senderId != myId) unawaited(_markRead());
  }

  Future<void> _markRead() async {
    final conversation = state.conversation;
    if (conversation == null) return;
    try {
      await ref.read(chatRepositoryProvider).markRead(conversation.id);
    } on ApiFailure {
      // Sin red: el contador se limpia la proxima vez que se abra.
      return;
    }
  }

  /// Une sin repetir (el mismo mensaje llega por REST y por el hub) y ordena
  /// del mas viejo al mas nuevo (el id de la API es un ObjectId: crece con
  /// el tiempo).
  static List<ChatMessage> _merge(
    List<ChatMessage> current,
    List<ChatMessage> incoming,
  ) {
    final byId = {
      for (final m in current) m.id: m,
      for (final m in incoming) m.id: m,
    };
    return byId.values.toList()..sort((a, b) {
      final time = a.sentAt.compareTo(b.sentAt);
      return time != 0 ? time : a.id.compareTo(b.id);
    });
  }
}

/// Una conversacion por destino. Se libera al cerrar la pantalla.
final NotifierProviderFamily<ChatController, ChatState, ChatTarget>
chatControllerProvider = NotifierProvider.autoDispose
    .family<ChatController, ChatState, ChatTarget>(ChatController.new);
