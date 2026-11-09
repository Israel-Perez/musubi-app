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
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/fake_wanted.dart';
import '../../helpers/in_memory_token_store.dart';

// Martes 10 de noviembre de 2026, mediodia.
final _now = DateTime(2026, 11, 10, 12);

/// Dos publicaciones del campus parecidas a lo que se busca.
const _matches = ProductPage(
  items: [
    ProductSummary(
      id: 'p1',
      title: 'Casio fx-991ES Plus',
      priceCents: 45000,
      stock: 1,
      condition: 'Usado',
      sellerName: 'Valeria C.',
    ),
    ProductSummary(
      id: 'p2',
      title: 'Casio fx-991LA X',
      priceCents: 70000,
      stock: 1,
      condition: 'Nuevo',
      sellerName: 'Luis M.',
    ),
  ],
  total: 2,
);

/// App completa con el router real, la sesion abierta y las solicitudes
/// falsas (HU-13).
class NeedHarness {
  new(this.tester, {FakeWantedRepository? wanted})
    : wanted = wanted ?? FakeWantedRepository();

  final WidgetTester tester;
  final FakeWantedRepository wanted;

  Future<void> open(String location) async {
    // Telefono de la maqueta: 390 x 844.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = chatTokens(_now.toUtc());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([const HomeFeed()], [_matches]),
          ),
          listingsRepositoryProvider.overrideWithValue(
            FakeListingsRepository(
              range: const PriceRange(lowCents: 38000, highCents: 58000),
            ),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          wantedRepositoryProvider.overrideWithValue(wanted),
        ],
        child: const MusubiApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(MusubiApp)))
        .read(routerProvider)
        .go(location);
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> type(String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
    'Necesidad-1…3: señala lo que falta, publica y muestra lo que coincide',
    (tester) async {
      final h = NeedHarness(tester);
      await h.open(AppRoutes.need);

      expect(find.text('Publicar lo que necesito'), findsOneWidget);
      expect(find.text('ASÍ FUNCIONA'), findsOneWidget);
      expect(find.text('PASO 1 DE 3 · PRODUCTO'), findsOneWidget);

      // Sin datos: señala el producto y la categoria.
      await h.tap(find.byKey(const Key('need-continue')));
      expect(
        find.text('Escribe qué buscas, con al menos 3 letras.'),
        findsOneWidget,
      );
      expect(find.text('Elige una categoría.'), findsOneWidget);

      await h.type('need-title', 'Calculadora Casio fx-991ES Plus');
      await h.tap(find.byKey(const Key('need-category-calculadoras')));
      expect(find.text('Otro'), findsOneWidget);
      expect(
        find.text(
          'Ya hay 2 publicaciones parecidas. Te las mostramos al publicar.',
        ),
        findsOneWidget,
      );
      await h.tap(find.byKey(const Key('need-continue')));

      // Paso 2: descripcion y caracteristicas.
      expect(find.text('Cuéntanos más'), findsOneWidget);
      await h.type('need-description', 'Para Cálculo Integral.');
      expect(find.text('22 / 300'), findsOneWidget);
      await h.type('need-feature', 'Con tapa');
      await h.tap(find.byKey(const Key('need-feature-add')));
      expect(find.text('Con tapa'), findsOneWidget);
      await h.tap(find.byKey(const Key('need-details-continue')));

      // Paso 3: sin presupuesto no publica.
      expect(find.text('¿Cuánto y para cuándo?'), findsOneWidget);
      await h.tap(find.byKey(const Key('need-publish')));
      expect(
        find.text('Indica cuánto quieres pagar como máximo.'),
        findsOneWidget,
      );
      expect(h.wanted.published, isEmpty);

      await h.type('need-budget', '600');
      expect(
        find.text(r'Buen presupuesto: en Musubi se venden entre $380 y $580.'),
        findsOneWidget,
      );
      await h.tap(find.byKey(const Key('need-quantity-1')));
      await h.tap(find.byKey(const Key('need-when-friday')));
      expect(find.text('Vie 13 nov'), findsOneWidget);
      expect(find.text('vie 13 nov · 2 piezas'), findsOneWidget);
      expect(find.text('Calculadoras · Ana R.'), findsOneWidget);

      await h.tap(find.byKey(const Key('need-publish')));

      final sent = h.wanted.published.single;
      expect(sent.toJson(), {
        'title': 'Calculadora Casio fx-991ES Plus',
        'category': 'calculadoras',
        'description': 'Para Cálculo Integral.',
        'features': ['Con tapa'],
        'budgetCents': 60000,
        'quantity': 2,
        'neededBy': '2026-11-13',
      });

      // Necesidad-publicada: lo que cabe en el presupuesto primero.
      expect(find.text('¡Tu solicitud está publicada!'), findsOneWidget);
      expect(find.text('Activa'), findsOneWidget);
      // La cantidad elegida se ve en el boleto publicado.
      expect(find.text('vie 13 nov · 2 piezas'), findsOneWidget);
      expect(find.text('Ya coinciden con lo que buscas'), findsOneWidget);
      expect(find.text('Dentro de tu presupuesto'), findsOneWidget);
      expect(find.text('Arriba de tu presupuesto'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Casio fx-991ES Plus · Usado')).dy,
        lessThan(tester.getTopLeft(find.text('Casio fx-991LA X · Nuevo')).dy),
      );

      await h.tap(find.byKey(const Key('need-see-mine')));
      expect(find.text('Mis solicitudes'), findsOneWidget);
      expect(find.text('Activas (1)'), findsOneWidget);
      expect(find.text('Calculadora Casio fx-991ES Plus'), findsOneWidget);
      expect(find.text('Aún no hay ofertas'), findsOneWidget);
      expect(find.text('2 piezas'), findsOneWidget);

      // Sin nada atras, "Regresar" lleva a Perfil.
      await h.tap(find.bySemanticsLabel('Regresar'));
      expect(find.text('Mis solicitudes'), findsOneWidget);
      expect(find.byKey(const Key('tile-my-wanted')), findsOneWidget);
    },
  );

  testWidgets('si la API rechaza, avisa y no sale del paso 3', (tester) async {
    final h = NeedHarness(
      tester,
      wanted: FakeWantedRepository(
        publishFailure: const ApiFailure(
          code: 'wanted.too_many_active',
          message:
              'Ya tienes 5 solicitudes activas. Espera a que alguna termine '
              'para publicar otra.',
          status: 409,
        ),
      ),
    );
    await h.open(AppRoutes.need);
    await h.type('need-title', 'Bata de laboratorio');
    await h.tap(find.byKey(const Key('need-category-otro')));
    await h.tap(find.byKey(const Key('need-continue')));
    await h.tap(find.byKey(const Key('need-details-continue')));
    await h.type('need-budget', '250');

    await h.tap(find.byKey(const Key('need-publish')));

    expect(
      find.text(
        'Ya tienes 5 solicitudes activas. Espera a que alguna termine para '
        'publicar otra.',
      ),
      findsOneWidget,
    );
    expect(find.text('¿Cuánto y para cuándo?'), findsOneWidget);
  });

  testWidgets('Elegir fecha ofrece las fechas de la maqueta', (tester) async {
    final h = NeedHarness(tester);
    await h.open(AppRoutes.need);
    await h.type('need-title', 'Bata de laboratorio');
    await h.tap(find.byKey(const Key('need-category-otro')));
    await h.tap(find.byKey(const Key('need-continue')));
    await h.tap(find.byKey(const Key('need-details-continue')));
    await h.type('need-budget', '250');

    await h.tap(find.byKey(const Key('need-when-date')));
    for (final label in [
      'Lunes 16 de noviembre',
      'Miércoles 18 de noviembre',
      'Viernes 20 de noviembre',
      'Lunes 23 de noviembre',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Miércoles 18 de noviembre'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Mié 18 nov'), findsOneWidget);
    await h.tap(find.byKey(const Key('need-publish')));
    expect(h.wanted.published.single.toJson()['neededBy'], '2026-11-18');
  });

  testWidgets('Mis solicitudes: pestañas, Cambiar y vencidas', (tester) async {
    final h = NeedHarness(
      tester,
      wanted: FakeWantedRepository(
        mine: [
          sampleWanted(offers: 3, neededBy: DateTime(2026, 11, 13)),
          sampleWanted(id: 'w2', title: 'Bata de laboratorio talla M'),
          sampleWanted(
            id: 'w3',
            title: 'Libro de Física',
            status: WantedStatus.expired,
          ),
        ],
      ),
    );
    await h.open(AppRoutes.myWanted);

    expect(find.text('Activas (2)'), findsOneWidget);
    expect(find.text('Cerradas (1)'), findsOneWidget);
    expect(find.text('3 ofertas'), findsOneWidget);
    expect(find.text('vie 13 nov'), findsOneWidget);
    // Una pieza es lo normal: no se dice.
    expect(find.text('1 pieza'), findsNothing);

    await h.tap(find.byKey(const Key('my-wanted-change-button')));
    await h.tap(find.text('Bata de laboratorio talla M').last);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Bata de laboratorio talla M'), findsOneWidget);
    expect(find.text('0 ofertas'), findsOneWidget);

    await h.tap(find.byKey(const Key('my-wanted-tab-closed')));
    expect(find.text('Libro de Física'), findsOneWidget);
    expect(find.text('Vencida'), findsOneWidget);
    expect(find.text('Sin ofertas'), findsOneWidget);
  });

  testWidgets('sin solicitudes invita a publicar', (tester) async {
    final h = NeedHarness(tester);
    await h.open(AppRoutes.myWanted);

    expect(find.text('Activas (0)'), findsOneWidget);
    await h.tap(find.byKey(const Key('my-wanted-empty-new')));
    expect(find.text('¿Qué estás buscando?'), findsOneWidget);
  });

  testWidgets('Perfil muestra Mis solicitudes con activas y ofertas', (
    tester,
  ) async {
    final h = NeedHarness(
      tester,
      wanted: FakeWantedRepository(
        mine: [
          sampleWanted(offers: 3),
          sampleWanted(id: 'w2'),
          sampleWanted(id: 'w3', status: WantedStatus.closed),
        ],
      ),
    );
    await h.open(AppRoutes.profile);

    expect(find.text('Mis solicitudes'), findsOneWidget);
    expect(find.text('2 activas · 3 ofertas'), findsOneWidget);
    await h.tap(find.byKey(const Key('tile-my-wanted')));
    expect(find.text('Activas (2)'), findsOneWidget);

    await h.tap(find.bySemanticsLabel('Regresar'));
    expect(find.text('2 activas · 3 ofertas'), findsOneWidget);
  });
}
