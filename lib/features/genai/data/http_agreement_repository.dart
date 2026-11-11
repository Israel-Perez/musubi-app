import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/genai/domain/agreement_models.dart';
import 'package:musubi_app/features/genai/domain/agreement_repository.dart';

/// La IA tarda hasta 20 s en el servidor: "Resumir acuerdo" espera mas que el
/// resto de las peticiones (RNF-12, la hoja muestra que esta leyendo).
const agreementReceiveTimeout = Duration(seconds: 30);

/// [AgreementRepository] sobre las filas "M-10" de
/// `musubi-api/docs/endpoints.md` (specs `musubi-api:HU-32`, `HU-33` y
/// `HU-34`). Siempre con sesion.
class HttpAgreementRepository implements AgreementRepository {
  new(this._dio);

  final Dio _dio;

  @override
  Future<Agreement> request(String conversationId) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.agreements,
      data: {'conversationId': conversationId},
      options: Options(receiveTimeout: agreementReceiveTimeout),
    );
    return agreementFromJson(response.data ?? const {});
  });

  @override
  Future<Agreement?> byConversation(String conversationId) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.agreements,
      queryParameters: {'conversationId': conversationId},
    );
    final items = (response.data?['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return items.isEmpty ? null : agreementFromJson(items.first);
  });

  @override
  Future<Agreement> update(Agreement agreement, AgreementEdit edit) =>
      _guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          ApiPaths.agreement(agreement.id),
          data: edit.toJson(agreement.revision),
        );
        return agreementFromJson(response.data ?? const {});
      });

  @override
  Future<Agreement> confirm(Agreement agreement) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.agreementConfirm(agreement.id),
      data: {'revision': agreement.revision},
    );
    return agreementFromJson(response.data ?? const {});
  });

  @override
  Future<void> discard(String id) =>
      _guard(() => _dio.delete<void>(ApiPaths.agreement(id)));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } on FormatException {
      throw AgreementFormat.failure;
    }
  }
}

/// La respuesta no trae la forma del acuerdo (HU-33 R4): no se muestra.
abstract final class AgreementFormat {
  static const failure = ApiFailure(
    code: 'agreements.invalid_response',
    message: 'No pudimos leer la propuesta. Inténtalo de nuevo.',
  );
}

/// Los campos de la propuesta que siempre trae la API (HU-33 R4).
const _proposalFields = [
  'title',
  'priceCents',
  'quantity',
  'meetingPoint',
  'pointName',
  'meetingDetail',
  'deliveryAt',
  'conditions',
];

/// Un `AgreementResponse` (fixture `agreement.json`). Valida que la propuesta
/// tenga siempre los mismos campos, cada uno de su tipo o `null`; si no,
/// [FormatException] y la hoja no la muestra.
Agreement agreementFromJson(Map<String, dynamic> json) {
  final proposal = json['proposal'];
  if (proposal is! Map<String, dynamic> ||
      _proposalFields.any((f) => !proposal.containsKey(f)) ||
      proposal['title'] is! String ||
      (proposal['priceCents'] != null && proposal['priceCents'] is! int) ||
      (proposal['quantity'] != null && proposal['quantity'] is! int) ||
      json['id'] is! String ||
      json['revision'] is! int) {
    throw const FormatException('AgreementResponse sin la forma esperada');
  }

  T? opt<T>(String key) => proposal[key] is T ? proposal[key] as T : null;
  DateTime? date(Object? value) =>
      value is String ? DateTime.parse(value).toUtc() : null;
  Map<String, dynamic> party(String key) =>
      json[key] as Map<String, dynamic>? ?? const {};

  return Agreement(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String? ?? '',
    revision: json['revision'] as int,
    status: AgreementStatus.parse(json['status'] as String?),
    isBuyer: json['role'] == 'buyer',
    requestedByBuyer: json['requestedBy'] == 'buyer',
    buyerName: party('buyer')['name'] as String? ?? '',
    sellerName: party('seller')['name'] as String? ?? '',
    proposal: AgreementProposal(
      title: proposal['title'] as String,
      priceCents: opt<int>('priceCents'),
      quantity: opt<int>('quantity'),
      meetingPoint: opt<String>('meetingPoint'),
      pointName: opt<String>('pointName'),
      detail: opt<String>('meetingDetail'),
      deliveryAt: date(proposal['deliveryAt']),
      conditions: opt<String>('conditions'),
    ),
    notIdentified: {
      for (final f in json['notIdentified'] as List<dynamic>? ?? const [])
        if (f is String) f,
    },
    missing: [
      for (final f in json['missing'] as List<dynamic>? ?? const [])
        if (f is String) f,
    ],
    maxQuantity: json['maxQuantity'] as int? ?? 1,
    buyerConfirmedAt: date(json['buyerConfirmedAt']),
    sellerConfirmedAt: date(json['sellerConfirmedAt']),
    updatedAt: date(json['updatedAt']),
  );
}
