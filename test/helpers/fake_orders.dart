import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/domain/order_repository.dart';

/// Los puntos de la UTTT de las pruebas: Biblioteca, Cafeteria y el edificio
/// de Tecnologias de la Informacion como el recomendado.
const samplePoints = [
  MeetingPoint(slug: 'biblioteca', name: 'Biblioteca'),
  MeetingPoint(slug: 'cafeteria', name: 'Cafetería'),
  MeetingPoint(
    slug: 'tecnologias-informacion',
    name: 'Tecnologías de la Información',
    suggested: true,
  ),
];

/// Un pedido pendiente de la calculadora (conversacion `c1`).
Order sampleOrder({
  String id = 'o1',
  bool isBuyer = true,
  bool paysCash = false,
  OrderStatus status = OrderStatus.pending,
  int quantity = 1,
}) => Order(
  id: id,
  number: 'MS-1001',
  status: status,
  isBuyer: isBuyer,
  conversationId: 'c1',
  item: OrderItem(
    title: 'Calculadora Casio fx-991ES Plus',
    priceCents: 45000,
    quantity: quantity,
    totalCents: 45000 * quantity,
    productId: 'p1',
  ),
  buyerName: 'Ana Sofía Ramírez',
  sellerName: 'Valeria Cruz',
  pointName: 'Biblioteca',
  detail: 'Planta baja',
  deliveryAt: DateTime.utc(2026, 11, 7, 19),
  paysCash: paysCash,
);

/// Repositorio de pedidos en memoria: guarda lo que se le pide.
class FakeOrderRepository implements OrderRepository {
  new({List<Order>? orders, this.points = samplePoints})
    : stored = orders ?? [];

  final List<Order> stored;
  final List<MeetingPoint> points;

  final List<NewOrder> created = [];
  final List<String> paid = [];
  ApiFailure? createFailure;
  ApiFailure? payFailure;

  @override
  Future<List<MeetingPoint>> meetingPoints() async => points;

  @override
  Future<Order> create(NewOrder order) async {
    created.add(order);
    if (createFailure != null) throw createFailure!;
    final made = Order(
      id: 'o${stored.length + 1}',
      number: 'MS-${1001 + stored.length}',
      status: OrderStatus.pending,
      isBuyer: true,
      conversationId: order.conversationId,
      item: OrderItem(
        title: 'Calculadora Casio fx-991ES Plus',
        priceCents: 45000,
        quantity: order.quantity,
        totalCents: 45000 * order.quantity,
      ),
      buyerName: 'Ana Sofía Ramírez',
      sellerName: 'Valeria Cruz',
      pointName: points.firstWhere((p) => p.slug == order.meetingPoint).name,
      detail: order.detail,
      deliveryAt: order.deliveryAt.toUtc(),
    );
    stored.add(made);
    return made;
  }

  @override
  Future<List<Order>> byConversation(String conversationId) async => [
    for (final order in stored.reversed)
      if (order.conversationId == conversationId) order,
  ];

  @override
  Future<Order> get(String id) async => stored.firstWhere((o) => o.id == id);

  @override
  Future<Order> payCash(String id) async {
    paid.add(id);
    if (payFailure != null) throw payFailure!;
    final i = stored.indexWhere((o) => o.id == id);
    final o = stored[i];
    return stored[i] = Order(
      id: o.id,
      number: o.number,
      status: o.status,
      isBuyer: o.isBuyer,
      conversationId: o.conversationId,
      item: o.item,
      buyerName: o.buyerName,
      sellerName: o.sellerName,
      pointName: o.pointName,
      detail: o.detail,
      deliveryAt: o.deliveryAt,
      paysCash: true,
    );
  }
}
