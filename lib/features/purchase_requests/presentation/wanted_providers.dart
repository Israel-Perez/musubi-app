import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/purchase_requests/data/http_wanted_repository.dart';
import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_repository.dart';

/// Solicitudes de compra (HU-13) y el tablero (HU-15). En pruebas, un fake.
final wantedRepositoryProvider = Provider<WantedRepository>(
  (ref) => HttpWantedRepository(
    ref.watch(dioProvider),
    ref.watch(appConfigProvider).apiBaseUrl,
  ),
);

/// "Mis solicitudes". Se vuelve a pedir al abrir la pantalla.
final FutureProvider<List<WantedRequest>> myWantedProvider =
    FutureProvider.autoDispose<List<WantedRequest>>(
      (ref) => ref.watch(wantedRepositoryProvider).mine(),
      retry: (_, _) => null,
    );

/// "Compara las ofertas" (HU-17) de una solicitud. Para recargar:
/// `ref.invalidate(receivedOffersProvider(id))`.
final FutureProviderFamily<List<ReceivedOffer>, String> receivedOffersProvider =
    FutureProvider.autoDispose.family<List<ReceivedOffer>, String>(
      (ref, requestId) =>
          ref.watch(wantedRepositoryProvider).receivedOffers(requestId),
      retry: (_, _) => null,
    );

/// Producto de "Otro" en `Necesidad-1`: no es una categoria de publicaciones.
const otherCategory = CatalogCategory(slug: 'otro', name: 'Otro');

/// "¿Para cuando la necesitas?" (`Necesidad-3`).
enum NeedWhen {
  /// Sin fecha: vence a los 30 dias (RN-10).
  none,

  /// "Esta semana": hasta el domingo.
  thisWeek,

  /// El proximo viernes ("Vie 9 oct").
  friday,

  /// "Elegir fecha".
  custom,
}

/// El domingo de esta semana (hoy si es domingo).
DateTime endOfWeek(DateTime today) =>
    _day(today).add(Duration(days: DateTime.sunday - today.weekday));

/// El proximo viernes (hoy si es viernes).
DateTime nextFriday(DateTime today) =>
    _day(today).add(Duration(days: (DateTime.friday - today.weekday + 7) % 7));

