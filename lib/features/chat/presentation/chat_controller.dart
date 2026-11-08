import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
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
  }) => ChatState(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    loading: loading ?? this.loading,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    sending: sending ?? this.sending,
    failure: clearFailure ? null : failure ?? this.failure,
    sendFailure: clearSendFailure ? null : sendFailure ?? this.sendFailure,
  );
}

/// Una conversacion abierta: carga, recibe en tiempo real y envia (HU-20).
class ChatController extends Notifier<ChatState> {
  new(this.target);

  final ChatTarget target;

  @override
  ChatState build() {
    ref.listen(chatIncomingProvider, (_, next) {
      final message = next.value;
      if (message != null) _receive(message);
    });
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
      if (!ref.mounted) return;
      state = state.copyWith(
        conversation: conversation,
        messages: _merge(state.messages, page.items),
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

  void _receive(ChatMessage message) {
    final conversation = state.conversation;
    if (conversation == null || message.conversationId != conversation.id) {
      return;
    }
    state = state.copyWith(messages: _merge(state.messages, [message]));
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
