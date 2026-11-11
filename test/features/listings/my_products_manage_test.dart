import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 10, 12);

OwnListing _listing({
  String id = 'calc',
  String title = 'Calculadora Casio fx-991ES Plus',
  int priceCents = 45000,
  int stock = 1,
  ListingStatus status = ListingStatus.active,
}) => OwnListing(
  product: ProductSummary(
    id: id,
    title: title,
    priceCents: priceCents,
    stock: stock,
    category: 'calculadoras',
    condition: 'Usado',
    publishedAt: _now,
  ),
  status: status,
  description: 'La usé un semestre.',
  usedDetail: UsedDetail.good,
);

/// App con sesion y `Mis-productos` abierto, con el fake de publicaciones.
class _Harness {
  new(this.tester);

  final WidgetTester tester;
  final listings = FakeListingsRepository();
  late ProviderContainer container;

  Future<void> open() async {
    final tokens = SessionTokens(
      accessToken: 'access',
      accessExpiresAt: _now.add(const Duration(minutes: 15)),
      refreshToken: 'refresh',
      profile: const SessionProfile(
        fullName: 'Ana Sofía Ramírez',
        email: 'ana.ramirez@uttt.edu.mx',
        campus: 'UTTT',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([sampleFeed]),
          ),
          listingsRepositoryProvider.overrideWithValue(listings),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(tokens)),
          initialSessionTokensProvider.overrideWithValue(tokens),
        ],
        child: const MusubiApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    final context = tester.element(find.byType(Scaffold).first);
    // Perfil → "Mis productos" (el camino de la app no se prueba aqui).
    // ignore: unawaited_futures, la pantalla se espera con pumpAndSettle.
    GoRouter.of(context).push(AppRoutes.myProducts);
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(String text) => tap(find.text(text).last);

  Future<void> tapKey(String key) => tap(find.byKey(Key(key)));

  /// Abre el menu de una publicacion y elige una opcion.
  Future<void> manage(String id, String option) async {
    await tapKey('my-product-$id');
    expect(find.byKey(const Key('my-product-manage')), findsOneWidget);
    await tapText(option);
    // Como el resto de las hojas: el siguiente paso abre 240 ms despues.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }
}

// HU-07: el menu de `Mis-productos` (Ver, Editar, Pausar/Reactivar, Eliminar)
// y "Editar publicación" con `Vender-2…4`.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  testWidgets('el menu tiene las opciones de la maqueta y Pausar', (
    tester,
  ) async {
    final h = _Harness(tester)..listings.own = [_listing()];
    await h.open();

    await h.tapKey('my-product-calc');

    expect(find.text('Ver publicación'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Pausar publicación'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('editar: Vender-2…4 con sus datos y Guardar cambios', (
    tester,
  ) async {
    final h = _Harness(tester)..listings.own = [_listing()];
    await h.open();

    await h.manage('calc', 'Editar');

    // Vender-2 con el titulo de la maqueta y los datos de la publicacion.
    expect(find.text('Editar publicación'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'Calculadora Casio fx-991ES Plus',
    );
    await tester.enterText(
      find.byKey(const Key('sell-title')),
      'Calculadora Casio fx-570',
    );
    await h.tapText('Continuar');
    // Vender-3: el precio ya viene escrito.
    expect(find.text('450'), findsOneWidget);
    await h.tapText('Continuar');
    // Vender-4: las piezas se ven, pero no se cambian (Reponer es de HU-50).
    expect(find.byKey(const Key('sell-quantity-locked')), findsOneWidget);
    await h.tapKey('sell-quantity-1');
    expect(h.container.read(sellEditDraftProvider).quantity, 1);

    await h.tapKey('sell-save-edit');

    expect(h.listings.updates['calc']?.title, 'Calculadora Casio fx-570');
    expect(h.listings.updates['calc']?.priceCents, 45000);
    expect(h.listings.updates['calc']?.usedDetail, UsedDetail.good);
    // De vuelta en Mis productos, con el aviso de la maqueta.
    expect(find.text('Mis productos'), findsOneWidget);
    expect(
      find.text('Guardamos los cambios de tu publicación'),
      findsOneWidget,
    );
    expect(find.text('Calculadora Casio fx-570'), findsOneWidget);
    // El borrador de venta no se toco.
    expect(h.container.read(sellDraftProvider).title, isEmpty);
  });

  testWidgets('editar: la X vuelve a Mis productos sin guardar', (
    tester,
  ) async {
    final h = _Harness(tester)..listings.own = [_listing()];
    await h.open();
    await h.manage('calc', 'Editar');
    await h.tapText('Continuar');

    await h.tap(find.bySemanticsLabel('Cerrar').first);

    expect(find.text('Mis productos'), findsOneWidget);
    expect(h.listings.updates, isEmpty);
  });

  testWidgets('pausar y reactivar: sigue en Activos con su marca', (
    tester,
  ) async {
    final h = _Harness(tester)..listings.own = [_listing()];
    await h.open();

    await h.manage('calc', 'Pausar publicación');

    expect(
      find.text('Pausaste la publicación. Ya no se ve en Musubi.'),
      findsOneWidget,
    );
    expect(find.text('Activos (1)'), findsOneWidget);
    expect(find.text(r'$450 · Pausada · Último'), findsOneWidget);

    await h.manage('calc', 'Reactivar');

    expect(find.text(r'$450 · Último'), findsOneWidget);
    expect(h.listings.own.single.status, ListingStatus.active);
  });

  testWidgets('eliminar: confirma con el texto de la maqueta', (tester) async {
    final h = _Harness(tester)
      ..listings.own = [_listing(), _listing(id: 'libro', title: 'Libro')];
    await h.open();

    await h.manage('calc', 'Eliminar');

    expect(find.text('¿Eliminar la publicación?'), findsOneWidget);
    expect(
      find.text('Ya no aparecerá en Musubi. Esta acción no se puede deshacer.'),
      findsOneWidget,
    );
    await h.tapKey('my-product-delete-confirm');

    expect(h.listings.deleted, ['calc']);
    expect(find.text('Eliminaste la publicación'), findsOneWidget);
    expect(find.text('Activos (1)'), findsOneWidget);
    expect(find.byKey(const Key('my-product-calc')), findsNothing);
  });

  testWidgets('eliminar con pedidos abiertos muestra el mensaje de la API', (
    tester,
  ) async {
    final h = _Harness(tester)..listings.own = [_listing()];
    await h.open();
    h.listings.nextFailure = const ApiFailure(
      code: 'listings.product_has_orders',
      message:
          'Tiene pedidos pendientes o confirmados. Termínalos o cancélalos '
          'antes de eliminarla.',
      status: 409,
    );

    await h.manage('calc', 'Eliminar');
    await h.tapKey('my-product-delete-confirm');

    expect(find.textContaining('Termínalos o cancélalos'), findsOneWidget);
    expect(h.listings.deleted, isEmpty);
    expect(find.byKey(const Key('my-product-calc')), findsOneWidget);
  });

  testWidgets('cancelar el dialogo no elimina', (tester) async {
    final h = _Harness(tester)..listings.own = [_listing()];
    await h.open();

    await h.manage('calc', 'Eliminar');
    await h.tapText('Cancelar');

    expect(h.listings.deleted, isEmpty);
  });
}
