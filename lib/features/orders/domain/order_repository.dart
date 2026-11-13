import 'package:musubi_app/features/orders/domain/order_models.dart';

/// Pedidos (HU-23 y HU-24). Lanza `ApiFailure` con el mensaje en espanol de
/// la API.
abstract interface class OrderRepository {
  /// Los puntos de entrega del campus, con el edificio de mi carrera marcado.
  Future<List<MeetingPoint>> meetingPoints();

  /// "Crear pedido": nace Pendiente (RN-16).
  Future<Order> create(NewOrder order);

  /// "Crear pedido" desde el acuerdo con IA que confirmaron los dos (HU-34,
  /// RF-47): la API toma todo del acuerdo y lo borra.
  Future<Order> createFromAgreement(String agreementId);

  /// Los pedidos de una conversacion, del mas nuevo al mas viejo.
  Future<List<Order>> byConversation(String conversationId);

  /// "Tu pedido".
  Future<Order> get(String id);

  /// "Mis pedidos" (HU-25): mis compras de una pestana (sin pestana, todas),
  /// con los numeros de las tres. [limit] de 1 a 50 (20 si no se manda).
  Future<MyOrdersPage> mine({MyOrdersTab? tab, String? cursor, int? limit});

  /// "Vendidos" de `Mis-productos` (HU-26): mis ventas completadas, con el
  /// numero y el total de todas.
  Future<SalesPage> sales({String? cursor});

  /// "Confirmar pago en efectivo" (RN-18).
  Future<Order> payCash(String id);

  /// "Aceptar pedido" (HU-24): solo quien vende, con el pago elegido.
  Future<Order> accept(String id);

  /// "Rechazar" o "Cancelar pedido" con su motivo (HU-24, RN-20).
  Future<Order> cancel(String id, CancelReason reason);

  /// "Confirmar entrega" de quien mira; con las dos, se completa (RN-19).
  Future<Order> confirmHandover(String id);
}
