import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 10, 27, 12);

/// App con sesion, la vitrina de muestra y los fakes de publicar.
class _Harness {
  new(this.tester, {PriceRange? range, int failUploads = 0})
    : listings = FakeListingsRepository(range: range, failUploads: failUploads);

  final WidgetTester tester;
  final FakeListingsRepository listings;
  final picker = FakePhotoPicker();

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
          photoPickerProvider.overrideWithValue(picker),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(tokens)),
          initialSessionTokensProvider.overrideWithValue(tokens),
        ],
        child: const MusubiApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(String text) => tap(find.text(text).last);

  Future<void> tapKey(String key) => tap(find.byKey(Key(key)));

  Future<void> type(String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  /// Inicio → Publicar → "Vender un producto".
  Future<void> startSelling() async {
    await tapText('Publicar');
    await tapKey('publish-sell');
  }

  /// Paso 1 con una foto de la camara → paso 2 → … → paso 4.
  Future<void> fillUntilCondition() async {
    await startSelling();
    await tapKey('sell-camera');
    await tapText('Continuar');
    await type('sell-title', 'Calculadora Casio fx-991ES Plus');
    await type('sell-description', 'La usé un semestre.');
    await tapText('Continuar');
    await type('sell-price', '450');
    await tapKey('sell-category-calculadoras');
    await tapText('Continuar');
  }
}

