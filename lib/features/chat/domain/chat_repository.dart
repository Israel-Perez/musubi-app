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

  /// Conecta (y reconecta solo) mientras haya sesion.
  void start();

  /// Cierra la conexion.
  Future<void> stop();
}
