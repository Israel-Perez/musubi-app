import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_board.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/fake_wanted.dart';
import '../../helpers/in_memory_token_store.dart';

// Lunes 9 de noviembre de 2026, mediodia en el campus.
final _now = DateTime(2026, 11, 9, 12);

/// Las solicitudes de la maqueta (`REQUESTS`).
final List<WantedRequest> _board = [
  boardWanted(
    neededBy: DateTime(2026, 11, 9),
    createdAt: _now.toUtc().subtract(const Duration(minutes: 20)),
  ),
  boardWanted(
    id: 'r-laptop',
    title: 'Laptop para programación con 16 GB de RAM',
    category: 'laptops',
    categoryName: 'Laptops',
    budgetCents: 1200000,
    neededBy: DateTime(2026, 11, 19),
    requester: 'Mariana López',
    requesterId: 'u-mariana',
    career: 'Ing. en Software',
    offers: 2,
    createdAt: _now.toUtc().subtract(const Duration(hours: 1)),
  ),
  boardWanted(
    id: 'r-fisica',
    title: 'Física Universitaria, Sears-Zemansky',
    category: 'libros',
    categoryName: 'Libros',
    budgetCents: 40000,
    requester: 'Luis Martínez',
    requesterId: 'u-luis',
    career: null,
    offers: 1,
    createdAt: _now.toUtc().subtract(const Duration(hours: 3)),
  ),
];

const _categories = [
  CatalogCategory(slug: 'laboratorio', name: 'Laboratorio'),
  CatalogCategory(slug: 'laptops', name: 'Laptops'),
  CatalogCategory(slug: 'libros', name: 'Libros'),
];

/// App completa con el router real y el tablero falso (HU-15).
class BoardHarness {
  new(
    this.tester, {
    FakeWantedRepository? wanted,
    this.signedIn = true,
    this.phone = true,
  }) : wanted = wanted ?? FakeWantedRepository(board: _board);

  final WidgetTester tester;
  final FakeWantedRepository wanted;
  final bool signedIn;

  /// Telefono de la maqueta (390 x 844); sin el, la pantalla de prueba.
  final bool phone;

  Future<void> open() async {
    if (phone) {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }
    final session = signedIn ? chatTokens(_now.toUtc()) : null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([const HomeFeed()])
              ..categoriesResponse = _categories,
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          wantedRepositoryProvider.overrideWithValue(wanted),
          listingsRepositoryProvider.overrideWithValue(
            FakeListingsRepository(),
          ),
        ],
        child: const MusubiApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(MusubiApp)))
        .read(routerProvider)
        .go(AppRoutes.wanted);
    await tester.pumpAndSettle();
  }

  /// Toca y espera: las opciones de una hoja eligen 160 ms despues y la
  /// hoja siguiente abre 240 ms despues, como la maqueta.
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  WantedBoardFilter get lastFilter => wanted.boardCalls.last.$1;
}

