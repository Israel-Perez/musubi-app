@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_share.dart';
import 'package:musubi_app/features/marketplace/presentation/comparison_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/saved_search_providers.dart';
import 'package:musubi_app/features/recommendations/presentation/recommendation_providers.dart';

import 'support/live_api.dart';
import 'support/live_flows.dart';

/// Pantallas `Inicio`, `Buscar`, `Recientes`, `Producto`, `Perfil-vendedor`,
/// `Favoritos` y `Busquedas-guardadas` contra la API real (HU-09, HU-10,
/// HU-11, HU-12, HU-35, HU-48, HU-49, HU-51).
void main() {
  group('Explorar contra la API real', skip: liveSkip, () {
    test(
      'inicio, busqueda, recientes, detalle y publicaciones de quien vende',
      () async {
        final valeria = await liveUser(name: 'Valeria Integración');
        final ana = await liveUser();
        addTearDown(valeria.dispose);
        addTearDown(ana.dispose);
        final word = 'Kalimba${DateTime.now().microsecondsSinceEpoch}';
        final product = await publishProduct(
          valeria,
          title: '$word de 17 notas',
        );
        final catalog = ana.read(catalogRepositoryProvider);

        final home = await catalog.homeFeed(period: PopularPeriod.week);
        final found = await catalog.search(query: word);
        final recent = await catalog.recentProducts();
        final categories = await catalog.categories();
        final detail = await catalog.product(product.id);
        final seller = await catalog.sellerListings(valeria.user.id);

        expect(home.categories, isNotEmpty);
        expect(found.items.map((p) => p.id), contains(product.id));
        expect(recent.items.map((p) => p.id), contains(product.id));
        expect(categories, isNotEmpty);
        expect((detail.id, detail.sellerId), (product.id, valeria.user.id));
        expect(seller.items.map((p) => p.id), contains(product.id));
      },
    );

    test('compartir (HU-61): el enlace lleva lo que ve un visitante', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      addTearDown(valeria.dispose);
      final visitor = LiveSession.visitor();
      addTearDown(visitor.dispose);
      final product = await publishProduct(
        valeria,
        title: 'Calculadora para compartir',
      );
      final mine = await valeria
          .read(catalogRepositoryProvider)
          .product(product.id);

      final shared = ProductShare.of(mine);
      // La landing (worker de /p/{id}) lee el mismo detalle sin sesion.
      final preview = await visitor
          .read(catalogRepositoryProvider)
          .product(product.id);

      expect(ProductShare.canShare(mine), isTrue);
      expect(shared.text, contains('Calculadora para compartir'));
      expect(shared.text, endsWith('https://musubiapp.com.mx/p/${product.id}'));
      expect(shared.text, isNot(contains(valeria.user.id)));
      expect(preview.title, 'Calculadora para compartir');
      expect(preview.priceCents, mine.priceCents);
      expect(preview.sellerId, isNull);

      // Pausada: el enlace dice "Ya no está disponible" (404 sin sesion).
      final paused = await valeria
          .read(listingsRepositoryProvider)
          .pause(product.id);
      expect(paused.status, isNot(ListingStatus.active));
      await expectLater(
        visitor.read(catalogRepositoryProvider).product(product.id),
        throwsA(isA<ApiFailure>().having((f) => f.status, 'status', 404)),
      );
    });

    test('un visitante explora sin cuenta', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      addTearDown(valeria.dispose);
      final visitor = LiveSession.visitor();
      addTearDown(visitor.dispose);
      final product = await publishProduct(
        valeria,
        title: 'Audífonos inalámbricos',
      );
      final catalog = visitor.read(catalogRepositoryProvider);

      final home = await catalog.homeFeed(period: PopularPeriod.today);
      final detail = await catalog.product(product.id);

      expect(home.categories, isNotEmpty);
      expect(detail.title, 'Audífonos inalámbricos');
      // Sin cuenta no se ve quien vende.
      expect(detail.sellerName, isNull);
    });

    test('favoritos: agregar, listar y quitar', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(
        valeria,
        title: 'Mochila para laptop',
      );
      final favorites = ana.read(favoritesRepositoryProvider);

      await favorites.add(product.id);
      final listed = await favorites.list();
      await favorites.remove(product.id);

      expect(listed.items.map((f) => f.productId), contains(product.id));
      expect((await favorites.list()).items, isEmpty);
    });

    test('comparar opciones y "Avisame" en una agotada', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final diego = await liveUser(name: 'Diego Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(diego.dispose);
      addTearDown(ana.dispose);
      final casio = await publishProduct(
        valeria,
        title: 'Calculadora Casio 991ES',
      );
      final other = await publishProduct(
        diego,
        title: 'Calculadora Casio 991ES Plus',
      );
      await valeria.read(listingsRepositoryProvider).setStock(casio.id, 0);
      final comparison = ana.read(comparisonRepositoryProvider);

      final options = await comparison.compare(other.id);
      final before = await comparison.stockAlert(casio.id);
      await comparison.watch(casio.id);
      final watching = await comparison.stockAlert(casio.id);
      await comparison.unwatch(casio.id);

      expect(options, isA<List<Object>>());
      expect(before, isFalse);
      expect(watching, isTrue);
      expect(await comparison.stockAlert(casio.id), isFalse);
    });

    test('busqueda guardada: guardar, listar y quitar', () async {
      final ana = await liveUser();
      addTearDown(ana.dispose);
      final searches = ana.read(savedSearchRepositoryProvider);

      final saved = await searches.save(query: 'microscopio');
      final mine = await searches.mine();
      await searches.remove(saved.search.id);

      expect(saved.created, isTrue);
      expect(mine.map((s) => s.id), contains(saved.search.id));
      expect(await searches.mine(), isEmpty);
    });

    test('recomendado para ti y ver parecidos', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(
        valeria,
        title: 'Tablet Samsung Galaxy',
      );
      final recommendations = ana.read(recommendationRepositoryProvider);

      final forYou = await recommendations.forYou(limit: 10);
      final similar = await recommendations.similar(product.id, limit: 5);

      expect(forYou.items, isA<List<Object>>());
      expect(similar.items.map((p) => p.id), isNot(contains(product.id)));
    });
  });
}
