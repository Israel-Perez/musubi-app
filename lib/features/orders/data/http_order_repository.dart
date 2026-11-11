import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/domain/order_repository.dart';

/// [OrderRepository] sobre las filas "M-08" de `musubi-api/docs/endpoints.md`
/// (spec `musubi-api:HU-23`). Siempre con sesion.
class HttpOrderRepository implements OrderRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<List<MeetingPoint>> meetingPoints() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.meetingPoints,
    );
    return [
      for (final item
          in (response.data?['items'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        MeetingPoint(
          slug: item['slug'] as String,
          name: item['name'] as String,
          suggested: item['suggested'] as bool? ?? false,
        ),
    ];
  });

  @override
  Future<Order> create(NewOrder order) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.orders,
      data: order.toJson(),
    );
    return orderFromJson(response.data ?? const {}, _apiBaseUrl);
  });

  @override
  Future<Order> createFromAgreement(String agreementId) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.orders,
      data: {'agreementId': agreementId},
    );
    return orderFromJson(response.data ?? const {}, _apiBaseUrl);
  });

  @override
  Future<List<Order>> byConversation(String conversationId) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.orders,
      queryParameters: {'conversationId': conversationId},
    );
    return [
      for (final item
          in (response.data?['items'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        orderFromJson(item, _apiBaseUrl),
    ];
  });

  @override
  Future<Order> get(String id) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.order(id));
    return orderFromJson(response.data ?? const {}, _apiBaseUrl);
  });

  @override
  Future<Order> payCash(String id) => _guard(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiPaths.orderPayment(id),
      data: const {'method': 'cash'},
    );
    return orderFromJson(response.data ?? const {}, _apiBaseUrl);
  });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}

/// Un `OrderResponse` de la API (fixture `order.json`). La foto llega como
/// ruta (`/media/...`) relativa a [apiBaseUrl].
Order orderFromJson(Map<String, dynamic> json, Uri apiBaseUrl) {
  final item = json['item'] as Map<String, dynamic>? ?? const {};
  final delivery = json['delivery'] as Map<String, dynamic>? ?? const {};
  final payment = json['payment'] as Map<String, dynamic>?;
  final photo = item['photo'] as String?;
  return Order(
    id: json['id'] as String? ?? '',
    number: json['number'] as String? ?? '',
    status: OrderStatus.parse(json['status']),
    isBuyer: json['role'] != 'seller',
    conversationId: json['conversationId'] as String? ?? '',
    item: OrderItem(
      title: item['title'] as String? ?? '',
      priceCents: (item['priceCents'] as num? ?? 0).toInt(),
      quantity: (item['quantity'] as num? ?? 1).toInt(),
      totalCents: (item['totalCents'] as num? ?? 0).toInt(),
      photoUrl: photo == null ? null : mediaUrl(photo, apiBaseUrl),
      productId: item['productId'] as String?,
    ),
    buyerName:
        (json['buyer'] as Map<String, dynamic>?)?['name'] as String? ?? '',
    sellerName:
        (json['seller'] as Map<String, dynamic>?)?['name'] as String? ?? '',
    pointName: delivery['pointName'] as String? ?? '',
    detail: delivery['detail'] as String?,
    deliveryAt: DateTime.parse(delivery['at'] as String).toUtc(),
    paysCash: payment?['method'] == 'cash',
    transferAvailable: json['transferAvailable'] as bool? ?? false,
  );
}
