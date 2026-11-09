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
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_screen.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/received_offers.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/fake_wanted.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime(2026, 11, 9, 12);

/// Las ofertas de la maqueta (`Mis-solicitudes`): Diego con mejor
/// reputacion y Valeria con menor precio.
final List<ReceivedOffer> _offers = [
  ReceivedOffer(
    id: 'o-valeria',
    kind: OfferKind.listing,
    productId: 'p1',
    title: 'Calculadora Casio fx-991ES Plus',
    priceCents: 45000,
    condition: 'used',
    conditionDetail: 'fair',
    message: 'Funciona bien, tiene un rayón en la tapa.',
    offerer: const Offerer(
      id: 'u-valeria',
      name: 'Valeria Cruz',
      career: 'Arquitectura',
      ratingAvg: 4.6,
      ratingCount: 18,
    ),
    createdAt: DateTime.utc(2026, 11, 9, 17),
  ),
  ReceivedOffer(
    id: 'o-diego',
    kind: OfferKind.direct,
    title: 'Casio fx-991ES Plus con tapa',
    priceCents: 50000,
    condition: 'used',
    message: 'La usé un semestre, incluye tapa y pilas nuevas.',
    offerer: const Offerer(
      id: 'u-diego',
      name: 'Diego Hernández',
      career: 'Ing. Civil',
      ratingAvg: 4.9,
      ratingCount: 32,
    ),
    createdAt: DateTime.utc(2026, 11, 9, 16),
  ),
];

/// La conversacion que abre una oferta (HU-17).
const _offerConversation = Conversation(
  id: 'c-o-valeria',
  role: ChatRole.buyer,
  counterpart: ChatCounterpart(id: 'u-valeria', name: 'Valeria Cruz'),
  context: ChatContext(
    id: 'o-valeria',
    title: 'Calculadora Casio fx-991ES Plus',
    available: true,
    type: 'offer',
  ),
);

class OffersHarness {
  new(this.tester, {List<ReceivedOffer>? offers})
    : wanted = FakeWantedRepository(mine: [sampleWanted(offers: 2)])
        ..received['w1'] = offers ?? _offers;

  final WidgetTester tester;
  final FakeWantedRepository wanted;
  final chat = FakeChatRepository(conversationValue: _offerConversation);

  Future<void> open() async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = chatTokens(_now.toUtc());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([const HomeFeed()]),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(chat),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          wantedRepositoryProvider.overrideWithValue(wanted),
        ],
        child: const MusubiApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(MusubiApp)))
        .read(routerProvider)
        .go(AppRoutes.myWanted);
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  /// El chat abierto encima, o `null`.
  String? get openChat {
    final screens = tester.widgetList<ChatScreen>(find.byType(ChatScreen));
    return screens.isEmpty ? null : screens.last.target.conversationId;
  }
}

