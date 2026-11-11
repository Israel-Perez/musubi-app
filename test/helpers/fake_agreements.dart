import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/genai/domain/agreement_models.dart';
import 'package:musubi_app/features/genai/domain/agreement_repository.dart';
import 'package:musubi_app/features/genai/presentation/agreement_providers.dart';

/// `genai.unavailable`: la IA no respondio (RNF-15).
const aiUnavailable = ApiFailure(
  code: 'genai.unavailable',
  message:
      'La IA no está disponible ahora. Llena el resumen a mano o inténtalo '
      'más tarde.',
  status: 503,
);

/// La propuesta de la calculadora en la conversacion `c1`: Ana compra a
/// Valeria; sin fecha ("No identificado") salvo que se pase [deliveryAt].
Agreement sampleAgreement({
  String id = 'a1',
  bool isBuyer = true,
  int revision = 1,
  AgreementStatus status = AgreementStatus.proposed,
  DateTime? deliveryAt,
  DateTime? buyerConfirmedAt,
  DateTime? sellerConfirmedAt,
  int maxQuantity = 1,
  int? priceCents = 40000,
  String? conditions,
}) => Agreement(
  id: id,
  conversationId: 'c1',
  revision: revision,
  status: status,
  isBuyer: isBuyer,
  requestedByBuyer: true,
  buyerName: 'Ana Sofía Ramírez',
  sellerName: 'Valeria Cruz',
  proposal: AgreementProposal(
    title: 'Calculadora Casio fx-991ES Plus',
    priceCents: priceCents,
    quantity: 1,
    meetingPoint: 'biblioteca',
    pointName: 'Biblioteca',
    detail: 'Planta baja',
    deliveryAt: deliveryAt,
    conditions: conditions,
  ),
  maxQuantity: maxQuantity,
  notIdentified: {
    AgreementField.deliveryAt,
    if (priceCents == null) AgreementField.price,
  },
  missing: [
    if (priceCents == null) AgreementField.price,
    if (deliveryAt == null) AgreementField.deliveryAt,
  ],
  buyerConfirmedAt: buyerConfirmedAt,
  sellerConfirmedAt: sellerConfirmedAt,
  updatedAt: DateTime.utc(2026, 11, 6, 21, 2),
);

/// Repositorio del acuerdo en memoria: guarda lo que se le pide.
class FakeAgreementRepository implements AgreementRepository {
  new({this.current, this.proposal});

  /// El acuerdo vigente de `c1`.
  Agreement? current;

  /// Lo que "propone la IA" al pedir el resumen.
  Agreement? proposal;
  ApiFailure? requestFailure;
  ApiFailure? updateFailure;
  ApiFailure? confirmFailure;

  final List<String> requested = [];
  final List<AgreementEdit> edits = [];
  final List<int> confirmed = [];
  final List<String> discarded = [];

  @override
  Future<Agreement> request(String conversationId) async {
    requested.add(conversationId);
    if (requestFailure != null) throw requestFailure!;
    return current = proposal ?? sampleAgreement();
  }

  @override
  Future<Agreement?> byConversation(String conversationId) async =>
      conversationId == 'c1' ? current : null;

  @override
  Future<Agreement> update(Agreement agreement, AgreementEdit edit) async {
    edits.add(edit);
    if (updateFailure != null) throw updateFailure!;
    final p = agreement.proposal;
    final at = edit.deliveryAt?.toUtc() ?? p.deliveryAt;
    final price = edit.priceCents ?? p.priceCents;
    return current = Agreement(
      id: agreement.id,
      conversationId: agreement.conversationId,
      revision: agreement.revision + 1,
      status: AgreementStatus.proposed,
      isBuyer: agreement.isBuyer,
      requestedByBuyer: agreement.requestedByBuyer,
      buyerName: agreement.buyerName,
      sellerName: agreement.sellerName,
      proposal: AgreementProposal(
        title: edit.title ?? p.title,
        priceCents: price,
        quantity: edit.quantity ?? p.quantity,
        meetingPoint: edit.meetingPoint ?? p.meetingPoint,
        pointName: edit.meetingPoint == null ? p.pointName : 'Cafetería',
        detail: edit.detail ?? p.detail,
        deliveryAt: at,
        conditions: edit.conditions ?? p.conditions,
      ),
      maxQuantity: agreement.maxQuantity,
      notIdentified: agreement.notIdentified,
      missing: [
        if (price == null) AgreementField.price,
        if (at == null) AgreementField.deliveryAt,
      ],
      updatedAt: agreement.updatedAt,
    );
  }

  @override
  Future<Agreement> confirm(Agreement agreement) async {
    confirmed.add(agreement.revision);
    if (confirmFailure != null) throw confirmFailure!;
    final now = DateTime.utc(2026, 11, 6, 21, 2);
    final buyer = agreement.isBuyer ? now : agreement.buyerConfirmedAt;
    final seller = agreement.isBuyer ? agreement.sellerConfirmedAt : now;
    return current = Agreement(
      id: agreement.id,
      conversationId: agreement.conversationId,
      revision: agreement.revision,
      status: buyer != null && seller != null
          ? AgreementStatus.confirmed
          : AgreementStatus.proposed,
      isBuyer: agreement.isBuyer,
      requestedByBuyer: agreement.requestedByBuyer,
      buyerName: agreement.buyerName,
      sellerName: agreement.sellerName,
      proposal: agreement.proposal,
      maxQuantity: agreement.maxQuantity,
      notIdentified: agreement.notIdentified,
      missing: agreement.missing,
      buyerConfirmedAt: buyer,
      sellerConfirmedAt: seller,
      updatedAt: now,
    );
  }

  @override
  Future<void> discard(String id) async {
    discarded.add(id);
    current = null;
  }
}

/// El aviso de la IA en memoria.
class FakeAiNoticeStore implements AiNoticeStore {
  new({this.wasSeen = false});

  bool wasSeen;

  @override
  Future<bool> seen() async => wasSeen;

  @override
  Future<void> markSeen() async => wasSeen = true;
}
