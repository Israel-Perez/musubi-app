import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/domain/listings_repository.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// [ListingsRepository] sobre las filas "M-03" de
/// `musubi-api/docs/endpoints.md` (specs `musubi-api:HU-06` y
/// `musubi-api:HU-07`). Usa el cliente con sesion.
class HttpListingsRepository implements ListingsRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<List<CatalogCategory>> categories() => _guard(() async {
    final response = await _dio.get<List<dynamic>>(ApiPaths.categories);
    return [
      for (final item
          in (response.data ?? const []).cast<Map<String, dynamic>>())
        CatalogCategory(
          slug: item['slug'] as String,
          name: item['name'] as String,
          photoUrl: categoryPhoto(item['slug'] as String),
        ),
    ];
  });

  @override
  Future<UploadedPhoto> uploadPhoto(String filePath) => _guard(() async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.productPhotos,
      data: form,
    );
    final body = _body(response);
    return UploadedPhoto(
      key: body['key'] as String,
      url: mediaUrl(body['path'] as String, _apiBaseUrl),
    );
  });

  @override
  Future<ProductSummary> publish(NewListing listing) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.products,
      data: listing.toJson(),
    );
    return productFromJson(_body(response), _apiBaseUrl);
  });

  @override
  Future<List<OwnListing>> mine() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.myProducts);
    return [
      for (final item
          in (_body(response)['items'] as List<dynamic>)
              .cast<Map<String, dynamic>>())
        _own(item),
    ];
  });

  @override
  Future<OwnListing> update(String id, ListingUpdate update) =>
      _guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          ApiPaths.product(id),
          data: update.toJson(),
        );
        return _own(_body(response));
      });

  @override
  Future<OwnListing> pause(String id) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.productPause(id),
    );
    return _own(_body(response));
  });

  @override
  Future<OwnListing> resume(String id) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.productResume(id),
    );
    return _own(_body(response));
  });

  @override
  Future<void> delete(String id) =>
      _guard(() => _dio.delete<void>(ApiPaths.product(id)));

  /// `ProductResponse` propio → publicacion con su estado y lo editable.
  OwnListing _own(Map<String, dynamic> item) => OwnListing(
    product: productFromJson(item, _apiBaseUrl),
    status: switch (item['status']) {
      'soldOut' => ListingStatus.soldOut,
      'hidden' => ListingStatus.hidden,
      _ => ListingStatus.active,
    },
    description: item['description'] as String? ?? '',
    condition: item['condition'] == 'new'
        ? ProductCondition.brandNew
        : ProductCondition.used,
    usedDetail: switch (item['conditionDetail']) {
      'likeNew' => UsedDetail.likeNew,
      'good' => UsedDetail.good,
      'fair' => UsedDetail.fair,
      _ => null,
    },
  );

  @override
  Future<PriceRange?> priceRange(String category) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.priceRange,
      queryParameters: {'category': category},
    );
    final body = response.data;
    if (response.statusCode == 204 || body == null) return null;
    return PriceRange(
      lowCents: (body['lowCents'] as num).toInt(),
      highCents: (body['highCents'] as num).toInt(),
    );
  });

  static Map<String, dynamic> _body(Response<Map<String, dynamic>> response) =>
      response.data ??
      (throw const ApiFailure(
        code: ApiFailure.serverError,
        message: 'El servidor respondió algo inesperado.',
      ));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      // Se traduce (no se traga): la pantalla decide por el code.
      throw ApiFailure.fromDio(error);
    }
  }
}
