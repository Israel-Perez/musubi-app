import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/orders/domain/reservation_models.dart';

/// [ReservationRepository] sobre "Apartados (HU-52)" de
/// `musubi-api/docs/endpoints.md` (spec `musubi-api:HU-52`). Siempre con
/// sesion.
class HttpReservationRepository implements ReservationRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<Reservation> create({
    required String productId,
    required String meetingPoint,
    required DateTime pickupAt,
  }) => _one(
    () => _dio.post<Map<String, dynamic>>(
      ApiPaths.reservations,
      data: {
        'productId': productId,
        'meetingPoint': meetingPoint,
        'pickupAt': pickupAt.toUtc().toIso8601String(),
      },
    ),
  );

  @override
  Future<ReservationPage> mine(ReservationTab tab) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.myReservations,
      queryParameters: {'tab': tab.code},
    );
    final body = response.data ?? const <String, dynamic>{};
    final counts = body['counts'] as Map<String, dynamic>? ?? const {};
    return ReservationPage(
      items: [
        for (final item
            in (body['items'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          reservationFromJson(item, _apiBaseUrl),
      ],
      bought: (counts['bought'] as num? ?? 0).toInt(),
      sold: (counts['sold'] as num? ?? 0).toInt(),
    );
  });

  @override
  Future<Reservation> get(String id) =>
      _one(() => _dio.get<Map<String, dynamic>>(ApiPaths.reservation(id)));

  @override
  Future<Reservation> cancel(String id) => _one(
    () => _dio.post<Map<String, dynamic>>(ApiPaths.reservationCancel(id)),
  );

  @override
  Future<Reservation> verify(String id, String code) => _one(
    () => _dio.post<Map<String, dynamic>>(
      ApiPaths.reservationVerify(id),
      data: {'code': code},
    ),
  );

  @override
  Future<Reservation> complete(String id) => _one(
    () => _dio.post<Map<String, dynamic>>(ApiPaths.reservationComplete(id)),
  );

  Future<Reservation> _one(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) => _guard(() async {
    final response = await call();
    return reservationFromJson(response.data ?? const {}, _apiBaseUrl);
  });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}

DateTime? _date(Object? value) => switch (value) {
  final String at => DateTime.parse(at).toUtc(),
  _ => null,
};

/// Un `ReservationResponse` de la API (fixture `reservation.json`). La foto
/// llega como ruta (`/media/...`) relativa a [apiBaseUrl].
Reservation reservationFromJson(Map<String, dynamic> json, Uri apiBaseUrl) {
  final buyer = json['buyer'] as Map<String, dynamic>? ?? const {};
  final seller = json['seller'] as Map<String, dynamic>? ?? const {};
  final photo = json['photo'] as String?;
  final now = DateTime.now().toUtc();
  return Reservation(
    id: json['id'] as String? ?? '',
    number: json['number'] as String? ?? '',
    status: ReservationStatus.parse(json['status']),
    isBuyer: json['role'] != 'seller',
    productId: json['productId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    photoUrl: photo == null ? null : mediaUrl(photo, apiBaseUrl),
    priceCents: (json['priceCents'] as num? ?? 0).toInt(),
    buyerId: buyer['id'] as String? ?? '',
    buyerName: buyer['name'] as String? ?? '',
    sellerId: seller['id'] as String? ?? '',
    sellerName: seller['name'] as String? ?? '',
    pointSlug: json['pointSlug'] as String? ?? '',
    pointName: json['pointName'] as String? ?? '',
    pickupAt: _date(json['pickupAt']) ?? now,
    expiresAt: _date(json['expiresAt']) ?? now,
    createdAt: _date(json['createdAt']) ?? now,
    conversationId: json['conversationId'] as String? ?? '',
    code: json['code'] as String?,
    qrPayload: json['qrPayload'] as String?,
    codeAttemptsLeft: (json['codeAttemptsLeft'] as num?)?.toInt(),
    verifiedAt: _date(json['verifiedAt']),
    orderId: json['orderId'] as String?,
    cancelledBy: json['cancelledBy'] as String?,
    updatedAt: _date(json['updatedAt']),
  );
}
