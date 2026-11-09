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
import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
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

/// Mis publicaciones de la maqueta (`Yo-tengo-vincular`).
const _mine = [
  OwnListing(
    product: ProductSummary(
      id: 'p-bata',
      title: 'Bata de laboratorio blanca, talla M',
      priceCents: 25000,
      stock: 1,
      condition: 'Usado',
    ),
    status: ListingStatus.active,
  ),
  OwnListing(
    product: ProductSummary(
      id: 'p-stewart',
      title: 'Cálculo de una variable, Stewart',
      priceCents: 38000,
      stock: 1,
      condition: 'Usado',
    ),
    status: ListingStatus.active,
  ),
  OwnListing(
    product: ProductSummary(
      id: 'p-pausada',
      title: 'Lámpara de escritorio',
      priceCents: 15000,
      stock: 1,
      condition: 'Usado',
    ),
    status: ListingStatus.hidden,
  ),
];

/// App completa con el tablero y mis publicaciones falsas (HU-16).
class OfferHarness {
  new(this.tester, {FakeWantedRepository? wanted, List<OwnListing>? mine})
    : wanted =
          wanted ??
          FakeWantedRepository(
            board: [boardWanted(neededBy: DateTime(2026, 11, 9))],
          ),
      listings = FakeListingsRepository()..own = mine ?? _mine;

  final WidgetTester tester;
  final FakeWantedRepository wanted;
  final FakeListingsRepository listings;

  Future<void> open() async {
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
            FakeCatalogRepository([const HomeFeed()]),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          wantedRepositoryProvider.overrideWithValue(wanted),
          listingsRepositoryProvider.overrideWithValue(listings),
          photoPickerProvider.overrideWithValue(FakePhotoPicker()),
        ],
        child: const MusubiApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(MusubiApp)))
        .read(routerProvider)
        .go(AppRoutes.wanted);
    await tester.pumpAndSettle();
    await tap(find.text('Yo tengo este producto').first);
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  Future<void> type(String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pumpAndSettle();
  }

  ProviderContainer get container =>
      ProviderScope.containerOf(tester.element(find.byType(MusubiApp)));
}

