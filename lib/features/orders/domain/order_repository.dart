import 'package:musubi_app/features/orders/domain/order_models.dart';

/// Pedidos (HU-23). Lanza `ApiFailure` con el mensaje en espanol de la API.
abstract interface class OrderRepository {
  /// Los puntos de entrega del campus, con el edificio de mi carrera marcado.
  Future<List<MeetingPoint>> meetingPoints();

  /// "Crear pedido": nace Pendiente (RN-16).
  Future<Order> create(NewOrder order);

  /// Los pedidos de una conversacion, del mas nuevo al mas viejo.
  Future<List<Order>> byConversation(String conversationId);

  /// "Tu pedido".
  Future<Order> get(String id);

  /// "Confirmar pago en efectivo" (RN-18).
  Future<Order> payCash(String id);
}
