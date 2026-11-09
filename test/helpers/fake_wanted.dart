import 'package:musubi_app/core/errors/api_failure.dart';
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

/// Solicitudes en memoria: guarda lo que se publica.
class FakeWantedRepository implements WantedRepository {
  new({List<WantedRequest>? mine, this.publishFailure}) : stored = mine ?? [];

  final List<WantedRequest> stored;
  ApiFailure? publishFailure;
  final List<NewWanted> published = [];

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
