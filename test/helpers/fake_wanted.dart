import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_board.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_repository.dart';

/// Una solicitud de ejemplo (maqueta `Mis-solicitudes`).
WantedRequest sampleWanted({
  String id = 'w1',
  String title = 'Calculadora Casio fx-991ES Plus',
  WantedStatus status = WantedStatus.active,
  int offers = 0,
  DateTime? neededBy,
}) => WantedRequest(
  id: id,
  title: title,
  categorySlug: 'calculadoras',
  categoryName: 'Calculadoras',
  budgetCents: 60000,
  quantity: 1,
  status: status,
  requesterName: 'Ana R.',
  createdAt: DateTime.utc(2026, 11, 9, 12),
  neededBy: neededBy,
  offersCount: offers,
);

/// Una solicitud del tablero (maqueta `Se-busca`, `REQUESTS`).
WantedRequest boardWanted({
  String id = 'r-bata',
  String title = 'Bata de laboratorio talla M, manga larga',
  String category = 'laboratorio',
  String categoryName = 'Laboratorio',
  int budgetCents = 30000,
  DateTime? neededBy,
  String requester = 'Fernanda Ortiz',
  String? requesterId = 'u-fernanda',
  String? career = 'QFB',
  int offers = 0,
  DateTime? createdAt,
}) => WantedRequest(
  id: id,
  title: title,
  categorySlug: category,
  categoryName: categoryName,
  budgetCents: budgetCents,
  quantity: 1,
  status: WantedStatus.active,
  requesterName: requester,
  requesterId: requesterId,
  requesterCareer: career,
  createdAt: createdAt ?? DateTime.utc(2026, 11, 9, 11, 40),
  neededBy: neededBy,
  offersCount: offers,
);

/// Solicitudes en memoria: guarda lo que se publica y sirve el tablero
/// ([board]) con los filtros de la hoja, como la API.
class FakeWantedRepository implements WantedRepository {
  new({
    List<WantedRequest>? mine,
    List<WantedRequest>? board,
    this.publishFailure,
    this.boardFailure,
    this.pageSize,
    Map<String, List<ReceivedOffer>>? received,
  }) : stored = mine ?? [],
       boardItems = board ?? [],
       received = received ?? {};

  final List<WantedRequest> stored;
  final List<WantedRequest> boardItems;
  ApiFailure? publishFailure;
  ApiFailure? boardFailure;

  /// Tamano de pagina forzado (para probar "cargar más").
  final int? pageSize;

  final List<NewWanted> published = [];

  /// Filtros y cursores con que se pidio el tablero.
  final List<(WantedBoardFilter, String?)> boardCalls = [];

  @override
  Future<WantedPage> board({
    WantedBoardFilter filter = const WantedBoardFilter(),
    String? cursor,
    int? limit,
  }) async {
    boardCalls.add((filter, cursor));
    if (boardFailure != null) throw boardFailure!;
    final slugs = {for (final c in filter.categories) c.slug};
    final q = filter.query.trim().toLowerCase();
    final matches = [
      for (final r in boardItems)
        if ((slugs.isEmpty || slugs.contains(r.categorySlug)) &&
            (filter.budget.min == null ||
                r.budgetCents >= filter.budget.min!) &&
            (filter.budget.max == null ||
                r.budgetCents <= filter.budget.max!) &&
            (q.isEmpty || r.title.toLowerCase().contains(q)))
          r,
    ];
    final start = cursor == null
        ? 0
        : matches.indexWhere((r) => r.id == cursor) + 1;
    final size = pageSize ?? limit ?? 20;
    final items = matches.skip(start).take(size).toList();
    return WantedPage(
      items: items,
      nextCursor: start + size < matches.length ? items.last.id : null,
    );
  }

  @override
  Future<WantedRequest> publish(NewWanted request) async {
    if (publishFailure != null) throw publishFailure!;
    published.add(request);
    final created = WantedRequest(
      id: 'w${100 + published.length}',
      title: request.title.trim(),
      categorySlug: request.category,
      categoryName: request.category == 'otro' ? 'Otro' : 'Calculadoras',
      description: request.description,
      features: request.features,
      budgetCents: request.budgetCents,
      quantity: request.quantity,
      neededBy: request.neededBy,
      status: WantedStatus.active,
      requesterName: 'Ana R.',
      createdAt: DateTime.utc(2026, 11, 9, 12),
    );
    stored.insert(0, created);
    return created;
  }