// HU-06: maqueta Publicar → Vender-1…4 → Vender-listo.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
  });
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
        .reset(),
  );

  testWidgets('Publicar abre la hoja y el boton central dice Cerrar', (
    tester,
  ) async {
    final h = _Harness(tester);
    await h.open();

    await h.tapText('Publicar');

    expect(find.text('¿Qué quieres publicar?'), findsOneWidget);
    expect(find.text('SOLO EN MUSUBI'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);

    await h.tapText('Cerrar');
    expect(find.text('¿Qué quieres publicar?'), findsNothing);
    expect(find.text('Publicar'), findsOneWidget);
  });

  testWidgets('cada paso dice que falta y al final se publica', (tester) async {
    final h = _Harness(tester);
    await h.open();
    await h.startSelling();

    expect(find.text('Agrega fotos'), findsOneWidget);
    await h.tapText('Continuar');
    expect(find.text('Agrega al menos una foto para continuar'), findsOne);

    await h.tapKey('sell-camera');
    expect(find.text('1 de 8'), findsOneWidget);
    expect(find.text('Portada'), findsOneWidget);
    await h.tapText('Continuar');

    expect(find.text('Cuéntanos qué es'), findsOneWidget);
    await h.tapText('Continuar');
    expect(find.text('Escribe el nombre del producto'), findsOneWidget);
    await h.type('sell-title', 'Calculadora Casio fx-991ES Plus');
    await h.type('sell-description', 'La usé un semestre.');
    expect(find.text('19 / 500'), findsOneWidget);
    await h.tapText('Continuar');

    expect(find.text('Precio y categoría'), findsOneWidget);
    await h.tapText('Continuar');
    expect(find.text('Ponle un precio a tu producto'), findsOneWidget);
    await h.type('sell-price', '450');
    await h.tapText('Continuar');
    expect(find.text('Elige una categoría'), findsOneWidget);
    await h.tapKey('sell-category-calculadoras');
    await h.tapText('Continuar');

    expect(find.text('Estado y cantidad'), findsOneWidget);
    expect(find.text('Usado · Como nuevo · 1 disponible'), findsOneWidget);
    await h.tapKey('sell-condition-new');
    expect(find.text('¿Cómo está?'), findsNothing);
    await h.tapKey('sell-quantity-1');
    expect(find.text('Nuevo · Sin usar · 2 disponibles'), findsOneWidget);
    await h.tapKey('sell-publish');

    expect(find.text('¡Tu producto ya está publicado!'), findsOneWidget);
    expect(find.text('Publicado ahora'), findsOneWidget);
    expect(find.text(r'$450'), findsOneWidget);
    final listing = h.listings.published.single;
    expect(listing.title, 'Calculadora Casio fx-991ES Plus');
    expect(listing.priceCents, 45000);
    expect(listing.category, 'calculadoras');
    expect(listing.condition, ProductCondition.brandNew);
    expect(listing.quantity, 2);
    expect(listing.photoKeys, ['media/products/u1/1.webp']);
    expect(listing.toJson()['conditionDetail'], isNull);
  });

  testWidgets('Ver mis productos: pestanas e inventario', (tester) async {
    final h = _Harness(tester);
    h.listings.own = const [
      OwnListing(
        product: ProductSummary(
          id: 'a',
          title: 'Calculadora Casio fx-991ES Plus',
          priceCents: 45000,
          stock: 1,
        ),
        status: ListingStatus.active,
      ),
      OwnListing(
        product: ProductSummary(
          id: 'b',
          title: 'Audífonos inalámbricos',
          priceCents: 65000,
          stock: 0,
        ),
        status: ListingStatus.soldOut,
      ),
    ];
    await h.open();
    await h.fillUntilCondition();
    await h.tapKey('sell-publish');

    await h.tapText('Ver mis productos');

    expect(find.text('Mis productos'), findsOneWidget);
    expect(find.text('Activos (1)'), findsOneWidget);
    expect(find.text('Agotados (1)'), findsOneWidget);
    expect(find.text(r'$450 · Último'), findsOneWidget);
    await h.tapText('Agotados (1)');
    expect(find.text(r'$650 · Agotado'), findsOneWidget);
  });

  testWidgets('quitar una foto se puede deshacer', (tester) async {
    final h = _Harness(tester);
    await h.open();
    await h.startSelling();
    await h.tapKey('sell-gallery');
    expect(find.text('Agregaste 3 fotos'), findsOneWidget);
    expect(find.text('3 de 8'), findsOneWidget);
    expect(h.picker.galleryRequests, [8]);

    await h.tap(find.bySemanticsLabel('Quitar foto 2'));
    expect(find.text('2 de 8'), findsOneWidget);
    expect(find.text('Quitaste la foto 2'), findsOneWidget);

    await h.tapText('Deshacer');
    expect(find.text('3 de 8'), findsOneWidget);
  });

  testWidgets('sin camara lo dice; una foto que no subio se reintenta', (
    tester,
  ) async {
    final h = _Harness(tester, failUploads: 1);
    await h.open();
    await h.startSelling();

    h.picker.cameraFails = true;
    await h.tapKey('sell-camera');
    expect(find.text('No pudimos abrir la cámara.'), findsOneWidget);

    h.picker.cameraFails = false;
    await h.tapKey('sell-camera');
    expect(find.bySemanticsLabel('Reintentar subir la foto 1'), findsOneWidget);
    await h.tap(find.bySemanticsLabel('Reintentar subir la foto 1'));
    expect(find.bySemanticsLabel('Reintentar subir la foto 1'), findsNothing);
    expect(h.listings.uploaded, ['fotos/camara-1.jpg']);
  });

  testWidgets('Guardar conserva el borrador para despues', (tester) async {
    final h = _Harness(tester);
    await h.open();
    await h.startSelling();
    await h.tapKey('sell-camera');
    await h.tapKey('sell-save');
    expect(
      find.text(
        'Borrador guardado. Lo terminas cuando quieras desde Publicar.',
      ),
      findsOneWidget,
    );

    await h.tap(find.bySemanticsLabel('Cerrar'));
    await h.startSelling();

    expect(find.text('1 de 8'), findsOneWidget);
  });

  testWidgets('el rango de precios dice si el precio esta en el rango', (
    tester,
  ) async {
    final h = _Harness(
      tester,
      range: const PriceRange(lowCents: 38000, highCents: 52000),
    );
    await h.open();
    await h.fillUntilCondition();
    await h.tapText('Atrás');

    expect(find.byKey(const Key('sell-price-range')), findsOneWidget);
    expect(find.text('Tu precio está dentro del rango'), findsOneWidget);
    await h.type('sell-price', '900');
    expect(
      find.text('Tu precio está arriba del rango: podría tardar en venderse'),
      findsOneWidget,
    );
  });
}
