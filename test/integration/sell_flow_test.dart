@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/comparison_providers.dart';
import 'package:musubi_app/features/seller_support/presentation/seller_support_providers.dart';

import 'support/live_api.dart';
import 'support/live_flows.dart';

/// Pantallas `Vender-1…4`, `Vender-listo`, `Mis-productos` y `Editar` contra
/// la API real (HU-06, HU-07, HU-08, HU-50), con el apoyo a vendedores
/// (HU-36, HU-37, HU-38), el precio sugerido (HU-58) y la moderacion del
/// texto (02-07).
void main() {
  group('Vender contra la API real', skip: liveSkip, () {
    test('publicar con foto, editar, pausar, reanudar y piezas', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      addTearDown(valeria.dispose);
      final listings = valeria.read(listingsRepositoryProvider);

      final categories = await listings.categories();
      final range = await listings.priceRange('calculadoras');
      final product = await publishProduct(
        valeria,
        title: 'Calculadora Casio fx-991',
      );
      final edited = await listings.update(
        product.id,
        const ListingUpdate(
          title: 'Calculadora Casio fx-991ES Plus',
          description: 'Con funda y manual.',
          category: 'calculadoras',
          priceCents: 42000,
          condition: ProductCondition.used,
          usedDetail: UsedDetail.likeNew,
        ),
      );
      final paused = await listings.pause(product.id);
      final resumed = await listings.resume(product.id);
      final stocked = await listings.setStock(product.id, 3);
      final mine = await listings.mine();
      final page = await listings.minePage(MyProductsTab.active);

      expect(categories.map((c) => c.slug), contains('calculadoras'));
      expect(range == null || range.lowCents <= range.highCents, isTrue);
      expect(edited.product.title, 'Calculadora Casio fx-991ES Plus');
      expect(paused.status, isNot(ListingStatus.active));
      expect(resumed.status, ListingStatus.active);
      expect(stocked.product.stock, 3);
      expect(mine.map((l) => l.product.id), contains(product.id));
      expect(page.items.map((l) => l.product.id), contains(product.id));
    });

    test('precio sugerido y estimación del modelo de ML (HU-58)', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(valeria, title: 'Calculadora Casio');

      final suggestion = await valeria
          .read(listingsRepositoryProvider)
          .suggestPrice((
            title: 'Calculadora Casio fx-991ES Plus',
            category: 'calculadoras',
            condition: ProductCondition.used,
            usedDetail: UsedDetail.good,
          ));
      final estimate = await ana
          .read(comparisonRepositoryProvider)
          .estimate(product.id);
      final invalid = await valeria
          .read(listingsRepositoryProvider)
          .suggestPrice((
            title: 'ab',
            category: 'calculadoras',
            condition: ProductCondition.used,
            usedDetail: UsedDetail.good,
          ))
          .then<ApiFailure?>(
            (_) => null,
            onError: (Object e) => e as ApiFailure,
          );

      // La API local empieza vacía: con menos de 20 precios del campus no
      // sugiere (sin inventar); con más, el rango es de pesos redondos.
      if (suggestion != null) {
        expect(suggestion.minCents, lessThan(suggestion.maxCents));
        expect(suggestion.samples, greaterThanOrEqualTo(5));
      }
      if (estimate != null) {
        expect(estimate.minCents, lessThan(estimate.maxCents));
      }
      expect(invalid?.code, 'recommendations.invalid_price_request');
    });

    test('marcar como vendido y eliminar', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      addTearDown(valeria.dispose);
      final listings = valeria.read(listingsRepositoryProvider);
      final sold = await publishProduct(
        valeria,
        title: 'Bata de laboratorio M',
      );
      final removed = await publishProduct(
        valeria,
        title: 'Juego de escuadras',
      );

      final marked = await listings.markSold(sold.id);
      await listings.delete(removed.id);
      final soldTab = await listings.minePage(MyProductsTab.sold);
      final mine = await listings.mine();

      expect(marked.status, ListingStatus.sold);
      expect(soldTab.items.map((l) => l.product.id), contains(sold.id));
      expect(mine.map((l) => l.product.id), isNot(contains(removed.id)));
    });

    test('un texto inapropiado no se publica', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      addTearDown(valeria.dispose);

      await expectLater(
        publishProduct(valeria, title: 'Vendo esto [[inapropiado]]'),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'moderation.text_rejected',
          ),
        ),
      );
    });

    test('apoyo a vendedores: sin vender, quienes la buscan e ideas', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      addTearDown(valeria.dispose);
      final support = valeria.read(sellerSupportRepositoryProvider);
      final product = await publishProduct(valeria, title: 'Calculadora Casio');

      final slow = await support.slow();
      final demand = await support.demand(product.id);
      final ideas = await support.ideas(product.id);

      // Recien publicada: todavia no "lleva tiempo sin venderse" (21 dias).
      expect(
        slow.items.map((s) => s.listing.product.id),
        isNot(contains(product.id)),
      );
      expect(demand.people, greaterThanOrEqualTo(0));
      expect(ideas.title, isNotEmpty);
    });
  });
}