void main() {
  group('ordenar (HU-17)', () {
    test(
      'recomendadas: en el presupuesto, mejor reputacion y menor precio',
      () {
        final over = ReceivedOffer(
          id: 'o-caro',
          kind: OfferKind.direct,
          title: 'Otra',
          priceCents: 70000,
          condition: 'new',
          offerer: const Offerer(
            id: 'u-x',
            name: 'Luis Martínez',
            ratingAvg: 5,
            ratingCount: 3,
          ),
          createdAt: DateTime.utc(2026, 11, 9),
        );
        final offers = [..._offers, over];

        List<String> ids(OfferSort sort) => [
          for (final o in sortOffers(offers, sort, 60000)) o.id,
        ];

        expect(ids(OfferSort.recommended), ['o-diego', 'o-valeria', 'o-caro']);
        expect(ids(OfferSort.price), ['o-valeria', 'o-diego', 'o-caro']);
        expect(ids(OfferSort.reputation), ['o-caro', 'o-diego', 'o-valeria']);
      },
    );
  });

  testWidgets('Compara las ofertas con su reputacion, presupuesto y '
      'etiquetas', (tester) async {
    final h = OffersHarness(tester);
    await h.open();

    expect(find.text('Compara las ofertas'), findsOneWidget);
    expect(find.text('Diego Hernández'), findsOneWidget);
    expect(find.text('(32) · Ing. Civil'), findsOneWidget);
    expect(find.text('Mejor reputación'), findsOneWidget);
    expect(find.text('Menor precio'), findsOneWidget);
    expect(find.text(r'$100 bajo tu presupuesto'), findsOneWidget);
    expect(
      find.text('“La usé un semestre, incluye tapa y pilas nuevas.”'),
      findsOneWidget,
    );
    expect(find.text('Usado · Oferta directa'), findsOneWidget);
    expect(find.text('Usado · con detalles · Su publicación'), findsOneWidget);
    expect(find.text('Recomendadas'), findsOneWidget);
  });

  testWidgets('Rechazar pide confirmacion, se puede deshacer y despues se '
      'envia', (tester) async {
    final h = OffersHarness(tester);
    await h.open();

    await h.tap(find.byKey(const ValueKey('offer-reject-o-diego')));
    expect(find.text('¿Rechazar la oferta de Diego?'), findsOneWidget);
    await h.tap(find.byKey(const Key('offer-reject-confirm')));

    expect(find.text('Diego Hernández'), findsNothing);
    expect(find.text('Rechazaste la oferta de Diego'), findsOneWidget);
    await h.tap(find.text('Deshacer'));
    expect(find.text('Diego Hernández'), findsOneWidget);

    await h.tap(find.byKey(const ValueKey('offer-reject-o-diego')));
    await h.tap(find.byKey(const Key('offer-reject-confirm')));
    await tester.pump(
      ReceivedOffersSection.undoWindow + const Duration(milliseconds: 100),
    );
    await tester.pumpAndSettle();

    expect(h.wanted.decisions, [('reject', 'w1', 'o-diego')]);
  });

  testWidgets('rechazar todas deja el aviso de la maqueta', (tester) async {
    final h = OffersHarness(tester, offers: [_offers.last]);
    await h.open();

    await h.tap(find.byKey(const ValueKey('offer-reject-o-diego')));
    await h.tap(find.byKey(const Key('offer-reject-confirm')));

    expect(find.byKey(const Key('offers-all-rejected')), findsOneWidget);
    await tester.pump(
      ReceivedOffersSection.undoWindow + const Duration(milliseconds: 100),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('Aceptar confirma y abre el chat con el saludo escrito', (
    tester,
  ) async {
    final h = OffersHarness(tester);
    await h.open();

    await h.tap(find.byKey(const ValueKey('offer-accept-o-valeria')));
    expect(find.text('¿Aceptar la oferta de Valeria?'), findsOneWidget);
    await h.tap(find.byKey(const Key('offer-accept-confirm')));

    expect(h.wanted.decisions, [('accept', 'w1', 'o-valeria')]);
    expect(h.openChat, 'c-o-valeria');
    expect(
      find.text(
        r'¡Hola, Valeria! Acepto tu oferta de $450. ¿Cuándo nos vemos?',
      ),
      findsOneWidget,
    );
    // El contexto es la oferta: sin "Ver".
    expect(find.text('OFERTA DE VALERIA · SE BUSCA'), findsOneWidget);
    expect(find.text('Respondió a tu solicitud'), findsOneWidget);
    expect(find.text('Ver'), findsNothing);
  });

  testWidgets('Abrir chat no decide', (tester) async {
    final h = OffersHarness(tester);
    await h.open();

    await h.tap(find.byKey(const ValueKey('offer-chat-o-diego')));

    expect(h.wanted.decisions, [('chat', 'w1', 'o-diego')]);
    expect(h.openChat, 'c-o-diego');
  });

  testWidgets('Ordenar por menor precio', (tester) async {
    final h = OffersHarness(tester);
    await h.open();

    await h.tap(find.byKey(const Key('offer-sort-button')));
    expect(find.text('Ordenar ofertas'), findsOneWidget);
    await h.tap(find.byKey(const ValueKey('option-OfferSort.price')));

    final valeria = tester.getTopLeft(find.text('Valeria Cruz')).dy;
    final diego = tester.getTopLeft(find.text('Diego Hernández')).dy;
    expect(valeria, lessThan(diego));
    expect(find.text('Menor precio'), findsWidgets);
  });

  testWidgets('una oferta aceptada ya no se rechaza ni se acepta', (
    tester,
  ) async {
    final accepted = ReceivedOffer(
      id: 'o-ok',
      kind: OfferKind.direct,
      title: 'Bata blanca',
      priceCents: 28000,
      condition: 'used',
      status: OfferStatus.accepted,
      offerer: const Offerer(id: 'u-ok', name: 'Valeria Cruz'),
      createdAt: DateTime.utc(2026, 11, 9),
    );
    final h = OffersHarness(tester, offers: [accepted]);
    await h.open();

    expect(find.text('Aceptada'), findsOneWidget);
    expect(find.text('Sin calificaciones'), findsOneWidget);
    expect(find.byKey(const ValueKey('offer-reject-o-ok')), findsNothing);
    expect(find.byKey(const ValueKey('offer-accept-o-ok')), findsNothing);
    expect(find.byKey(const ValueKey('offer-chat-o-ok')), findsOneWidget);
  });

  testWidgets('si aceptar falla, avisa y no abre el chat', (tester) async {
    final h = OffersHarness(tester);
    h.wanted.decisionFailure = const ApiFailure(
      code: 'offers.request_closed',
      message: 'Tu solicitud ya no está activa.',
    );
    await h.open();

    await h.tap(find.byKey(const ValueKey('offer-accept-o-valeria')));
    await h.tap(find.byKey(const Key('offer-accept-confirm')));

    expect(find.text('Tu solicitud ya no está activa.'), findsOneWidget);
    expect(h.openChat, isNull);
  });
}
