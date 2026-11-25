import 'dart:typed_data';

import 'package:musubi_app/features/chat/domain/chat_models.dart';

/// Conversaciones y mensajes (HU-20) y bandeja (HU-22), con sesion. Lanza
/// `ApiFailure` (nunca `DioException`).
abstract interface class ChatRepository {
  /// "Mensaje" en una publicacion: abre la conversacion con el vendedor, o la
  /// que ya existia (la API es idempotente).
  Future<Conversation> start(String productId);

  /// Encabezado y tarjeta de una conversacion.
  Future<Conversation> conversation(String id);

  /// Mensajes del mas nuevo al mas viejo.
  Future<MessagePage> messages(String conversationId, {String? cursor});

  /// Envia un texto; la API lo modera antes de guardarlo.
  Future<ChatMessage> send(String conversationId, String text);

  /// HU-65: envia una foto (la API la modera antes de guardarla).
  Future<ChatMessage> sendPhoto(String conversationId, String filePath);

  /// HU-65: los bytes de una foto del chat (solo para los participantes).
  Future<Uint8List> photo(String path);

  /// Bandeja: conversaciones con mensajes, por actividad reciente.
  Future<InboxPage> inbox({
    InboxFilter filter = InboxFilter.all,
    String? cursor,
  });

  /// Deja en cero mis no leidos de la conversacion.
  Future<void> markRead(String conversationId);
}

/// Mensajes que llegan en tiempo real (`messageCreated` de `/hubs/chat`).
abstract interface class ChatRealtime {
  /// Cada mensaje nuevo de cualquiera de mis conversaciones (tambien los mios,
  /// que llegan a mis otros dispositivos).
  Stream<ChatMessage> get messages;

  /// El id de cada conversacion cuyo acuerdo con IA cambio (`agreementChanged`,
  /// HU-34): se pidio, se corrigio, se confirmo, se descarto o ya es pedido.
  Stream<String> get agreementChanges;

  /// HU-65: "Escribiendo…" de la otra persona (no se guarda).
  Stream<TypingSignal> get typing;

  /// HU-65: alguien abrio una conversacion ("Leído").
  Stream<ReadSignal> get reads;

  /// HU-65: avisa que estoy escribiendo en [conversationId] (sin respuesta;
  /// sin conexion no hace nada).
  void sendTyping(String conversationId);

  /// Conecta (y reconecta solo) mientras haya sesion.
  void start();

  /// Cierra la conexion.
  Future<void> stop();
}
