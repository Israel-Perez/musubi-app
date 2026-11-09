import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_controls.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/data/demo_catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 10, 5, 20);

const _ana = SessionProfile(
  fullName: 'Ana Sofía Ramírez',
  email: 'ana.ramirez@uttt.edu.mx',
  campus: 'UTTT',
);

SessionTokens _session({SessionProfile? profile = _ana}) => SessionTokens(
  accessToken: 'access',
  accessExpiresAt: _now.add(const Duration(minutes: 15)),
  refreshToken: 'refresh',
  profile: profile,
);

Future<void> _open(
  WidgetTester tester, {
  required CatalogRepository catalog,
  SessionTokens? session,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        brandSplashEnabledProvider.overrideWithValue(false),
        catalogRepositoryProvider.overrideWithValue(catalog),
        sessionApiProvider.overrideWithValue(FakeSessionApi()),
        clockProvider.overrideWithValue(() => _now),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
        initialSessionTokensProvider.overrideWithValue(session),
      ],
      child: const MusubiApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

// SCRUM-82: Inicio igual a la maqueta (`Inicio-visitante`, `Inicio`,
// `Inicio-cargando`, `Inicio-error`) y la hoja "Filtrar".
void main() {
  setUp(() {
    // Pantalla de telefono de la maqueta (390 x 844).
    TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
  });
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
        .reset(),
  );

  group('Filtrar', () {
    Future<void> openFilter(WidgetTester tester) async {
      await _open(tester, catalog: DemoCatalogRepository(() => _now));
      await tester.scrollUntilVisible(
        find.byKey(const Key('home-filter')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('home-filter')));
      await tester.pumpAndSettle();
    }

    testWidgets('elige una categoria: titulo y globo de 1 filtro', (
      tester,
    ) async {
      await openFilter(tester);
      expect(find.text('Filtrar'), findsOneWidget);
      expect(find.text('Ver 14 productos'), findsOneWidget);

      await tester.tap(find.text('Laboratorio'));
      await tester.pumpAndSettle();
      expect(find.text('Ver 3 productos'), findsOneWidget);

      await tester.tap(find.text('Ver 3 productos'));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar'), findsNothing);
      expect(find.text('Laboratorio'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Ocultar agotados y Limpiar', (tester) async {
      await openFilter(tester);

      await tester.tap(find.byType(MusubiSwitch));
      await tester.pumpAndSettle();
      expect(find.text('Ver 12 productos'), findsOneWidget);

      await tester.tap(find.text('Limpiar'));
      await tester.pumpAndSettle();
      expect(find.text('Ver 14 productos'), findsOneWidget);
    });

    testWidgets('sin categorias del catalogo no hay boton de filtro', (
      tester,
    ) async {
      await _open(tester, catalog: FakeCatalogRepository([sampleFeed]));

      expect(find.byKey(const Key('home-filter')), findsNothing);
    });
  });

  // Letra del sistema 30 % mas grande: nada se desborda (la fuente de las
  // pruebas es mas ancha que Plus Jakarta Sans).
  testWidgets('con letra grande la vitrina no se desborda', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _open(tester, catalog: DemoCatalogRepository(() => _now));
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-join-banner')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
  });

  // HU-48 fase 2: sin vistas (HU-11) no hay "Populares"; la vitrina vacia
  // explica por que.
  testWidgets('sin vistas no hay Populares, pero si lo recien publicado', (
    tester,
  ) async {
    await _open(
      tester,
      catalog: FakeCatalogRepository([
        const HomeFeed(
          recent: [
            ProductSummary(
              id: 'r1',
              title: 'Calculadora Casio fx-991ES Plus',
              priceCents: 45000,
              stock: 1,
            ),
          ],
        ),
      ]),
    );

    expect(find.text('Populares'), findsNothing);
    expect(find.text('Recién publicados'), findsOneWidget);
  });

  testWidgets('vitrina vacia: lo dice en lugar de Populares', (tester) async {
    await _open(tester, catalog: FakeCatalogRepository());

    expect(find.byKey(const Key('home-empty-products')), findsOneWidget);
  });

  group('con sesion (maqueta Inicio)', () {
    testWidgets('saluda por nombre y muestra el buscador', (tester) async {
      await _open(
        tester,
        catalog: DemoCatalogRepository(() => _now),
        session: _session(),
      );

      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(find.text('Busca libros, laptops, batas…'), findsOneWidget);
      expect(find.text('Se busca en tu comunidad'), findsOneWidget);
      expect(find.text('Entrar'), findsNothing);
      expect(find.byKey(const Key('home-join-banner')), findsNothing);
    });

    testWidgets('Publicaciones recientes: de la mas nueva a la mas vieja', (
      tester,
    ) async {
      await _open(
        tester,
        catalog: DemoCatalogRepository(() => _now),
        session: _session(),
      );
      await tester.scrollUntilVisible(
        find.text('hace 3 h · Luis M.'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('hace 20 min · Jorge S.'), findsOneWidget);
      expect(find.text('hace 1 h · Diego H.'), findsOneWidget);
      expect(find.text('hace 2 h · Paola N.'), findsOneWidget);
      // La de hace 2 dias ya no cabe en las 4 de la maqueta.
      expect(find.text('hace 2 días · Valeria C.'), findsNothing);
    });

    testWidgets('sin el perfil guardado saluda sin nombre', (tester) async {
      await _open(
        tester,
        catalog: DemoCatalogRepository(() => _now),
        session: _session(profile: null),
      );

      expect(find.text('Hola'), findsOneWidget);
    });

    testWidgets('cargando: "¿Qué necesitas hoy?" y el esqueleto', (
      tester,
    ) async {
      await _open(
        tester,
        catalog: FakeCatalogRepository.pending(),
        session: _session(),
        settle: false,
      );

      expect(find.text('¿Qué necesitas hoy?'), findsOneWidget);
      expect(find.byKey(const Key('home-loading')), findsOneWidget);
    });

    testWidgets('sin red: solo la barra de arriba y el error', (tester) async {
      await _open(
        tester,
        catalog: FakeCatalogRepository([
          const ApiFailure(code: ApiFailure.networkOffline, message: 'x'),
        ]),
        session: _session(),
      );

      expect(find.text('Hola, Ana'), findsNothing);
      expect(find.text('Sin conexión a internet'), findsOneWidget);
      expect(find.text('Error de conexión'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
