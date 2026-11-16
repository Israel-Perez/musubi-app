import 'package:flutter/foundation.dart';

/// Estado de un apartado (`ReservationResponse.status`, HU-52).
enum ReservationStatus {
  /// Por recoger: guarda una pieza durante 24 h.
  active,

  /// Se entrego (nacio un pedido completado).
  collected,
  cancelled,
  expired;

  static ReservationStatus parse(Object? value) => switch (value) {
    'collected' => collected,
    'cancelled' => cancelled,
    'expired' => expired,
    _ => active,
  };
}

/// Las pestanas de `Mis-apartados`: "Yo aparté" y "Me apartaron".
enum ReservationTab {
  buyer('buyer'),
  seller('seller');

  new(this.code);

  /// `?tab=` de `GET /reservations/mine`.
  final String code;
}

/// Un apartado, visto por una de sus partes (`ReservationResponse`).
/// [code] y [qrPayload] solo llegan a quien aparto mientras esta activo;
/// [codeAttemptsLeft], solo a quien vende.
@immutable
class Reservation {
  const new({
    required this.id,
    required this.number,
    required this.status,
    required this.isBuyer,
    required this.productId,
    required this.title,
    required this.priceCents,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.pointSlug,
    required this.pointName,
    required this.pickupAt,
    required this.expiresAt,
    required this.createdAt,
    required this.conversationId,
    this.photoUrl,
    this.code,
    this.qrPayload,
    this.codeAttemptsLeft,
    this.verifiedAt,
    this.orderId,
    this.cancelledBy,
    this.updatedAt,
  });

  final String id;

  /// "AP-4821".
  final String number;
  final ReservationStatus status;
  final bool isBuyer;
  final String productId;
  final String title;
  final String? photoUrl;
  final int priceCents;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String pointSlug;
  final String pointName;
  final DateTime pickupAt;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String conversationId;

  /// Los 6 digitos ("482173").
  final String? code;

  /// `musubi:apartado:{id}:{code}`.
  final String? qrPayload;
  final int? codeAttemptsLeft;
  final DateTime? verifiedAt;

  /// El pedido completado que nacio al entregar.
  final String? orderId;

  /// `buyer`, `seller` o `system`.
  final String? cancelledBy;
  final DateTime? updatedAt;

  bool get active => status == ReservationStatus.active;
  bool get verified => verifiedAt != null;

  /// El nombre de la otra parte.
  String get otherName => isBuyer ? sellerName : buyerName;

  /// "482 173", como lo dicta quien aparto.
  String? get spacedCode {
    final code = this.code;
    if (code == null || code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }
}

/// `GET /reservations/mine`: una pestana y los numeros de las dos.
@immutable
class ReservationPage {
  const new({required this.items, this.bought = 0, this.sold = 0});

  final List<Reservation> items;

  /// "Yo aparté (n)".
  final int bought;

  /// "Me apartaron (n)".
  final int sold;
}

/// "Valeria C." a partir de "Valeria Cruz" (como la maqueta).
String shortPersonName(String fullName) {
  final words = fullName.trim().split(RegExp(r'\s+'));
  if (words.length < 2 || words[1].isEmpty) return words.first;
  return '${words.first} ${words[1][0].toUpperCase()}.';
}

/// El QR de un apartado (`musubi:apartado:{id}:{code}`, spec
/// `musubi-api:HU-52`). Devuelve el codigo solo si el QR es de [reservationId]:
/// el QR de otro apartado no se acepta.
String? codeFromQr(String? raw, String reservationId) {
  if (raw == null) return null;
  final match = RegExp(r'^musubi:apartado:([0-9a-f]{24}):(\d{6})$')
      .firstMatch(raw.trim());
  if (match == null || match.group(1) != reservationId) return null;
  return match.group(2);
}

/// Una hora para pasar por lo apartado ("Hoy 1:00 p. m.").
@immutable
class PickupSlot {
  const new(this.at);

  /// Hora local.
  final DateTime at;

  @override
  bool operator ==(Object other) => other is PickupSlot && other.at == at;

  @override
  int get hashCode => at.hashCode;
}

/// Las horas de `Apartar` ("¿Cuándo pasas?"). La API acepta cualquier hora de
/// las proximas 24 h entre las 7:00 y las 21:00; la maqueta ofrece tres
/// botones: las 10:00, 13:00 y 17:00 de hoy y de mañana que caen en la
/// ventana (con 30 min de margen para llegar). Si quedan menos de tres, se
/// completan con las horas en punto del final de la ventana (a las 9:41, la
/// maqueta dice "Mañana 10:00 a. m.", que ya pasa de las 24 h: queda
/// "Mañana 9:00 a. m.").
abstract final class PickupSlots {
  static const _menu = [10, 13, 17];
  static const _first = 7;
  static const _last = 21;
  static const _lead = Duration(minutes: 30);
  static const _window = Duration(hours: 24);

  static List<PickupSlot> around(DateTime nowLocal, {int count = 3}) {
    final earliest = nowLocal.add(_lead);
    final latest = nowLocal.add(_window).subtract(const Duration(minutes: 5));
    bool fits(DateTime at) =>
        !at.isBefore(earliest) &&
        !at.isAfter(latest) &&
        at.hour >= _first &&
        (at.hour < _last || (at.hour == _last && at.minute == 0));

    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final picked = <DateTime>[
      for (final day in [today, today.add(const Duration(days: 1))])
        for (final hour in _menu)
          if (fits(DateTime(day.year, day.month, day.day, hour)))
            DateTime(day.year, day.month, day.day, hour),
    ];
    var at = DateTime(latest.year, latest.month, latest.day, latest.hour);
    while (picked.length < count && !at.isBefore(earliest)) {
      if (fits(at) && !picked.contains(at)) picked.add(at);
      at = at.subtract(const Duration(hours: 1));
    }
    picked.sort();
    return [for (final at in picked.take(count)) PickupSlot(at)];
  }
}

/// `/reservations/*` (spec `musubi-api:HU-52`).
abstract interface class ReservationRepository {
  /// "Apartar": guarda una pieza 24 h.
  Future<Reservation> create({
    required String productId,
    required String meetingPoint,
    required DateTime pickupAt,
  });

  /// `Mis-apartados`: una pestana y los numeros de las dos.
  Future<ReservationPage> mine(ReservationTab tab);

  Future<Reservation> get(String id);

  /// "Cancelar apartado" (cualquiera de las partes).
  Future<Reservation> cancel(String id);

  /// Quien vende: el codigo del QR o escrito.
  Future<Reservation> verify(String id, String code);

  /// "Confirmar entrega": nace un pedido completado.
  Future<Reservation> complete(String id);
}
