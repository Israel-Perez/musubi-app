@Tags(['integration'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/offline_cache.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/storage/local_store.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/comparison_providers.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/seller_support/presentation/seller_support_providers.dart';

import 'support/live_api.dart';
import 'support/live_flows.dart';

/// Pantallas `Vender-1…4`, `Vender-listo`, `Mis-productos` y `Editar` contra
/// la API real (HU-06, HU-07, HU-08, HU-50), con el apoyo a vendedores
/// (HU-36, HU-37, HU-38), el precio sugerido (HU-58), "Llenar con IA"
/// (HU-59) y la moderacion del texto (02-07).
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

    test('Llenar con IA (HU-59): la portada propone el borrador; solo la '
        'mia', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final listings = valeria.read(listingsRepositoryProvider);
      final cover = await listings.uploadPhoto(livePhoto().path);

      final proposal = await listings.draftFromPhoto(cover.key);
      final categories = await listings.categories();
      final theirs = await ana
          .read(listingsRepositoryProvider)
          .draftFromPhoto(cover.key)
          .then<ApiFailure?>(
            (_) => null,
            onError: (Object e) => e as ApiFailure,
          );

      // La API local usa la IA en memoria (determinista, sin Gemini).
      expect(proposal.title.length, inInclusiveRange(3, 80));
      expect(proposal.description, isNotEmpty);
      expect(categories.map((c) => c.slug), contains(proposal.category));
      expect(proposal.condition, ProductCondition.used);
      expect(proposal.usedDetail, isNotNull);
      // RN-38: nada se publico; con lo que propuso, y el precio, se publica.
      expect(await listings.mine(), isEmpty);
      final published = await listings.publish(
        NewListing(
          title: proposal.title,
          description: proposal.description,
          category: proposal.category!,
          priceCents: 30000,
          condition: proposal.condition,
          usedDetail: proposal.usedDetail,
          quantity: 1,
          photoKeys: [cover.key],
        ),
      );
      expect(published.title, proposal.title);
      // OWASP API1: la foto de Valeria no le sirve a nadie mas.
      expect(theirs?.code, 'listings.photo_not_found');
    });

    test('sin conexion se ve lo ultimo que cargo (HU-63, L-16h)', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      addTearDown(valeria.dispose);
      final product = await publishProduct(valeria, title: 'Calculadora Casio');
      // Con red: "Mis productos" y "Mis pedidos" llegan y se guardan.
      final online = await valeria
          .read(listingsRepositoryProvider)
          .minePage(MyProductsTab.active);
      await valeria.read(orderRepositoryProvider).mine(tab: MyOrdersTab.active);

      // El mismo telefono sin red: la misma sesion y la misma base local, con
      // la API apagada.
      final phone = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.parse(
              environment: 'dev',
              apiBaseUrl: 'http://localhost:9',
            ),
          ),
          tokenStoreProvider.overrideWithValue(valeria.store),
          initialSessionTokensProvider.overrideWithValue(valeria.store.saved),
          localStoreProvider.overrideWithValue(valeria.local),
        ],
      );
      addTearDown(phone.dispose);
      final offlinePage = await phone
          .read(listingsRepositoryProvider)
          .minePage(MyProductsTab.active);
      final orders = await phone
          .read(orderRepositoryProvider)
          .mine(tab: MyOrdersTab.active);
      // La revalidacion en segundo plano no llega: "Sin conexión" (en Windows
      // un puerto cerrado tarda ~2 s en rechazar la conexion).
      for (var i = 0; i < 100 && !phone.read(offlineProvider); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(online.items.map((l) => l.product.id), contains(product.id));
      expect(offlinePage.items.map((l) => l.product.id), contains(product.id));
      expect(orders.items, isEmpty);
      expect(phone.read(offlineProvider), isTrue);
      // Lo sensible nunca se escribe en el telefono.
      expect(
        valeria.local.responses.values.any((b) => b.contains('accessToken')),
        isFalse,
      );
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
