@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_board.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

import 'support/live_api.dart';
import 'support/live_flows.dart';

const _coat = NewWanted(
  title: 'Bata de laboratorio talla M',
  category: 'laboratorio',
  budgetCents: 30000,
  quantity: 1,
);

/// Pantallas `Necesidad-1…3`, `Se-busca`, `Mis-solicitudes`, `Yo-tengo` y
/// ofertas recibidas contra la API real (HU-13, HU-14, HU-15, HU-16, HU-17,
/// HU-18, HU-19).
void main() {
  group('Se busca contra la API real', skip: liveSkip, () {
    test('publicar, verla en el tablero, editar y cancelar', () async {
      final fernanda = await liveUser(name: 'Fernanda Integración');
      final ana = await liveUser();
      addTearDown(fernanda.dispose);
      addTearDown(ana.dispose);
      final wanted = fernanda.read(wantedRepositoryProvider);

      final request = await wanted.publish(_coat);
      final board = await ana
          .read(wantedRepositoryProvider)
          .board(filter: const WantedBoardFilter(query: 'bata'));
      final seen = await ana.read(wantedRepositoryProvider).get(request.id);
      final edited = await wanted.update(
        request.id,
        const NewWanted(
          title: 'Bata de laboratorio talla M',
          category: 'laboratorio',
          budgetCents: 32000,
          quantity: 1,
          description: 'Blanca, de algodón.',
        ),
      );
      final mine = await wanted.mine();
      final cancelled = await wanted.cancel(request.id);

      expect(board.items.map((r) => r.id), contains(request.id));
      expect(seen.title, 'Bata de laboratorio talla M');
      expect(edited.budgetCents, 32000);
      expect(mine.map((r) => r.id), contains(request.id));
      expect(cancelled.status, WantedStatus.cancelled);
    });

    test(
      'ofertas: directa y con una publicacion; rechazar, chatear, aceptar',
      () async {
        final fernanda = await liveUser(name: 'Fernanda Integración');
        final valeria = await liveUser(name: 'Valeria Integración');
        final diego = await liveUser(name: 'Diego Integración');
        addTearDown(fernanda.dispose);
        addTearDown(valeria.dispose);
        addTearDown(diego.dispose);
        final request = await fernanda
            .read(wantedRepositoryProvider)
            .publish(_coat);
        final listed = await publishProduct(
          diego,
          title: 'Bata de laboratorio talla M',
          category: 'laboratorio',
          priceCents: 25000,
        );
        final fromValeria = valeria.read(wantedRepositoryProvider);
        final fromDiego = diego.read(wantedRepositoryProvider);
        final requester = fernanda.read(wantedRepositoryProvider);

        final none = await fromValeria.myOffer(request.id);
        final direct = await fromValeria.sendOffer(
          request.id,
          const NewOffer.direct(
            description: 'Bata blanca de algodón',
            priceCents: 28000,
            condition: 'used',
            message: 'Te la llevo a la biblioteca.',
          ),
        );
        final withListing = await fromDiego.sendOffer(
          request.id,
          NewOffer.listing(productId: listed.id),
        );
        final mine = await fromValeria.myOffer(request.id);
        final received = await requester.receivedOffers(request.id);
        final matches = await requester.matches(request.id);
        await requester.rejectOffer(request.id, withListing.id);
        final chat = await requester.offerChat(request.id, direct.id);
        final accepted = await requester.acceptOffer(request.id, direct.id);
        final closed = await requester.close(request.id);

        expect(none, isNull);
        expect(mine?.id, direct.id);
        expect(
          received.map((o) => o.id),
          containsAll([direct.id, withListing.id]),
        );
        expect(matches, isA<List<Object>>());
        expect(chat, isNotEmpty);
        expect(accepted, chat);
        expect(closed.status, WantedStatus.closed);
      },
    );
  });
}
