import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/recent_products_provider.dart';

import '../../helpers/fake_catalog_repository.dart';

void main() {
  ProductSummary product(String id) =>
      ProductSummary(id: id, title: 'Producto $id', priceCents: 100, stock: 1);

  test('carga más antiguas por cursor y descarta duplicados', () async {
    final repository = FakeCatalogRepository(const [], const [], [
      ProductPage(items: [product('p1')], total: 3, nextCursor: 'cursor-1'),
      ProductPage(
        items: [product('p1'), product('p2')],
        total: 3,
        nextCursor: 'cursor-2',
      ),
      ProductPage(items: [product('p3')], total: 3),
    ]);
    final container = ProviderContainer.test(
      overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
    );

    await container.read(recentProductsProvider.future);
    await container.read(recentProductsProvider.notifier).loadMore();
    await container.read(recentProductsProvider.notifier).loadMore();
    final result = container.read(recentProductsProvider).requireValue;

    expect(repository.recentCursors, [null, 'cursor-1', 'cursor-2']);
    expect(result.items.map((item) => item.id), ['p1', 'p2', 'p3']);
    expect(result.hasMore, isFalse);
  });
}
