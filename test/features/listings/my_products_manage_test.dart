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
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_orders.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 10, 12);

OwnListing _listing({
  String id = 'calc',
  String title = 'Calculadora Casio fx-991ES Plus',
  int priceCents = 45000,
  int stock = 1,
  ListingStatus status = ListingStatus.active,
  DateTime? soldAt,
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
  soldAt: soldAt,
);

/// Una venta completada de Valeria (HU-26), cerrada el 10 de noviembre.
Order _sale({
  String id = 's1',
  String title = 'Calculadora Casio fx-991ES Plus',
  int priceCents = 45000,
  int quantity = 1,
}) => sampleOrder(
  id: id,
  isBuyer: false,
  status: OrderStatus.completed,
  title: title,
  priceCents: priceCents,
  quantity: quantity,
  buyerConfirmed: true,
  sellerConfirmed: true,
  updatedAt: _now,
);

/// App con sesion y `Mis-productos` abierto, con los fakes de publicaciones y
/// de pedidos.
class _Harness {
  new(this.tester);

  final WidgetTester tester;
  final listings = FakeListingsRepository();
  final orders = FakeOrderRepository();
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
          orderRepositoryProvider.overrideWithValue(orders),
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
// y "Editar publicación" con `Vender-2…4`. HU-08: pestanas con los conteos de
// la API, "Marcar como vendido" y "Vendidos". HU-50: "Cambiar piezas" y
// "Reponer".
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

  testWidgets('las pestanas usan los conteos de la API', (tester) async {
    final h = _Harness(tester)
      ..listings.own = [
        _listing(),
        _listing(id: 'pausa', status: ListingStatus.hidden),
        _listing(id: 'agotada', stock: 0, status: ListingStatus.soldOut),
        _listing(id: 'vendida', status: ListingStatus.sold, soldAt: _now),
      ];
    await h.open();

    expect(find.text('Activos (2)'), findsOneWidget);
    expect(find.text('Vendidos (1)'), findsOneWidget);
    expect(find.text('Agotados (1)'), findsOneWidget);
    expect(find.byKey(const Key('my-product-vendida')), findsNothing);
  });

  testWidgets('marcar como vendido: dialogo de la maqueta y pasa a Vendidos', (
    tester,
  ) async {
    final h = _Harness(tester)..listings.own = [_listing()];
    await h.open();

    await h.manage('calc', 'Marcar como vendido');

    expect(find.text('¿Marcar como vendido?'), findsOneWidget);
    expect(
      find.text('Ya no aparecerá en las búsquedas y se moverá a tus ventas.'),
      findsOneWidget,
    );
    await h.tapKey('my-product-sold-confirm');

    expect(h.listings.soldIds, ['calc']);
    expect(find.text('¡Felicidades por tu venta!'), findsOneWidget);
    expect(find.text('Activos (0)'), findsOneWidget);
    expect(find.text('Vendidos (1)'), findsOneWidget);
  });

  testWidgets('Vendidos a mano: fecha y la marca; solo se ve o se elimina', (
    tester,
  ) async {
    final h = _Harness(tester)
      ..listings.own = [
        _listing(id: 'v1', status: ListingStatus.sold, soldAt: _now),
        _listing(
          id: 'v2',
          title: 'Libro de Cálculo',
          priceCents: 30000,
          status: ListingStatus.sold,
          soldAt: _now,
        ),
      ];
    await h.open();

    await h.tapText('Vendidos (2)');

    // Sin pedidos completados no hay tarjeta: no hay un monto real.
    expect(find.byKey(const Key('my-products-sales')), findsNothing);
    expect(find.text(r'$450 · 10 nov · Marcado a mano'), findsOneWidget);
    expect(find.text('Vendido'), findsNWidgets(2));

    await h.tapKey('my-product-v1');

    expect(find.text('Ver publicación'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Marcar como vendido'), findsNothing);
    expect(find.text('Pausar publicación'), findsNothing);
    expect(find.text('Cambiar piezas'), findsNothing);
  });

  // HU-26: el historial de ventas en "Vendidos".
  testWidgets('Vendidos: mis ventas con quien compró y el total real', (
    tester,
  ) async {
    final h = _Harness(tester)
      ..listings.own = [
        _listing(id: 'mano', status: ListingStatus.sold, soldAt: _now),
      ]
      ..orders.stored.addAll([
        _sale(),
        _sale(
          id: 's2',
          title: 'Libro de Cálculo',
          priceCents: 30000,
          quantity: 2,
        ),
        // Ni una compra ni una venta sin completar son ventas.
        sampleOrder(id: 'compra', status: OrderStatus.completed),
        sampleOrder(id: 'abierta', isBuyer: false),
      ]);
    await h.open();

    // Dos ventas y una marcada a mano.
    await h.tapText('Vendidos (3)');

    expect(find.text('2 ventas'), findsOneWidget);
    expect(find.text(r'$1,050'), findsOneWidget);
    expect(
      find.text(r'$600 · 10 nov · 2 piezas · Ana Sofía Ramírez'),
      findsOneWidget,
    );
    expect(find.text(r'$450 · 10 nov · Ana Sofía Ramírez'), findsOneWidget);
    expect(find.text(r'$450 · 10 nov · Marcado a mano'), findsOneWidget);
    expect(find.byKey(const Key('my-sale-compra')), findsNothing);
    expect(find.byKey(const Key('my-sale-abierta')), findsNothing);
    // La mas nueva primero y lo marcado a mano al final.
    expect(
      tester.getTopLeft(find.byKey(const Key('my-sale-s2'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('my-sale-s1'))).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('my-sale-s1'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('my-product-mano'))).dy),
    );

    await h.tapKey('my-sale-s2');

    final router = GoRouter.of(tester.element(find.byType(Scaffold).last));
    expect(router.state.uri.path, AppRoutes.order('s2'));
  });

  testWidgets('Vendidos: Ver más trae ventas y luego lo marcado a mano', (
    tester,
  ) async {
    final h = _Harness(tester)
      ..listings.own = [
        _listing(id: 'mano', status: ListingStatus.sold, soldAt: _now),
      ]
      ..orders.salesPageSize = 1
      ..orders.stored.addAll([_sale(), _sale(id: 's2')]);
    await h.open();
    await h.tapText('Vendidos (3)');

    expect(find.byKey(const Key('my-sale-s2')), findsOneWidget);
    expect(find.byKey(const Key('my-sale-s1')), findsNothing);
    expect(find.byKey(const Key('my-product-mano')), findsNothing);
    // La tarjeta cuenta todas, no solo la pagina.
    expect(find.text('2 ventas'), findsOneWidget);

    await h.tapKey('my-products-more');

    expect(h.orders.salesCalls.last, 's2');
    expect(find.byKey(const Key('my-sale-s1')), findsOneWidget);
    expect(find.byKey(const Key('my-product-mano')), findsOneWidget);
    expect(find.byKey(const Key('my-products-more')), findsNothing);
  });

  testWidgets('Vendidos: si las ventas no cargan, lo explica y reintenta', (
    tester,
  ) async {
    final h = _Harness(tester)
      ..orders.salesFailure = const ApiFailure(
        code: ApiFailure.serverError,
        message: 'Algo salió mal. Intenta de nuevo.',
      )
      ..orders.stored.add(_sale());
    await h.open();

    await h.tapText('Vendidos (0)');

    expect(find.text('Algo salió mal. Intenta de nuevo.'), findsOneWidget);

    await h.tapText('Reintentar');

    expect(find.byKey(const Key('my-sale-s1')), findsOneWidget);
    expect(find.text('Vendidos (1)'), findsOneWidget);
  });

  testWidgets('Ver más: trae la siguiente pagina de la pestana', (
    tester,
  ) async {
    final h = _Harness(tester)
      ..listings.pageSize = 1
      ..listings.own = [_listing(), _listing(id: 'libro', title: 'Libro')];
    await h.open();

    expect(find.byKey(const Key('my-product-calc')), findsOneWidget);
    expect(find.byKey(const Key('my-product-libro')), findsNothing);

    await h.tapKey('my-products-more');

    expect(find.byKey(const Key('my-product-libro')), findsOneWidget);
    expect(find.byKey(const Key('my-products-more')), findsNothing);
  });

  testWidgets('cambiar piezas: el selector de Vender-4 de 0 a 10', (
    tester,
  ) async {
    final h = _Harness(tester)..listings.own = [_listing(stock: 2)];
    await h.open();

    await h.manage('calc', 'Cambiar piezas');

    expect(find.byKey(const Key('my-product-stock')), findsOneWidget);
    expect(find.text('Piezas disponibles'), findsOneWidget);
    await h.tapKey('sell-quantity--1');
    await h.tapKey('sell-quantity--1');
    // Con 0 queda agotada; ya no baja de 0.
    expect(find.text('Con 0 queda como agotado'), findsOneWidget);
    await h.tapKey('sell-quantity--1');
    await h.tapKey('my-product-stock-save');

    expect(h.listings.stockChanges, {'calc': 0});
    expect(
      find.text('Guardamos las piezas. Ya aparece como agotado.'),
      findsOneWidget,
    );
    expect(find.text('Activos (0)'), findsOneWidget);
    expect(find.text('Agotados (1)'), findsOneWidget);
  });

  testWidgets('Reponer en Agotados la deja con 1 pieza', (tester) async {
    final h = _Harness(tester)
      ..listings.own = [
        _listing(id: 'agotada', stock: 0, status: ListingStatus.soldOut),
      ];
    await h.open();

    await h.tapText('Agotados (1)');
    await h.tapKey('my-product-restock-agotada');

    expect(h.listings.stockChanges, {'agotada': 1});
    expect(
      find.text(
        'Repusiste «Calculadora Casio fx-991ES Plus». Ya está disponible',
      ),
      findsOneWidget,
    );
    expect(find.text('Activos (1)'), findsOneWidget);
    expect(find.text('Agotados (0)'), findsOneWidget);
  });

  testWidgets('una pausada sigue pausada al cambiar piezas', (tester) async {
    final h = _Harness(tester)
      ..listings.own = [_listing(status: ListingStatus.hidden)];
    await h.open();

    await h.manage('calc', 'Cambiar piezas');
    await h.tapKey('sell-quantity-1');
    await h.tapKey('my-product-stock-save');

    expect(h.listings.stockChanges, {'calc': 2});
    expect(h.listings.own.single.paused, isTrue);
    expect(find.text(r'$450 · Pausada · Quedan 2'), findsOneWidget);
  });
}