void main() {
  group('Se-busca (con sesion)', () {
    testWidgets('lista los boletos con quien busca, su carrera y el plazo', (
      tester,
    ) async {
      final h = BoardHarness(tester);
      await h.open();

      expect(find.text('Se busca'), findsWidgets);
      expect(find.text('Fernanda Ortiz'), findsOneWidget);
      expect(find.text('QFB · hace 20 min'), findsOneWidget);
      expect(
        find.text('Bata de laboratorio talla M, manga larga'),
        findsOneWidget,
      );
      expect(find.text(r'$300'), findsOneWidget);
      expect(find.text('lun 9 nov'), findsOneWidget);
      expect(find.text('Laboratorio'), findsOneWidget);
      expect(
        find.text('Ing. en Software · hace 1 h · 2 ofertas'),
        findsOneWidget,
      );
      expect(find.text(r'$12,000'), findsOneWidget);
      // Sin carrera visible y sin fecha.
      await tester.scrollUntilVisible(find.text('Luis Martínez'), 300);
      expect(find.text('hace 3 h · 1 oferta'), findsOneWidget);
      expect(find.text('Sin fecha'), findsOneWidget);
      expect(find.text('SE BUSCA'), findsWidgets);
    });

    testWidgets('Filtrar: categorias (varias), presupuesto y el numero', (
      tester,
    ) async {
      final h = BoardHarness(tester);
      await h.open();

      await h.tap(find.byKey(const Key('wanted-filter')));
      expect(find.text('Filtrar solicitudes'), findsOneWidget);
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Cualquier presupuesto'), findsOneWidget);
      expect(find.text('Cualquier fecha'), findsOneWidget);

      await h.tap(find.text('Categoría'));
      expect(find.byKey(const Key('wanted-categories')), findsOneWidget);
      // La lista de la hoja suma "Otro".
      expect(find.byKey(const ValueKey('option-otro')), findsOneWidget);
      await h.tap(find.byKey(const ValueKey('option-libros')));
      await h.tap(find.byKey(const ValueKey('option-laboratorio')));
      await h.tap(find.byKey(const Key('wanted-categories-apply')));

      expect(h.lastFilter.categories.map((c) => c.slug), [
        'laboratorio',
        'libros',
      ]);
      expect(
        find.text('Laptop para programación con 16 GB de RAM'),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('Filtrar solicitudes, 2 activos'),
        findsOneWidget,
      );

      await h.tap(find.byKey(const Key('wanted-filter')));
      expect(find.text('Laboratorio, Libros'), findsOneWidget);
      await h.tap(find.text('Presupuesto'));
      await h.tap(find.byKey(const ValueKey('option-WantedBudget.upTo300')));

      expect(h.lastFilter.budget, WantedBudget.upTo300);
      expect(h.lastFilter.toQuery(), {
        'category': ['laboratorio', 'libros'],
        'maxBudgetCents': 30000,
      });
      expect(find.text('Física Universitaria, Sears-Zemansky'), findsNothing);
      expect(
        find.text('Bata de laboratorio talla M, manga larga'),
        findsOneWidget,
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Fecha límite va como dias en la consulta', (tester) async {
      final h = BoardHarness(tester);
      await h.open();

      await h.tap(find.byKey(const Key('wanted-filter')));
      await h.tap(find.text('Fecha límite'));
      await h.tap(find.text('En 3 días o menos'));

      expect(h.lastFilter.toQuery(), {'neededWithinDays': 3});
    });

    testWidgets('la lupa filtra al escribir y al cerrarla vuelve todo', (
      tester,
    ) async {
      final h = BoardHarness(tester);
      await h.open();

      await h.tap(find.byKey(const Key('wanted-search')));
      expect(find.text('Busca solicitudes: bata, laptop…'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('wanted-search-field')),
        'laptop',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(h.lastFilter.query, 'laptop');
      expect(
        find.text('Bata de laboratorio talla M, manga larga'),
        findsNothing,
      );
      expect(
        find.text('Laptop para programación con 16 GB de RAM'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('wanted-search-field')),
        'nave',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wanted-board-no-matches')), findsOneWidget);

      await h.tap(find.byKey(const Key('wanted-search')));
      expect(find.byKey(const Key('wanted-search-field')), findsNothing);
      expect(h.lastFilter.query, isEmpty);
      expect(
        find.text('Bata de laboratorio talla M, manga larga'),
        findsOneWidget,
      );
    });

    testWidgets('al final de la lista carga la pagina siguiente', (
      tester,
    ) async {
      final h = BoardHarness(
        tester,
        wanted: FakeWantedRepository(board: _board, pageSize: 2),
      );
      await h.open();

      await tester.scrollUntilVisible(
        find.text('Física Universitaria, Sears-Zemansky'),
        300,
      );
      await tester.pumpAndSettle();

      expect(h.wanted.boardCalls.map((c) => c.$2), [null, 'r-laptop']);
    });

    testWidgets('sin solicitudes invita a pedir algo', (tester) async {
      final h = BoardHarness(tester, wanted: FakeWantedRepository());
      await h.open();

      expect(find.byKey(const Key('wanted-board-empty')), findsOneWidget);
      await h.tap(find.text('Pedir algo'));
      expect(find.text('Publicar lo que necesito'), findsOneWidget);
    });

    testWidgets('un error se muestra en espanol y se reintenta', (
      tester,
    ) async {
      final wanted = FakeWantedRepository(
        board: _board,
        boardFailure: const ApiFailure(
          code: 'network.offline',
          message: 'Sin conexión. Revisa tu internet.',
        ),
      );
      final h = BoardHarness(tester, wanted: wanted);
      await h.open();

      expect(find.text('Sin conexión. Revisa tu internet.'), findsOneWidget);
      wanted.boardFailure = null;
      await h.tap(find.text('Reintentar'));
      expect(find.text('Fernanda Ortiz'), findsOneWidget);
    });

    testWidgets('Yo tengo este producto abre la oferta (HU-16)', (
      tester,
    ) async {
      final h = BoardHarness(tester);
      await h.open();

      await h.tap(find.text('Yo tengo este producto').first);

      expect(find.text('Fernanda busca'), findsOneWidget);
      expect(find.byKey(const Key('offer-send')), findsOneWidget);
    });
  });

  group('Se-busca-visitante', () {
    testWidgets('explica como funciona y lista lo que se busca', (
      tester,
    ) async {
      final h = BoardHarness(
        tester,
        signedIn: false,
        wanted: FakeWantedRepository(
          board: [
            boardWanted(
              requester: 'Fernanda O.',
              requesterId: null,
              career: null,
              neededBy: DateTime(2026, 11, 9),
              createdAt: _now.toUtc().subtract(const Duration(minutes: 20)),
            ),
          ],
        ),
      );
      await h.open();

      expect(find.text('Tu campus lo pide. Tú lo tienes.'), findsOneWidget);
      for (final step in ['Alguien lo pide', 'Tú lo ofreces', 'Se lo vendes']) {
        expect(find.text(step), findsOneWidget);
      }
      expect(find.text('Lo que se busca hoy'), findsOneWidget);
      expect(find.text('Fernanda O. · hace 20 min'), findsOneWidget);
      expect(find.text('PAGA HASTA'), findsOneWidget);
      expect(find.byKey(const Key('wanted-filter')), findsNothing);
    });

    testWidgets('ofrecer o pedir algo pide la cuenta', (tester) async {
      final h = BoardHarness(tester, signedIn: false);
      await h.open();

      await h.tap(find.text('Yo tengo este producto').first);
      expect(find.text('¿Lo tienes? Véndelo'), findsOneWidget);
      await tester.tapAt(const Offset(195, 60));
      await tester.pumpAndSettle();

      await h.tap(find.byKey(const Key('wanted-ask')));
      expect(find.text('Pide lo que necesitas'), findsOneWidget);
    });

    testWidgets('Entrar lleva a iniciar sesion y vuelve a Se busca', (
      tester,
    ) async {
      // La pantalla de entrar no cabe a 390 con la letra de prueba.
      final h = BoardHarness(tester, signedIn: false, phone: false);
      await h.open();

      await h.tap(find.byKey(const Key('wanted-enter')));

      final router = ProviderScope.containerOf(
        tester.element(find.byType(MusubiApp)),
      ).read(routerProvider);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '${AppRoutes.signIn}?${AppRoutes.returnParam}=%2Fse-busca',
      );
    });
  });
}