void main() {
  testWidgets('Vincular publicación: elige, escribe y envia', (tester) async {
    final h = OfferHarness(tester);
    await h.open();

    expect(find.text('Fernanda busca'), findsOneWidget);
    expect(find.text(r'Hasta $300'), findsOneWidget);
    expect(find.text('Vincular publicación'), findsOneWidget);
    expect(
      find.text(
        'Elige una de tus publicaciones. Fernanda verá la foto, el precio y '
        'tu reputación.',
      ),
      findsOneWidget,
    );
    // Solo las disponibles.
    expect(find.text('Bata de laboratorio blanca, talla M'), findsOneWidget);
    expect(find.text('Lámpara de escritorio'), findsNothing);
    expect(find.text('Mensaje para Fernanda'), findsOneWidget);

    await h.tap(find.byKey(const ValueKey('offer-listing-p-stewart')));
    await h.type('offer-message', '¡Hola! Te lo llevo.');
    await h.tap(find.byKey(const Key('offer-send')));

    final (requestId, sent) = h.wanted.sentOffers.single;
    expect(requestId, 'r-bata');
    expect(
      (sent.productId, sent.message),
      ('p-stewart', '¡Hola! Te lo llevo.'),
    );
    expect(find.text('¡Oferta enviada!'), findsOneWidget);
    expect(
      find.text(
        'Le avisamos a Fernanda. Si le interesa, te escribirá por el chat y '
        'te avisaremos.',
      ),
      findsOneWidget,
    );
    expect(find.text('Vinculada a tu publicación'), findsOneWidget);

    await h.tap(find.byKey(const Key('offer-sent-close')));
    expect(find.byKey(const Key('offer-sent')), findsNothing);
    expect(find.text('Fernanda Ortiz'), findsOneWidget);
  });

  testWidgets('sin publicaciones solo hay oferta directa; avisa el '
      'presupuesto y pide lo que falta', (tester) async {
    final h = OfferHarness(tester, mine: const []);
    await h.open();

    expect(find.byKey(const Key('offer-tabs')), findsNothing);
    expect(
      find.text(
        '¿No lo has publicado? No pasa nada. Esta oferta solo la verá '
        'Fernanda.',
      ),
      findsOneWidget,
    );

    await h.tap(find.byKey(const Key('offer-send')));
    expect(h.wanted.sentOffers, isEmpty);

    await h.type('offer-description', 'Bata blanca de algodón, talla M');
    await h.type('offer-price', '350');
    expect(find.text(r'Está arriba de su presupuesto ($300)'), findsOneWidget);
    await h.type('offer-price', '280');
    expect(find.text(r'Está dentro de su presupuesto ($300)'), findsOneWidget);
    await h.tap(find.byKey(const ValueKey('segment-new')));
    await h.tap(find.byKey(const Key('offer-photo')));
    await h.tap(find.text('Elegir de la galería'));
    expect(h.listings.uploaded, hasLength(1));

    await h.tap(find.byKey(const Key('offer-send')));

    final sent = h.wanted.sentOffers.single.$2;
    expect(
      (sent.productId, sent.description, sent.priceCents, sent.condition),
      (null, 'Bata blanca de algodón, talla M', 28000, 'new'),
    );
    expect(sent.photoKey, 'media/products/u1/1.webp');
    expect(find.text('Oferta directa'), findsOneWidget);
    expect(find.text(r'$280'), findsOneWidget);
  });

  testWidgets('con una oferta ya enviada la abre para editarla (RN-14)', (
    tester,
  ) async {
    final wanted = FakeWantedRepository(
      board: [boardWanted(neededBy: DateTime(2026, 11, 9))],
    );
    wanted.offers['r-bata'] = const WantedOffer(
      id: 'o1',
      requestId: 'r-bata',
      kind: OfferKind.direct,
      title: 'Bata talla M, como nueva',
      priceCents: 26000,
      condition: 'new',
      photoKey: 'media/products/u1/foto.webp',
    );
    final h = OfferHarness(tester, wanted: wanted);
    await h.open();

    expect(find.text('Actualizar oferta'), findsOneWidget);
    expect(find.text('Bata talla M, como nueva'), findsOneWidget);
    expect(find.text('260'), findsOneWidget);

    await h.tap(find.byKey(const Key('offer-send')));

    final sent = h.wanted.sentOffers.single.$2;
    expect((sent.priceCents, sent.condition), (26000, 'new'));
    // La foto que ya tenia se conserva.
    expect(sent.photoKey, 'media/products/u1/foto.webp');
  });

  testWidgets('una oferta ya rechazada no se puede cambiar (HU-17)', (
    tester,
  ) async {
    final wanted = FakeWantedRepository(
      board: [boardWanted(neededBy: DateTime(2026, 11, 9))],
    );
    wanted.offers['r-bata'] = const WantedOffer(
      id: 'o1',
      requestId: 'r-bata',
      kind: OfferKind.direct,
      title: 'Bata talla M',
      priceCents: 26000,
      condition: 'used',
      status: OfferStatus.rejected,
    );
    final h = OfferHarness(tester, wanted: wanted);
    await h.open();

    expect(find.text('Fernanda rechazó tu oferta'), findsOneWidget);
    await h.tap(find.byKey(const Key('offer-send')));
    expect(h.wanted.sentOffers, isEmpty);
  });

  testWidgets('si la API rechaza, avisa y la hoja sigue abierta', (
    tester,
  ) async {
    final h = OfferHarness(
      tester,
      wanted:
          FakeWantedRepository(
              board: [boardWanted(neededBy: DateTime(2026, 11, 9))],
            )
            ..offerFailure = const ApiFailure(
              code: 'moderation.text_rejected',
              message: 'Revisa el mensaje: no lo pudimos publicar.',
            ),
    );
    await h.open();

    await h.tap(find.byKey(const Key('offer-send')));

    expect(
      find.text('Revisa el mensaje: no lo pudimos publicar.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('offer-send')), findsOneWidget);
  });

  testWidgets('Ir a mensajes lleva a la bandeja', (tester) async {
    final h = OfferHarness(tester);
    await h.open();

    await h.tap(find.byKey(const Key('offer-send')));
    await h.tap(find.byKey(const Key('offer-sent-messages')));

    expect(
      h.container.read(routerProvider).routeInformationProvider.value.uri.path,
      AppRoutes.messages,
    );
  });
}
