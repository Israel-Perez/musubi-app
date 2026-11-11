import 'dart:async';
import 'dart:convert';

import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/domain/chat_repository.dart';

/// Mi id en las pruebas del chat (el `sub` de [chatTokens]).
const myId = '6716a0000000000000000003';

/// La vendedora de las pruebas (maqueta `Chat-Valeria`).
const valeria = ChatCounterpart(
  id: '6716a0000000000000000001',
  name: 'Valeria Cruz',
);

/// Un access token con forma de JWT y `sub` = [myId] (la firma no importa:
/// la app solo lo lee).
String jwtFor(String sub) {
  String part(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'sub': sub})}.firma';
}

/// Sesion abierta como [myId].
SessionTokens chatTokens(DateTime now) => SessionTokens(
  accessToken: jwtFor(myId),
  accessExpiresAt: now.add(const Duration(minutes: 15)),
  refreshToken: 'refresh',
  profile: const SessionProfile(
    fullName: 'Ana Sofía Ramírez',
    email: 'ana.ramirez@uttt.edu.mx',
    campus: 'UTTT',
  ),
);

/// La conversacion de la maqueta: Ana compra la calculadora de Valeria.
const sampleConversation = Conversation(
  id: 'c1',
  role: ChatRole.buyer,
  counterpart: valeria,
  context: ChatContext(
    id: 'p1',
    title: 'Calculadora Casio fx-991ES Plus',
    available: true,
    priceCents: 45000,
    condition: 'used',
    conditionDetail: 'fair',
  ),
);

/// Repositorio del chat en memoria: guarda lo que se le pide.
class FakeChatRepository implements ChatRepository {
  new({
    this.conversationValue = sampleConversation,
    List<ChatMessage>? messages,
    List<InboxEntry>? inboxEntries,
    this.startFailure,
    this.sendFailure,
  }) : stored = messages ?? [],
       inboxEntries = inboxEntries ?? [];

  final Conversation conversationValue;
  final List<ChatMessage> stored;
  final List<InboxEntry> inboxEntries;
  final ApiFailure? startFailure;
  ApiFailure? sendFailure;

  final List<String> started = [];
  final List<String> sent = [];
  final List<String> read = [];
  final List<InboxFilter> inboxCalls = [];

  @override
  Future<Conversation> start(String productId) async {
    started.add(productId);
    if (startFailure != null) throw startFailure!;
    return conversationValue;
  }

  @override
  Future<Conversation> conversation(String id) async => conversationValue;

  @override
  Future<MessagePage> messages(String conversationId, {String? cursor}) async =>
      MessagePage(items: stored.reversed.toList());

  @override
  Future<ChatMessage> send(String conversationId, String text) async {
    if (sendFailure != null) throw sendFailure!;
    sent.add(text);
    final message = ChatMessage(
      id: 'm${100 + sent.length}',
      conversationId: conversationId,
      senderId: myId,
      text: text,
      sentAt: DateTime.utc(2026, 11, 6, 20, 30 + sent.length),
    );
    stored.add(message);
    return message;
  }

  @override
  Future<InboxPage> inbox({
    InboxFilter filter = InboxFilter.all,
    String? cursor,
  }) async {
    inboxCalls.add(filter);
    return InboxPage(
      items: [
        for (final entry in inboxEntries)
          if (filter.role == null || entry.role.name == filter.role) entry,
      ],
    );
  }

  @override
  Future<void> markRead(String conversationId) async =>
      read.add(conversationId);
}

/// Tiempo real falso: la prueba empuja mensajes con [push].
class FakeChatRealtime implements ChatRealtime {
  final _controller = StreamController<ChatMessage>.broadcast();
  final _agreements = StreamController<String>.broadcast();
  int starts = 0;

  void push(ChatMessage message) => _controller.add(message);

  /// `agreementChanged` de la conversacion.
  void agreementChanged(String conversationId) =>
      _agreements.add(conversationId);

  @override
  Stream<ChatMessage> get messages => _controller.stream;

  @override
  Stream<String> get agreementChanges => _agreements.stream;

  @override
  void start() => starts++;

  @override
  Future<void> stop() async {}
}
