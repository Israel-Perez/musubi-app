import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/profile/presentation/seller_profile_screen.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 11, 12);

PublicProfile _withoutRatings() => PublicProfile(
  id: FakeProfileRepository.publicSample.id,
  fullName: 'Valeria Cruz',
  campusShortName: 'UTTT',
  memberSince: DateTime(2025, 2, 15),
  careerShortName: 'Arquitectura',
  term: 8,
  ratingCount: 0,
);

ProductSummary _product(String id, String title) => ProductSummary(
  id: id,
  title: title,
  priceCents: 45000,
  stock: 1,
  sellerName: 'Valeria C.',
  publishedAt: _now.subtract(const Duration(hours: 1)),
);

ProductDetail _detail() => ProductDetail(
  id: 'p1',
  title: 'Calculadora Casio',
  description: 'La usé un semestre.',
  categoryName: 'Calculadoras',
  priceCents: 45000,
  condition: 'used',
  stock: 1,
  status: 'active',
  photoUrls: const [],
  publishedAt: _now.subtract(const Duration(days: 1)),
  sellerId: FakeProfileRepository.publicSample.id,
  sellerName: 'Valeria Cruz',
);

/// App completa con el router real y el perfil público de la maqueta.
class _Harness {
  new(
    this.tester, {
    FakeProfileRepository? profiles,
    FakeCatalogRepository? catalog,
  }) : profiles = profiles ?? FakeProfileRepository(),
       catalog = catalog ?? FakeCatalogRepository();

  final WidgetTester tester;
  final FakeProfileRepository profiles;
  final FakeCatalogRepository catalog;
  final chat = FakeChatRepository();
  late ProviderContainer container;

  Future<void> open(
    String sellerId, {
    Size size = const Size(1170, 2532),
    bool settle = true,
    SellerProfileOrigin? origin,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = chatTokens(_now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(catalog),
          favoritesRepositoryProvider.overrideWithValue(
            FakeFavoritesRepository(),
          ),
          profileRepositoryProvider.overrideWithValue(profiles),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(chat),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
        ],
        child: const MusubiApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    container
        .read(routerProvider)
        .go(AppRoutes.sellerProfile(sellerId), extra: origin);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }
}

FakeProfileRepository _withProfile(PublicProfile profile) =>
    FakeProfileRepository()..publicProfiles[profile.id] = profile;

void main() {
  final valeria = FakeProfileRepository.publicSample;

  testWidgets('cabecera con campus, carrera, periodo, reputación y desde', (
    tester,
  ) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));
    h.catalog.sellerListingsResponse = const ProductPage(total: 3);

    await h.open(valeria.id);

