import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/domain/order_repository.dart';
import 'package:musubi_app/features/orders/domain/payment_models.dart';

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
  bool paysTransfer = false,
  bool transferAvailable = false,
  DateTime? transferReportedAt,
  DateTime? transferNotReceivedAt,
  DateTime? transferValidatedAt,
  String? transferReference,
  String? deliveryCode,
  int? codeAttemptsLeft,
  OrderStatus status = OrderStatus.pending,
  int quantity = 1,
  bool buyerConfirmed = false,
  bool sellerConfirmed = false,
  bool buyerArrived = false,
  bool sellerArrived = false,
  OrderCancellation? cancellation,
  String title = 'Calculadora Casio fx-991ES Plus',
  int priceCents = 45000,
  DateTime? updatedAt,
}) => Order(
  id: id,
  number: 'MS-1001',
  status: status,
  isBuyer: isBuyer,
  conversationId: 'c1',
  item: OrderItem(
    title: title,
    priceCents: priceCents,
    quantity: quantity,
    totalCents: priceCents * quantity,
    productId: 'p1',
  ),
  buyerName: 'Ana Sofía Ramírez',
  sellerName: 'Valeria Cruz',
  pointName: 'Biblioteca',
  detail: 'Planta baja',
  deliveryAt: DateTime.utc(2026, 11, 7, 19),
  paysCash: paysCash,
  paysTransfer: paysTransfer,
  transferAvailable: transferAvailable,
  transferReportedAt: transferReportedAt,
  transferNotReceivedAt: transferNotReceivedAt,
  transferValidatedAt: transferValidatedAt,
  transferReference: transferReference,
  deliveryCode: deliveryCode,
  codeAttemptsLeft: codeAttemptsLeft,
  buyerConfirmed: buyerConfirmed,
  sellerConfirmed: sellerConfirmed,
  buyerArrived: buyerArrived,
  sellerArrived: sellerArrived,
  cancellation: cancellation,
  updatedAt: updatedAt,
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

  final List<String> fromAgreements = [];

  @override
  Future<Order> createFromAgreement(String agreementId) async {
    fromAgreements.add(agreementId);
    if (createFailure != null) throw createFailure!;
    final made = sampleOrder(id: 'o${stored.length + 1}', quantity: 2);
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

  /// Lo que pidio "Mis pedidos" (HU-25): pestana, cursor y limite.
  final List<(MyOrdersTab?, String?, int?)> mineCalls = [];

  /// Falla la siguiente lectura de "Mis pedidos".
  ApiFailure? mineFailure;

  /// Mis compras, del mas nuevo (el ultimo de [stored]) al mas viejo, con
  /// cursor = id del ultimo de la pagina.
  @override
  Future<MyOrdersPage> mine({
    MyOrdersTab? tab,
    String? cursor,
    int? limit,
  }) async {
    mineCalls.add((tab, cursor, limit));
    final failure = mineFailure;
    if (failure != null) {
      mineFailure = null;
      throw failure;
    }
    bool inTab(Order o, MyOrdersTab t) => switch (t) {
      MyOrdersTab.active => o.status.open,
      MyOrdersTab.completed => o.status == OrderStatus.completed,
      MyOrdersTab.cancelled => o.status == OrderStatus.cancelled,
    };
    final mine = [
      for (final o in stored.reversed)
        if (o.isBuyer) o,
    ];
    final inPage = [
      for (final o in mine)
        if (tab == null || inTab(o, tab)) o,
    ];
    final start = cursor == null
        ? 0
        : inPage.indexWhere((o) => o.id == cursor) + 1;
    final size = limit ?? 20;
    final page = inPage.skip(start).take(size).toList();
    final more = start + size < inPage.length;
    int count(MyOrdersTab t) => mine.where((o) => inTab(o, t)).length;
    return MyOrdersPage(
      items: page,
      nextCursor: more ? page.last.id : null,
      total: inPage.length,
      counts: MyOrdersCounts(
        active: count(MyOrdersTab.active),
        completed: count(MyOrdersTab.completed),
        cancelled: count(MyOrdersTab.cancelled),
      ),
    );
  }

  /// Cursores que pidio "Vendidos" (HU-26).
  final List<String?> salesCalls = [];

  /// Tamano de pagina de las ventas.
  int salesPageSize = 20;

  /// Falla la siguiente lectura de las ventas.
  ApiFailure? salesFailure;

  /// Mis ventas completadas, de la mas nueva (la ultima de [stored]) a la
  /// mas vieja, con cursor = id de la ultima de la pagina.
  @override
  Future<SalesPage> sales({String? cursor}) async {
    salesCalls.add(cursor);
    final failure = salesFailure;
    if (failure != null) {
      salesFailure = null;
      throw failure;
    }
    final mine = [
      for (final o in stored.reversed)
        if (!o.isBuyer && o.status == OrderStatus.completed) o,
    ];
    final start = cursor == null
        ? 0
        : mine.indexWhere((o) => o.id == cursor) + 1;
    final page = mine.skip(start).take(salesPageSize).toList();
    return SalesPage(
      items: page,
      nextCursor: start + salesPageSize < mine.length ? page.last.id : null,
      count: mine.length,
      totalCents: mine.fold(0, (sum, o) => sum + o.item.totalCents),
    );
  }

  final List<String> accepted = [];
  final List<(String, CancelReason)> cancelled = [];
  final List<String> handovers = [];

  /// Falla la siguiente accion de HU-24 (aceptar, cancelar o entregar).
  ApiFailure? actionFailure;

  /// Hasta cuando se puede calificar un pedido que se completa (HU-27).
  DateTime completedRateUntil = DateTime.utc(2099);

  @override
  Future<Order> payCash(String id) async {
    paid.add(id);
    if (payFailure != null) throw payFailure!;
    return _replace(id, (o) => o.copyWith(paysCash: true));
  }

  /// La cuenta de Valeria (HU-55): la CLABE completa para quien compra.
  TransferDetails transferDetails = const TransferDetails(
    amountCents: 45000,
    bankName: 'BBVA México',
    holderName: 'Valeria Cruz Hernández',
    clabe: '012 180 0154 2378 9134',
    clabeLast4: '9134',
    concept: 'MS-1001',
  );

  /// El codigo de entrega que genera "aceptar" en efectivo.
  String code = '7319';

  final List<String> transfersChosen = [];
  final List<(String, String)> references = [];
  final List<String> notReceived = [];
  final List<(String, String)> codes = [];

  @override
  Future<Order> payTransfer(String id) async {
    transfersChosen.add(id);
    if (payFailure != null) throw payFailure!;
    return _replace(id, (o) => o.copyWith(paysTransfer: true, paysCash: false));
  }

  @override
  Future<TransferDetails> transfer(String id) async {
    final order = await get(id);
    final d = transferDetails;
    return TransferDetails(
      amountCents: d.amountCents,
      bankName: d.bankName,
      holderName: d.holderName,
      clabe: order.isBuyer ? d.clabe : '•••• ${d.clabeLast4}',
      clabeLast4: d.clabeLast4,
      concept: order.number,
      reference: order.transferReference,
      reportedAt: order.transferReportedAt,
      notReceivedAt: order.transferNotReceivedAt,
      validatedAt: order.transferValidatedAt,
    );
  }

  @override
  Future<Order> reportTransfer(String id, String reference) async {
    references.add((id, reference));
    _fail();
    return _replace(
      id,
      (o) => Order(
        id: o.id,
        number: o.number,
        status: o.status,
        isBuyer: o.isBuyer,
        conversationId: o.conversationId,
        item: o.item,
        buyerName: o.buyerName,
        sellerName: o.sellerName,
        pointName: o.pointName,
        deliveryAt: o.deliveryAt,
        detail: o.detail,
        paysTransfer: true,
        transferAvailable: o.transferAvailable,
        transferReference: reference,
        transferReportedAt: DateTime.utc(2026, 11, 15, 21, 14),
      ),
    );
  }

  @override
  Future<Order> transferNotReceived(String id) async {
    notReceived.add(id);
    _fail();
    return _replace(
      id,
      (o) => o.copyWith(transferNotReceivedAt: DateTime.utc(2026, 11, 15, 22)),
    );
  }

  @override
  Future<Order> deliveryCode(String id, String code) async {
    codes.add((id, code));
    _fail();
    if (code != this.code) {
      final left =
          (stored.firstWhere((o) => o.id == id).codeAttemptsLeft ?? 5) - 1;
      _replace(id, (o) => o.copyWith(codeAttemptsLeft: left));
      throw const ApiFailure(
        code: 'orders.invalid_code',
        message: 'El código no coincide. Pídeselo de nuevo a quien compra.',
        status: 422,
      );
    }
    return _replace(
      id,
      (o) => o.copyWith(
        status: OrderStatus.completed,
        buyerConfirmed: true,
        sellerConfirmed: true,
        rateUntil: completedRateUntil,
      ),
    );
  }

  @override
  Future<Order> accept(String id) async {
    accepted.add(id);
    _fail();
    return _replace(
      id,
      (o) => o.copyWith(
        status: OrderStatus.confirmed,
        transferValidatedAt: o.paysTransfer
            ? DateTime.utc(2026, 11, 15, 21, 30)
            : null,
        deliveryCode: o.paysCash && o.isBuyer ? code : null,
        codeAttemptsLeft: o.paysCash && !o.isBuyer ? 5 : null,
      ),
    );
  }

  @override
  Future<Order> cancel(String id, CancelReason reason) async {
    cancelled.add((id, reason));
    _fail();
    return _replace(
      id,
      (o) => o.copyWith(
        status: OrderStatus.cancelled,
        cancellation: OrderCancellation(byBuyer: o.isBuyer, reason: reason),
      ),
    );
  }

  @override
  Future<Order> confirmHandover(String id) async {
    handovers.add(id);
    _fail();
    return _replace(id, (o) {
      final buyer = o.buyerConfirmed || o.isBuyer;
      final seller = o.sellerConfirmed || !o.isBuyer;
      return o.copyWith(
        buyerConfirmed: buyer,
        sellerConfirmed: seller,
        status: buyer && seller ? OrderStatus.completed : null,
        // Como la API (HU-27): al completarse empieza el plazo para calificar.
        rateUntil: buyer && seller ? completedRateUntil : null,
      );
    });
  }

  /// "Ya llegué" (HU-62).
  final List<String> arrivals = [];

  @override
  Future<Order> arrived(String id) async {
    arrivals.add(id);
    _fail();
    return _replace(
      id,
      (o) => o.copyWith(
        buyerArrived: o.buyerArrived || o.isBuyer,
        sellerArrived: o.sellerArrived || !o.isBuyer,
      ),
    );
  }

  void _fail() {
    final failure = actionFailure;
    if (failure == null) return;
    actionFailure = null;
    throw failure;
  }

  Order _replace(String id, Order Function(Order) change) {
    final i = stored.indexWhere((o) => o.id == id);
    return stored[i] = change(stored[i]);
  }
}
