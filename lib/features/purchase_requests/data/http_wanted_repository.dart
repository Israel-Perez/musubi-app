import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_board.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_repository.dart';

/// [WantedRepository] sobre las filas "M-05" de `musubi-api/docs/endpoints.md`
/// (specs `musubi-api:HU-13` y `HU-15`). Usa el cliente con sesion: sin
/// sesion no lleva token y el tablero responde como a un visitante.
class HttpWantedRepository implements WantedRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<WantedPage> board({
    WantedBoardFilter filter = const WantedBoardFilter(),
    String? cursor,
    int? limit,
  }) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.wanted,
      queryParameters: {
        ...filter.toQuery(),
        'cursor': ?cursor,
        'limit': ?limit,
      },
    );
    final data = response.data ?? const {};
    return WantedPage(
      items: [
        for (final item
            in (data['items'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          wantedFromJson(item, apiBaseUrl: _apiBaseUrl),
      ],
      nextCursor: data['nextCursor'] as String?,
    );
  });

  @override
  Future<WantedRequest> publish(NewWanted request) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.wanted,
      data: request.toJson(),
    );
    return wantedFromJson(response.data ?? const {});
  });

  @override
  Future<List<WantedRequest>> mine() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.myWanted);
    return [
      for (final item
          in (response.data?['items'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        wantedFromJson(item),
    ];
  });

  @override
  Future<WantedRequest> update(String id, NewWanted request) =>
      _guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          ApiPaths.wantedById(id),
          data: request.toJson(),
        );
        return wantedFromJson(response.data ?? const {});
      });

  @override
  Future<WantedRequest> close(String id) => _status(id, 'close');

  @override
  Future<WantedRequest> cancel(String id) => _status(id, 'cancel');

  Future<WantedRequest> _status(String id, String action) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.wantedAction(id, action),
    );
    return wantedFromJson(response.data ?? const {});
  });

  @override
  Future<WantedOffer?> myOffer(String requestId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.myOffer(requestId),
      );
      return offerFromJson(response.data ?? const {}, _apiBaseUrl);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      // Aun no ofrezco: la hoja empieza vacia.
      if (failure.code == 'offers.not_found') return null;
      throw failure;
    }
  }

  @override
  Future<WantedOffer> sendOffer(String requestId, NewOffer offer) =>
      _guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          ApiPaths.myOffer(requestId),
          data: offer.toJson(),
        );
        return offerFromJson(response.data ?? const {}, _apiBaseUrl);
      });

  @override
  Future<List<ReceivedOffer>> receivedOffers(String requestId) =>
      _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiPaths.receivedOffers(requestId),
        );
        return [
          for (final item
              in (response.data?['items'] as List<dynamic>? ?? const [])
                  .cast<Map<String, dynamic>>())
            receivedOfferFromJson(item, _apiBaseUrl),
        ];
      });

  @override
  Future<void> rejectOffer(String requestId, String offerId) => _guard(
    () => _dio.post<void>(ApiPaths.offerAction(requestId, offerId, 'reject')),
  );

  @override
  Future<String> acceptOffer(String requestId, String offerId) =>
      _conversation(ApiPaths.offerAction(requestId, offerId, 'accept'));

  @override
  Future<String> offerChat(String requestId, String offerId) =>
      _conversation(ApiPaths.offerAction(requestId, offerId, 'chat'));

  Future<String> _conversation(String path) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(path);
    return response.data!['conversationId'] as String;
  });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}

/// Un `WantedResponse` de la API. [apiBaseUrl] resuelve la foto de quien
/// busca (`/media/avatars/...`, solo en el tablero con sesion).
WantedRequest wantedFromJson(Map<String, dynamic> json, {Uri? apiBaseUrl}) {
  final category = json['category'] as Map<String, dynamic>? ?? const {};
  final requester = json['requester'] as Map<String, dynamic>? ?? const {};
  final neededBy = json['neededBy'] as String?;
  final photo = requester['photo'] as String?;
  return WantedRequest(
    id: json['id'] as String,
    title: json['title'] as String,
    categorySlug: category['slug'] as String? ?? 'otro',
    categoryName: category['name'] as String? ?? 'Otro',
    description: json['description'] as String?,
    features: [
      for (final f in json['features'] as List<dynamic>? ?? const [])
        f as String,
    ],
    budgetCents: (json['budgetCents'] as num).toInt(),
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    // "2026-11-13": un dia del campus, sin zona.
    neededBy: neededBy == null ? null : DateTime.parse(neededBy),
    status: WantedStatus.parse(json['status']),
    offersCount: (json['offersCount'] as num?)?.toInt() ?? 0,
    requesterName: requester['name'] as String? ?? '',
    requesterId: requester['id'] as String?,
    requesterPhotoUrl: photo == null || apiBaseUrl == null
        ? null
        : mediaUrl(photo, apiBaseUrl),
    requesterCareer: requester['career'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
  );
}

/// Un `OfferResponse` de la API.
WantedOffer offerFromJson(Map<String, dynamic> json, Uri apiBaseUrl) {
  final photo = json['photo'] as String?;
  return WantedOffer(
    id: json['id'] as String,
    requestId: json['requestId'] as String,
    kind: OfferKind.parse(json['kind']),
    productId: json['productId'] as String?,
    title: json['title'] as String,
    priceCents: (json['priceCents'] as num).toInt(),
    condition: json['condition'] as String? ?? 'used',
    photoUrl: photo == null ? null : mediaUrl(photo, apiBaseUrl),
    // La ruta es `/media/...`; la llave, sin la diagonal.
    photoKey: photo != null && photo.startsWith('/')
        ? photo.substring(1)
        : photo,
    message: json['message'] as String?,
    overBudget: json['overBudget'] as bool? ?? false,
    status: OfferStatus.parse(json['status']),
  );
}

/// Un `ReceivedOfferResponse` de la API (HU-17).
ReceivedOffer receivedOfferFromJson(Map<String, dynamic> json, Uri apiBaseUrl) {
  final photo = json['photo'] as String?;
  final offerer = json['offerer'] as Map<String, dynamic>? ?? const {};
  final avatar = offerer['photo'] as String?;
  return ReceivedOffer(
    id: json['id'] as String,
    kind: OfferKind.parse(json['kind']),
    productId: json['productId'] as String?,
    title: json['title'] as String,
    priceCents: (json['priceCents'] as num).toInt(),
    condition: json['condition'] as String? ?? 'used',
    conditionDetail: json['conditionDetail'] as String?,
    photoUrl: photo == null ? null : mediaUrl(photo, apiBaseUrl),
    message: json['message'] as String?,
    status: OfferStatus.parse(json['status']),
    offerer: Offerer(
      id: offerer['id'] as String? ?? '',
      name: offerer['name'] as String? ?? '',
      photoUrl: avatar == null ? null : mediaUrl(avatar, apiBaseUrl),
      career: offerer['career'] as String?,
      ratingAvg: (offerer['ratingAvg'] as num?)?.toDouble(),
      ratingCount: (offerer['ratingCount'] as num?)?.toInt() ?? 0,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
  );
}