    expect(find.text('Valeria Cruz'), findsWidgets);
    expect(find.text('Arquitectura · 8º cuatrimestre'), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
    expect(find.textContaining('18 calificaciones'), findsOneWidget);
    expect(find.text('En Musubi desde feb 2025'), findsOneWidget);
    expect(find.text('Publicaciones (3)'), findsOneWidget);
    // Recuadro de la maqueta: ventas, publicaciones y "A tiempo" (sin dato).
    String stat(String key) =>
        tester.widget<Text>(find.byKey(Key('seller-stat-$key'))).data!;
    expect(stat('sales'), '15');
    expect(stat('publications'), '3');
    expect(stat('on-time'), '—');
    expect(find.text('Seguir'), findsOneWidget);
    expect(find.text('Mensaje'), findsOneWidget);
  });

  testWidgets('ventas ocultas y publicaciones cargando se ven con "—"', (
    tester,
  ) async {
    final h = _Harness(tester, profiles: _withProfile(_withoutRatings()));
    h.catalog.pendingSellerListings = Completer<ProductPage>();

    await h.open(valeria.id, settle: false);
    await tester.pump();
    await tester.pump();

    String stat(String key) =>
        tester.widget<Text>(find.byKey(Key('seller-stat-$key'))).data!;
    expect(stat('sales'), '—');
    expect(stat('publications'), '—');

    h.catalog.pendingSellerListings!.complete(const ProductPage(total: 2));
    await tester.pumpAndSettle();
    expect(stat('publications'), '2');
  });

  testWidgets('"Mensaje" desde Producto abre el chat de esa publicación', (
    tester,
  ) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));
    h.catalog.sellerListingsResponse = ProductPage(
      items: [_product('p2', 'Laptop Lenovo')],
      total: 2,
    );

    await h.open(
      valeria.id,
      origin: SellerProfileOrigin.product(_product('p1', 'Calculadora Casio')),
    );
    await tester.tap(find.byKey(const Key('seller-mensaje')));
    await tester.pumpAndSettle();

    expect(find.text('Escribe un mensaje…'), findsOneWidget);
    expect(h.chat.started, ['p1']);
  });

  testWidgets('"Mensaje" sin origen usa su primera publicación activa', (
    tester,
  ) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));
    h.catalog.sellerListingsResponse = ProductPage(
      items: [_product('p2', 'Laptop Lenovo')],
      total: 1,
    );

    await h.open(valeria.id);
    await tester.tap(find.byKey(const Key('seller-mensaje')));
    await tester.pumpAndSettle();

    expect(find.text('Escribe un mensaje…'), findsOneWidget);
    expect(h.chat.started, ['p2']);
  });

  testWidgets('"Mensaje" sin publicaciones lo explica', (tester) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));

    await h.open(valeria.id);
    await tester.tap(find.byKey(const Key('seller-mensaje')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Valeria no tiene publicaciones activas para escribirle.'),
      findsOneWidget,
    );
    expect(find.text('Escribe un mensaje…'), findsNothing);
    expect(h.chat.started, isEmpty);
  });

  testWidgets('"Seguir" avisa que llega pronto', (tester) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));

    await h.open(valeria.id);
    await tester.tap(find.byKey(const Key('seller-seguir')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Seguir a Valeria llega muy pronto.'), findsOneWidget);
  });

  testWidgets('"Compartir" avisa que llega pronto', (tester) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));

    await h.open(valeria.id);
    await tester.tap(find.byKey(const Key('seller-compartir')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Compartir llega muy pronto.'), findsOneWidget);
  });

  testWidgets('sin /careers muestra el periodo sin unidad', (tester) async {
    final h = _Harness(
      tester,
      profiles: _withProfile(valeria)..failCareers = true,
    );

    await h.open(valeria.id);

    expect(find.text('Arquitectura · 8º'), findsOneWidget);
    expect(find.textContaining('cuatrimestre'), findsNothing);
  });

  testWidgets('con la carrera oculta queda solo el campus', (tester) async {
    final hidden = PublicProfile(
      id: valeria.id,
      fullName: 'Valeria Cruz',
      campusShortName: 'UTTT',
      memberSince: DateTime(2025, 2, 15),
      ratingCount: 0,
    );
    final h = _Harness(tester, profiles: _withProfile(hidden));

    await h.open(valeria.id);

    expect(
      tester.widget<Text>(find.byKey(const Key('seller-subtitle'))).data,
      'UTTT',
    );
  });

  testWidgets('mientras carga muestra el esqueleto', (tester) async {
    final pending = Completer<PublicProfile>();
    final profiles = _withProfile(valeria)..pendingPublicProfile = pending;
    final h = _Harness(tester, profiles: profiles);

    await h.open(valeria.id, settle: false);
    await tester.pump();

    expect(find.byKey(const Key('seller-loading')), findsOneWidget);

    pending.complete(valeria);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('seller-name')), findsOneWidget);
  });

  testWidgets('si fallan las publicaciones, la cabecera sigue', (tester) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));
    h.catalog.failSellerListings = true;

    await h.open(valeria.id);

    expect(find.text('Arquitectura · 8º cuatrimestre'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    h.catalog
      ..failSellerListings = false
      ..sellerListingsResponse = const ProductPage(total: 1);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Publicaciones (1)'), findsOneWidget);
  });

  testWidgets('sin calificaciones y opiniones vacías (RN-26)', (tester) async {
    final profile = _withoutRatings();
    final h = _Harness(tester, profiles: _withProfile(profile));

    await h.open(profile.id);

    expect(find.text('Sin calificaciones'), findsOneWidget);
    expect(find.text('Opiniones (0)'), findsOneWidget);

    await tester.ensureVisible(find.text('Opiniones (0)'));
    await tester.tap(find.text('Opiniones (0)'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay opiniones'), findsOneWidget);
    expect(find.textContaining('Cuando alguien califique'), findsOneWidget);
  });

  testWidgets('publicaciones activas con su contador y tarjetas', (
    tester,
  ) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));
    h.catalog.sellerListingsResponse = ProductPage(
      items: [
        _product('p1', 'Calculadora Casio'),
        _product('p2', 'Laptop Lenovo'),
      ],
      total: 3,
    );

    await h.open(valeria.id);

    expect(find.text('Publicaciones (3)'), findsOneWidget);
    expect(find.text('Calculadora Casio'), findsOneWidget);
    expect(find.text('Laptop Lenovo'), findsOneWidget);
    expect(find.textContaining('Valeria C.'), findsNothing);
  });

  testWidgets('sin publicaciones activas lo explica', (tester) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));

    await h.open(valeria.id);

    expect(
      find.text('Todavía no tiene publicaciones activas.'),
      findsOneWidget,
    );
  });

  testWidgets('un error de red se reintenta', (tester) async {
    final h = _Harness(
      tester,
      profiles: _withProfile(valeria)..failPublicProfile = true,
    );

    await h.open(valeria.id);

    expect(find.text('Algo salió mal'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    h.profiles.failPublicProfile = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Arquitectura · 8º cuatrimestre'), findsOneWidget);
  });

  testWidgets('un perfil inexistente no revela el motivo', (tester) async {
    final h = _Harness(tester);

    await h.open(valeria.id);

    expect(find.text('No encontramos ese perfil'), findsOneWidget);
    expect(find.text('Regresar'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('"Ver más" agrega la siguiente página', (tester) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));
    h.catalog
      ..sellerListingsResponse = ProductPage(
        items: [_product('p1', 'Calculadora Casio')],
        total: 2,
        nextCursor: 'next',
      )
      ..sellerListingsByCursor['next'] = ProductPage(
        items: [_product('p2', 'Laptop Lenovo')],
        total: 2,
      );

    await h.open(valeria.id);

    await tester.ensureVisible(find.text('Ver más'));
    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();

    expect(find.text('Laptop Lenovo'), findsOneWidget);
    expect(h.catalog.sellerCursors, [null, 'next']);
  });

  testWidgets('tocar una publicación abre su detalle', (tester) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));
    h.catalog
      ..sellerListingsResponse = ProductPage(
        items: [_product('p1', 'Calculadora Casio')],
        total: 1,
      )
      ..details['p1'] = _detail();

    await h.open(valeria.id);
    await tester.tap(find.text('Calculadora Casio'));
    await tester.pumpAndSettle();

    expect(find.text('Comprar'), findsOneWidget);
  });

  testWidgets('accesibilidad y 360x640 sin overflow', (tester) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));
    h.catalog.sellerListingsResponse = const ProductPage(total: 1);

    await h.open(valeria.id, size: const Size(360 * 3, 640 * 3));

    expect(tester.takeException(), isNull);
    expect(tester, meetsGuideline(textContrastGuideline));
    expect(
      tester,
      meetsGuideline(
        const MinimumTapTargetGuideline(
          size: Size(44, 44),
          link: 'RNF-27: área táctil mínima de 44 dp',
        ),
      ),
    );
  });

  testWidgets('tablet sin overflow', (tester) async {
    final h = _Harness(tester, profiles: _withProfile(valeria));
    h.catalog.sellerListingsResponse = const ProductPage(total: 1);

    await h.open(valeria.id, size: const Size(800 * 3, 1280 * 3));

    expect(tester.takeException(), isNull);
  });
}
