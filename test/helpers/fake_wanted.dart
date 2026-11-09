import 'package:musubi_app/core/errors/api_failure.dart';
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
  }) : stored = mine ?? [],
       boardItems = board ?? [];

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
}
