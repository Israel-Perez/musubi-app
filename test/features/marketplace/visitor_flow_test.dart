import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/shell/musubi_bottom_bar.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/fake_status_repository.dart';
import '../../helpers/in_memory_token_store.dart';

/// App completa (router real) para HU-48: modo visitante.
class Harness {
  new(this.tester, {FakeCatalogRepository? catalog, this.initial})
    : catalog = catalog ?? FakeCatalogRepository();

  final WidgetTester tester;
  final FakeCatalogRepository catalog;
  final SessionTokens? initial;
  final auth = FakeAuthRepository();
  late final store = InMemoryTokenStore(initial);
  late ProviderContainer container;

  Future<void> open() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(catalog),
          authRepositoryProvider.overrideWithValue(auth),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => auth.now),
          statusRepositoryProvider.overrideWithValue(
            FakeStatusRepository([const ApiOnline(version: 'v1')]),
          ),
          tokenStoreProvider.overrideWithValue(store),
          initialSessionTokensProvider.overrideWithValue(initial),
        ],
        child: const MusubiApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    await tester.pumpAndSettle();
  }

  Finder tab(String label) => find.descendant(
    of: find.byType(MusubiBottomBar),
    matching: find.bySemanticsLabel(label),
  );

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder.first);
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(String text) => tap(find.text(text));

  String get location => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  bool get signedIn => container.read(sessionControllerProvider) is SignedIn;
}