/// "Elegir fecha" (`NEED_DATES` de la maqueta): lunes, miércoles y viernes
/// de la semana que entra y el lunes siguiente.
List<DateTime> otherDates(DateTime today) {
  final monday = _day(today)
      .add(Duration(days: DateTime.daysPerWeek - today.weekday + 1));
  return [
    for (final days in [0, 2, 4, 7]) monday.add(Duration(days: days)),
  ];
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Borrador de "Publicar lo que necesito" (`Necesidad-1…3`) y de "Editar
/// solicitud" (HU-14, con [editingId]).
@immutable
class NeedDraft {
  const new({
    this.title = '',
    this.category,
    this.description = '',
    this.features = const [],
    this.budgetCents,
    this.quantity = 1,
    this.when = NeedWhen.none,
    this.customDate,
    this.editingId,
    this.productLocked = false,
  });

  /// "Editar solicitud" (HU-14): el borrador sale de la solicitud. Su fecha
  /// vuelve a la opcion rapida que la da ("Esta semana" o el viernes) o queda
  /// como "Elegir fecha".
  factory fromRequest(WantedRequest request, DateTime today) => NeedDraft(
    title: request.title,
    category: CatalogCategory(
      slug: request.categorySlug,
      name: request.categoryName,
    ),
    description: request.description ?? '',
    features: request.features,
    budgetCents: request.budgetCents,
    quantity: request.quantity,
    when: switch (request.neededBy) {
      null => NeedWhen.none,
      final day when day == nextFriday(today) => NeedWhen.friday,
      final day when day == endOfWeek(today) => NeedWhen.thisWeek,
      _ => NeedWhen.custom,
    },
    customDate: request.neededBy,
    editingId: request.id,
    productLocked: request.offersCount > 0,
  );

  final String title;
  final CatalogCategory? category;
  final String description;
  final List<String> features;
  final int? budgetCents;
  final int quantity;
  final NeedWhen when;
  final DateTime? customDate;

  /// La solicitud que se edita (HU-14), o `null` al publicar.
  final String? editingId;

  /// Con ofertas, el producto y la categoria ya no cambian (HU-14).
  final bool productLocked;

  bool get editing => editingId != null;

  /// Largo minimo del producto (como la API).
  static const minTitle = 3;

  /// Largo maximo del producto.
  static const maxTitle = 80;

  /// Largo maximo de la descripcion ("0 / 300").
  static const maxDescription = 300;

  /// Caracteristicas como maximo.
  static const maxFeatures = 5;

  /// Largo maximo de una caracteristica.
  static const maxFeature = 40;

  /// Piezas como maximo.
  static const maxQuantity = 10;

  /// Presupuesto maximo: $999,999.
  static const maxBudgetCents = 99999900;

  bool get titleValid => title.trim().length >= minTitle;

  /// El dia elegido, o `null` sin fecha.
  DateTime? neededBy(DateTime today) => switch (when) {
    NeedWhen.none => null,
    NeedWhen.thisWeek => endOfWeek(today),
    NeedWhen.friday => nextFriday(today),
    NeedWhen.custom => customDate,
  };

  NeedDraft copyWith({
    String? title,
    CatalogCategory? category,
    String? description,
    List<String>? features,
    int? budgetCents,
    bool clearBudget = false,
    int? quantity,
    NeedWhen? when,
    DateTime? customDate,
  }) => NeedDraft(
    title: title ?? this.title,
    category: category ?? this.category,
    description: description ?? this.description,
    features: features ?? this.features,
    budgetCents: clearBudget ? null : budgetCents ?? this.budgetCents,
    quantity: quantity ?? this.quantity,
    when: when ?? this.when,
    customDate: customDate ?? this.customDate,
    editingId: editingId,
    productLocked: productLocked,
  );

  /// Lo que se publica.
  NewWanted toRequest(DateTime today) => NewWanted(
    title: title,
    category: category!.slug,
    description: description,
    features: features,
    budgetCents: budgetCents!,
    quantity: quantity,
    neededBy: neededBy(today),
  );
}

/// El borrador vive mientras la app esta abierta ("Guardar" lo conserva al
/// cerrar el flujo).
class NeedDraftNotifier extends Notifier<NeedDraft> {
  @override
  NeedDraft build() => const NeedDraft();

  void setTitle(String value) => state = state.copyWith(title: value);

  void setCategory(CatalogCategory value) =>
      state = state.copyWith(category: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  /// Agrega una caracteristica (sin repetir ni pasar del maximo).
  bool addFeature(String value) {
    final feature = value.trim();
    if (feature.isEmpty ||
        state.features.length >= NeedDraft.maxFeatures ||
        state.features.contains(feature)) {
      return false;
    }
    state = state.copyWith(features: [...state.features, feature]);
    return true;
  }

  void removeFeature(String value) => state = state.copyWith(
    features: [...state.features.where((f) => f != value)],
  );

  void setBudget(int? cents) => state = cents == null
      ? state.copyWith(clearBudget: true)
      : state.copyWith(budgetCents: cents);

  void step(int delta) => state = state.copyWith(
    quantity: (state.quantity + delta).clamp(1, NeedDraft.maxQuantity),
  );

  /// Elige cuando; tocar la opcion elegida la quita (sin fecha).
  void setWhen(NeedWhen value, {DateTime? date}) => state = NeedDraft(
    title: state.title,
    category: state.category,
    description: state.description,
    features: state.features,
    budgetCents: state.budgetCents,
    quantity: state.quantity,
    when: state.when == value && value != NeedWhen.custom
        ? NeedWhen.none
        : value,
    customDate: value == NeedWhen.custom ? date : state.customDate,
    editingId: state.editingId,
    productLocked: state.productLocked,
  );

  void reset() => state = const NeedDraft();

  /// "Editar solicitud" (HU-14): empieza con los datos de la solicitud.
  void load(WantedRequest request, DateTime today) =>
      state = NeedDraft.fromRequest(request, today);
}

final NotifierProvider<NeedDraftNotifier, NeedDraft> needDraftProvider =
    NotifierProvider<NeedDraftNotifier, NeedDraft>(NeedDraftNotifier.new);

/// "Editar solicitud" (HU-14): otro borrador, para no pisar el de "Publicar
/// lo que necesito" que se guardo a medias.
final NotifierProvider<NeedDraftNotifier, NeedDraft> needEditDraftProvider =
    NotifierProvider<NeedDraftNotifier, NeedDraft>(NeedDraftNotifier.new);

/// El borrador de cada flujo: publicar o editar (HU-14).
NotifierProvider<NeedDraftNotifier, NeedDraft> needDraftFor({
  required bool editing,
}) => editing ? needEditDraftProvider : needDraftProvider;

/// Publicaciones del campus que coinciden con lo que se busca (busqueda
/// HU-09), dentro del presupuesto primero. Sin coincidencias, vacio.
final FutureProviderFamily<List<ProductSummary>, String> needMatchesProvider =
    FutureProvider.autoDispose.family<List<ProductSummary>, String>((
      ref,
      title,
    ) async {
      final query = title.trim();
      if (query.length < NeedDraft.minTitle) return const [];
      final page = await ref
          .watch(catalogRepositoryProvider)
          .search(query: query);
      return page.items;
    }, retry: (_, _) => null);

/// Hoy (para las fechas rapidas de `Necesidad-3`).
DateTime todayFrom(Ref ref) => ref.read(clockProvider)().toLocal();
