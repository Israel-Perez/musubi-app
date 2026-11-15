import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/orders/domain/reservation_models.dart';

/// Id (24 hex, como la API) del apartado de la calculadora.
const casioReservationId = '6716a0000000000000000a01';

/// Id del apartado de las escuadras (me apartaron).
const squaresReservationId = '6716a0000000000000000a02';

/// Un apartado de las pruebas: por defecto, la calculadora que Ana aparto a
/// Valeria (`Apartado-listo`, codigo 482 173).
Reservation sampleReservation({
  String id = casioReservationId,
  String number = 'AP-4821',
  bool isBuyer = true,
  ReservationStatus status = ReservationStatus.active,
  String title = 'Calculadora Casio fx-991ES Plus',
  int priceCents = 45000,
  String? photoUrl = 'asset:assets/products/casio.webp',
  String buyerName = 'Ana Sofía Ramírez',
  String sellerName = 'Valeria Cruz',
  String pointName = 'Biblioteca Central',
  DateTime? pickupAt,
  DateTime? expiresAt,
  DateTime? verifiedAt,
  DateTime? updatedAt,
  String? orderId,
  int? codeAttemptsLeft,
}) {
  final active = status == ReservationStatus.active;
  final pickup = pickupAt ?? DateTime.utc(2026, 10, 5, 19);
  return Reservation(
    id: id,
    number: number,
    status: status,
    isBuyer: isBuyer,
    productId: 'p-$id',
    title: title,
    photoUrl: photoUrl,
    priceCents: priceCents,
    buyerId: 'buyer-$id',
    buyerName: buyerName,
    sellerId: 'seller-$id',
    sellerName: sellerName,
    pointSlug: 'biblioteca',
    pointName: pointName,
    pickupAt: pickup,
    expiresAt: expiresAt ?? pickup.add(const Duration(hours: 23)),
    createdAt: pickup.subtract(const Duration(hours: 1)),
    conversationId: 'c-$id',
    code: active && isBuyer ? '482173' : null,
    qrPayload: active && isBuyer ? 'musubi:apartado:$id:482173' : null,
    codeAttemptsLeft: active && !isBuyer ? codeAttemptsLeft ?? 5 : null,
    verifiedAt: verifiedAt,
    orderId: orderId,
    updatedAt: updatedAt,
  );
}

/// Las escuadras que Luis aparto a Ana (`Verificar-comprador`).
Reservation sampleSellerReservation({
  ReservationStatus status = ReservationStatus.active,
  DateTime? verifiedAt,
  int? codeAttemptsLeft,
}) => sampleReservation(
  id: squaresReservationId,
  number: 'AP-4822',
  isBuyer: false,
  status: status,
  title: 'Juego de escuadras y compás',
  priceCents: 18000,
  photoUrl: 'asset:assets/products/compas.webp',
  buyerName: 'Luis Martínez',
  sellerName: 'Ana Sofía Ramírez',
  pickupAt: DateTime.utc(2026, 10, 5, 21),
  verifiedAt: verifiedAt,
  codeAttemptsLeft: codeAttemptsLeft,
);

/// Apartados en memoria (HU-52). El codigo correcto es `482173`.
class FakeReservationRepository implements ReservationRepository {
  new({List<Reservation>? reservations}) : reservations = [...?reservations];

  final List<Reservation> reservations;

  /// Falla el siguiente "Apartar".
  ApiFailure? createFailure;

  final List<(String, String, DateTime)> created = [];
  final List<String> verifiedCodes = [];
  final List<String> cancelled = [];
  final List<String> completed = [];

  Reservation _find(String id) => reservations.firstWhere(
    (r) => r.id == id,
    orElse: () => throw const ApiFailure(
      code: 'reservations.not_found',
      message: 'No encontramos este apartado.',
      status: 404,
    ),
  );

  void _replace(Reservation next) {
    final i = reservations.indexWhere((r) => r.id == next.id);
    reservations[i] = next;
  }

  @override
  Future<Reservation> create({
    required String productId,
    required String meetingPoint,
    required DateTime pickupAt,
  }) async {
    created.add((productId, meetingPoint, pickupAt));
    final failure = createFailure;
    if (failure != null) {
      createFailure = null;
      throw failure;
    }
    final reservation = sampleReservation(pickupAt: pickupAt.toUtc());
    reservations.add(reservation);
    return reservation;
  }

  @override
  Future<ReservationPage> mine(ReservationTab tab) async {
    final bought = reservations.where((r) => r.isBuyer).toList();
    final sold = reservations.where((r) => !r.isBuyer).toList();
    return ReservationPage(
      items: tab == ReservationTab.buyer ? bought : sold,
      bought: bought.length,
      sold: sold.length,
    );
  }

  @override
  Future<Reservation> get(String id) async => _find(id);

  @override
  Future<Reservation> cancel(String id) async {
    cancelled.add(id);
    final next = _copy(
      _find(id),
      status: ReservationStatus.cancelled,
      cancelledBy: 'buyer',
    );
    _replace(next);
    return next;
  }

  @override
  Future<Reservation> verify(String id, String code) async {
    verifiedCodes.add(code);
    final current = _find(id);
    if (code != '482173') {
      final left = (current.codeAttemptsLeft ?? 5) - 1;
      _replace(_copy(current, codeAttemptsLeft: left));
      throw left <= 0
          ? const ApiFailure(
              code: 'reservations.code_locked',
              message:
                  'Se acabaron los intentos del código. Escríbele a quien '
                  'apartó.',
              status: 409,
            )
          : const ApiFailure(
              code: 'reservations.invalid_code',
              message:
                  'El código no coincide. Revisa que sea el apartado de esta '
                  'persona.',
              status: 422,
            );
    }
    final next = _copy(current, verifiedAt: DateTime.utc(2026, 10, 5, 21));
    _replace(next);
    return next;
  }

  @override
  Future<Reservation> complete(String id) async {
    completed.add(id);
    final next = _copy(
      _find(id),
      status: ReservationStatus.collected,
      orderId: 'o-$id',
    );
    _replace(next);
    return next;
  }

  static Reservation _copy(
    Reservation r, {
    ReservationStatus? status,
    String? cancelledBy,
    DateTime? verifiedAt,
    String? orderId,
    int? codeAttemptsLeft,
  }) => Reservation(
    id: r.id,
    number: r.number,
    status: status ?? r.status,
    isBuyer: r.isBuyer,
    productId: r.productId,
    title: r.title,
    photoUrl: r.photoUrl,
    priceCents: r.priceCents,
    buyerId: r.buyerId,
    buyerName: r.buyerName,
    sellerId: r.sellerId,
    sellerName: r.sellerName,
    pointSlug: r.pointSlug,
    pointName: r.pointName,
    pickupAt: r.pickupAt,
    expiresAt: r.expiresAt,
    createdAt: r.createdAt,
    conversationId: r.conversationId,
    code: (status ?? r.status) == ReservationStatus.active ? r.code : null,
    qrPayload: (status ?? r.status) == ReservationStatus.active
        ? r.qrPayload
        : null,
    codeAttemptsLeft: codeAttemptsLeft ?? r.codeAttemptsLeft,
    verifiedAt: verifiedAt ?? r.verifiedAt,
    orderId: orderId ?? r.orderId,
    cancelledBy: cancelledBy ?? r.cancelledBy,
    updatedAt: r.updatedAt,
  );
}