  @override
  Future<List<WantedRequest>> mine() async => List.of(stored);

  /// Lo que se mando con "Guardar cambios" (HU-14): `(id, datos)`.
  final List<(String, NewWanted)> updates = [];

  /// `(accion, id)` de "Ya lo consegui" y "Cancelar solicitud".
  final List<(String, String)> statusChanges = [];
  ApiFailure? manageFailure;

  WantedRequest _replace(String id, WantedRequest Function(WantedRequest) f) {
    final i = stored.indexWhere((r) => r.id == id);
    final changed = f(stored[i]);
    stored[i] = changed;
    return changed;
  }

  @override
  Future<WantedRequest> update(String id, NewWanted request) async {
    if (manageFailure != null) throw manageFailure!;
    updates.add((id, request));
    return _replace(
      id,
      (r) => WantedRequest(
        id: r.id,
        title: request.title.trim(),
        categorySlug: request.category,
        categoryName: request.category == 'otro' ? 'Otro' : r.categoryName,
        description: request.description,
        features: request.features,
        budgetCents: request.budgetCents,
        quantity: request.quantity,
        neededBy: request.neededBy,
        status: r.status,
        offersCount: r.offersCount,
        requesterName: r.requesterName,
        createdAt: r.createdAt,
      ),
    );
  }

  @override
  Future<WantedRequest> close(String id) =>
      _status(id, 'close', WantedStatus.closed);

  @override
  Future<WantedRequest> cancel(String id) =>
      _status(id, 'cancel', WantedStatus.cancelled);

  Future<WantedRequest> _status(
    String id,
    String action,
    WantedStatus status,
  ) async {
    if (manageFailure != null) throw manageFailure!;
    statusChanges.add((action, id));
    return _replace(
      id,
      (r) => WantedRequest(
        id: r.id,
        title: r.title,
        categorySlug: r.categorySlug,
        categoryName: r.categoryName,
        description: r.description,
        features: r.features,
        budgetCents: r.budgetCents,
        quantity: r.quantity,
        neededBy: r.neededBy,
        status: status,
        offersCount: r.offersCount,
        requesterName: r.requesterName,
        createdAt: r.createdAt,
      ),
    );
  }

  /// Mis ofertas por solicitud (HU-16).
  final Map<String, WantedOffer> offers = {};

  /// Lo que se envio con "Enviar oferta".
  final List<(String, NewOffer)> sentOffers = [];
  ApiFailure? offerFailure;

  @override
  Future<WantedOffer?> myOffer(String requestId) async => offers[requestId];

  /// Ofertas recibidas por solicitud (HU-17).
  final Map<String, List<ReceivedOffer>> received;

  /// Lo que se decidio: `(accion, solicitud, oferta)`.
  final List<(String, String, String)> decisions = [];
  ApiFailure? decisionFailure;

  @override
  Future<List<ReceivedOffer>> receivedOffers(String requestId) async => [
    for (final o in received[requestId] ?? const <ReceivedOffer>[])
      if (!decisions.contains(('reject', requestId, o.id))) o,
  ];

  @override
  Future<void> rejectOffer(String requestId, String offerId) async {
    if (decisionFailure != null) throw decisionFailure!;
    decisions.add(('reject', requestId, offerId));
  }

  @override
  Future<String> acceptOffer(String requestId, String offerId) async {
    if (decisionFailure != null) throw decisionFailure!;
    decisions.add(('accept', requestId, offerId));
    return 'c-$offerId';
  }

  @override
  Future<String> offerChat(String requestId, String offerId) async {
    if (decisionFailure != null) throw decisionFailure!;
    decisions.add(('chat', requestId, offerId));
    return 'c-$offerId';
  }

  @override
  Future<WantedOffer> sendOffer(String requestId, NewOffer offer) async {
    if (offerFailure != null) throw offerFailure!;
    sentOffers.add((requestId, offer));
    final budget = [
      ...boardItems,
      ...stored,
    ].firstWhere((r) => r.id == requestId).budgetCents;
    final price = offer.priceCents ?? 25000;
    return offers[requestId] = WantedOffer(
      id: 'o-$requestId',
      requestId: requestId,
      kind: offer.productId == null ? OfferKind.direct : OfferKind.listing,
      productId: offer.productId,
      title: offer.description ?? 'Bata de laboratorio blanca, talla M',
      priceCents: price,
      condition: offer.condition ?? 'used',
      message: offer.message,
      overBudget: price > budget,
    );
  }
}
