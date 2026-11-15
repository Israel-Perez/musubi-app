import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/listings/data/http_listings_repository.dart';
import 'package:musubi_app/features/seller_support/domain/seller_support.dart';

/// [SellerSupportRepository] sobre las filas "M-12" de
/// `musubi-api/docs/endpoints.md` (specs `musubi-api:HU-36`, `HU-37` y
/// `HU-38`). Usa el cliente con sesion.
class HttpSellerSupportRepository implements SellerSupportRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<SlowListings> slow() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.slowProducts,
    );
    final body = response.data ?? const <String, dynamic>{};
    return SlowListings(
      thresholdDays: (body['thresholdDays'] as num? ?? 21).toInt(),
      items: [
        for (final item
            in (body['items'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          _slow(item),
      ],
    );
  });

  @override
  Future<ProductDemand> demand(String productId) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.productDemand(productId),
    );
    final body = response.data ?? const <String, dynamic>{};
    return ProductDemand(
      people: _int(body['people']),
      alerts: _int(body['alerts']),
      requests: [
        for (final item
            in (body['requests'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          DemandRequest(
            id: item['id'] as String,
            title: item['title'] as String? ?? '',
            budgetCents: _int(item['budgetCents']),
            requesterName: item['requesterName'] as String? ?? '',
            expiresAt: DateTime.parse(item['expiresAt'] as String).toUtc(),
          ),
      ],
    );
  });

  SlowListing _slow(Map<String, dynamic> item) {
    final demand = item['demand'] as Map<String, dynamic>? ?? const {};
    return SlowListing(
      listing: ownListingFromJson(
        item['product'] as Map<String, dynamic>,
        _apiBaseUrl,
      ),
      daysListed: _int(item['daysListed']),
      views: _int(item['views']),
      messages: _int(item['messages']),
      people: _int(demand['people']),
      requests: _int(demand['requests']),
      tips: [
        for (final tip
            in (item['tips'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          SalesTip(
            kind: SalesTipKind.parse(tip['kind'] as String?),
            title: tip['title'] as String? ?? '',
            body: tip['body'] as String? ?? '',
            applies: tip['applies'] as bool? ?? false,
          ),
      ],
    );
  }

  static int _int(Object? value) => (value as num? ?? 0).toInt();

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      // Se traduce (no se traga): la pantalla decide por el code.
      throw ApiFailure.fromDio(error);
    }
  }
}