// HU-48: la app abre en la vitrina; las acciones de miembro piden la cuenta
// sin salir de la pantalla y, al terminar, se vuelve a donde estabas.
void main() {
  group('vitrina', () {
    testWidgets('abre directo en Inicio con el encabezado de la maqueta', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open();

      expect(h.location, AppRoutes.home);
      expect(find.text('Musubi'), findsOneWidget);
      expect(find.text('UTTT'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Populares'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Semana'), findsOneWidget);
      await tester.scrollUntilVisible(
        scrollable: find.byType(Scrollable).first,

        find.byKey(const Key('home-join-banner')),
        300,
      );
      expect(find.text('La UTTT ya está en Musubi'), findsOneWidget);
    });

    testWidgets('sin publicaciones: estados vacios con su accion', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open();

      expect(find.byKey(const Key('home-empty-products')), findsOneWidget);
      expect(find.byKey(const Key('home-empty-wanted')), findsOneWidget);
      expect(find.text('Todavía no hay publicaciones en la UTTT'), findsOne);
    });

    testWidgets('cargando: la forma de la vitrina (Inicio-cargando)', (
      tester,
    ) async {
      final h = Harness(tester, catalog: FakeCatalogRepository.pending());
      await h.tester.pumpWidget(const SizedBox());
      await h.open();

      expect(find.byKey(const Key('home-loading')), findsOneWidget);
      expect(find.bySemanticsLabel('Cargando publicaciones…'), findsOneWidget);
    });

    testWidgets('sin red: Inicio-error y Reintentar vuelve a pedir', (
      tester,
    ) async {
      final catalog = FakeCatalogRepository([offlineFailure, sampleFeed]);
      final h = Harness(tester, catalog: catalog);
      await h.open();

      expect(find.text('Sin conexión a internet'), findsOneWidget);
      expect(find.text('No pudimos cargar las publicaciones'), findsOneWidget);

      await h.tapText('Reintentar');

      expect(find.byKey(const Key('home-error')), findsNothing);
      expect(find.text('Calculadora Casio fx-991ES'), findsOneWidget);
    });

    testWidgets('con datos: populares con su lugar, agotados y Se busca', (
      tester,
    ) async {
      final h = Harness(tester, catalog: FakeCatalogRepository([sampleFeed]));
      await h.open();

      expect(find.text('128 vistas'), findsOneWidget);
      expect(find.text('Quedan 2'), findsOneWidget);
      expect(find.text('Último'), findsOneWidget);
      expect(find.text(r'$11,800'), findsOneWidget);
      await tester.scrollUntilVisible(
        scrollable: find.byType(Scrollable).first,
        find.text('Recién publicados'),
        200,
      );
      await tester.scrollUntilVisible(
        scrollable: find.byType(Scrollable).first,
        find.text('Agotado'),
        200,
      );
      expect(find.text('Agotado'), findsOneWidget);
      await tester.scrollUntilVisible(
        scrollable: find.byType(Scrollable).first,
        find.text('PAGA HASTA'),
        200,
      );
      expect(find.text(r'$300'), findsOneWidget);
      expect(find.text('lun 5 oct'), findsOneWidget);
    });

    testWidgets('Hoy / Semana cambia el periodo de Populares', (tester) async {
      final h = Harness(tester);
      await h.open();

      await h.tapText('Semana');

      expect(h.catalog.periods, [PopularPeriod.today, PopularPeriod.week]);
    });

    testWidgets('con sesion: sin Entrar ni banner de bienvenida', (
      tester,
    ) async {
      final h = Harness(tester, initial: testTokens());
      await h.open();

      expect(find.text('Entrar'), findsNothing);
      expect(find.byKey(const Key('home-join-banner')), findsNothing);
    });
  });

  group('Crea tu cuenta', () {
    testWidgets('guardar, ofrecer y pedir abren su hoja sin navegar', (
      tester,
    ) async {
      final h = Harness(tester, catalog: FakeCatalogRepository([sampleFeed]));
      await h.open();

      await h.tap(find.byType(SaveButton));
      expect(find.text('Crea tu cuenta para guardar'), findsOneWidget);
      expect(h.location, AppRoutes.home);
      await h.tapText('Seguir explorando');
      expect(find.text('Crea tu cuenta para guardar'), findsNothing);

      // El boton vive en una fila horizontal: se baja la vista vertical hasta
      // dejarlo completo en pantalla (ensureVisible moveria la horizontal).
      await tester.dragUntilVisible(
        find.text('Yo tengo este producto'),
        find.byType(Scrollable).first,
        const Offset(0, -150),
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yo tengo este producto'));
      await tester.pumpAndSettle();
      expect(find.text('Crea tu cuenta para ofrecerlo'), findsOneWidget);
    });

    testWidgets('Mensajes y Publicar no navegan: piden la cuenta', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open();

      await h.tap(h.tab('Mensajes'));
      expect(find.text('Aquí verás tus mensajes'), findsOneWidget);
      await h.tapText('Seguir explorando');

      await h.tap(find.byTooltip('Publicar'));
      expect(find.text('Crea tu cuenta para publicar'), findsOneWidget);
      expect(h.location, AppRoutes.home);
    });

    testWidgets('Ya tengo cuenta: al entrar vuelve a donde estaba', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open();
      await h.tap(h.tab('Se busca'));
      expect(h.location, AppRoutes.wanted);

      await h.tap(h.tab('Perfil'));
      await h.tapText('Ya tengo cuenta');
      expect(find.text('Hola de nuevo'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('signin-email')),
        FakeAuthRepository.activeEmail,
      );
      await tester.enterText(
        find.byKey(const Key('signin-password')),
        FakeAuthRepository.activePassword,
      );
      await tester.pump();
      await h.tap(find.byType(FilledButton).last);

      expect(h.signedIn, isTrue);
      expect(h.location, AppRoutes.wanted);
    });

    testWidgets('Crear cuenta: tras la bienvenida vuelve a donde estaba', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open();
      await h.tap(h.tab('Se busca'));

      await h.tap(h.tab('Mensajes'));
      await h.tapText('Crear cuenta');
      expect(find.text('Crea tu cuenta'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('signup-email')),
        'ana.ramirez@uttt.edu.mx',
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('signup-name')),
        'Ana Sofía Ramírez',
      );
      await tester.enterText(
        find.byKey(const Key('signup-password')),
        'musubi2026',
      );
      await tester.pump();
      await h.tap(find.byKey(const Key('signup-consent')));
      await h.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.enterText(
        find.byKey(const Key('verification-code')),
        FakeAuthRepository.validCode,
      );
      await tester.pump();
      await h.tapText('Verificar correo');
      await h.tapText('Empezar a explorar');

      expect(h.signedIn, isTrue);
      expect(h.location, AppRoutes.wanted);
    });

    testWidgets('el chip del campus explica la UTTT al visitante', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open();

      await h.tap(find.byKey(const Key('campus-chip')));

      expect(find.text('Estás explorando la UTTT'), findsOneWidget);
      expect(find.text('Al entrar, vuelves justo aquí.'), findsOneWidget);
    });

    testWidgets('Entrar lleva a iniciar sesion y regresa a Inicio', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open();

      await h.tapText('Entrar');
      expect(find.text('Hola de nuevo'), findsOneWidget);
      expect(h.location, contains('desde=%2F'));
    });

    testWidgets('las 9 hojas de la maqueta tienen su titulo y su texto', (
      tester,
    ) async {
      for (final motive in AccountGateMotive.values) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AccountGateSheet(motive: motive, returnTo: '/'),
              ),
            ),
          ),
        );
        expect(find.text(motive.title), findsOneWidget, reason: motive.name);
        expect(find.text(motive.message), findsOneWidget, reason: motive.name);
        expect(
          find.text('Solo necesitas tu correo de la universidad'),
          findsOneWidget,
        );
      }
    });
  });
}
