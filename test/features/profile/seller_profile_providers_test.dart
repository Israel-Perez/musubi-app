import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_profile_repository.dart';

// HU-05: el perfil público y sus publicaciones activas viven en providers
// compartidos; el error no se convierte en null para que la pantalla decida.
void main() {
  final ana = PublicProfile(
    id: 'ana',
    fullName: 'Ana Sofía Ramírez',
    campusShortName: 'UTTT',
    memberSince: DateTime.utc(2025, 2),
    careerShortName: 'Ing. Mecatrónica',
    term: 7,
    ratingAvg: 4.6,
    ratingCount: 18,
    sales: 15,
  );

  ProviderContainer containerFor({
    FakeProfileRepository? profiles,
    FakeCatalogRepository? catalog,
  }) {
    final container =
        ProviderContainer.test(
            overrides: [
              profileRepositoryProvider.overrideWithValue(
                profiles ?? FakeProfileRepository(),
              ),
              catalogRepositoryProvider.overrideWithValue(
                catalog ?? FakeCatalogRepository(),
              ),
            ],
          )
          // autoDispose: el listener lo mantiene vivo durante la prueba.
          ..listen(publicProfileProvider('ana'), (_, _) {})
          ..listen(sellerListingsProvider('ana'), (_, _) {});
    return container;
  }

  test('publicProfileProvider carga el perfil público', () async {
    final profiles = FakeProfileRepository()..publicProfiles['ana'] = ana;
    final container = containerFor(profiles: profiles);

    final profile = await container.read(publicProfileProvider('ana').future);

    expect(profile.fullName, 'Ana Sofía Ramírez');
    expect(profile.campusShortName, 'UTTT');
    expect(profile.careerShortName, 'Ing. Mecatrónica');
    expect(profile.term, 7);
    expect(profile.ratingAvg, 4.6);
  });

  test('publicProfileProvider deja el error y se reintenta', () async {
    final profiles = FakeProfileRepository()
      ..publicProfiles['ana'] = ana
      ..failPublicProfile = true;
    final container = containerFor(profiles: profiles);

    await expectLater(
      container.read(publicProfileProvider('ana').future),
      throwsA(isA<ApiFailure>()),
    );
    expect(
      container.read(publicProfileProvider('ana')),
      isA<AsyncError<PublicProfile>>(),
    );

    profiles.failPublicProfile = false;
    container.invalidate(publicProfileProvider('ana'));

    expect(
      (await container.read(publicProfileProvider('ana').future)).fullName,
      'Ana Sofía Ramírez',
    );
  });

  test(
    'sellerListingsProvider pide la primera página de esa persona',
    () async {
      final catalog = FakeCatalogRepository()
        ..sellerListingsResponse = const ProductPage(
          items: [
            ProductSummary(
              id: 'p1',
              title: 'Calculadora',
              priceCents: 45000,
              stock: 1,
            ),
          ],
          total: 3,
          nextCursor: 'next',
        );
      final container = containerFor(catalog: catalog);

      final page = await container.read(sellerListingsProvider('ana').future);

      expect(page.items.single.title, 'Calculadora');
      expect(page.total, 3);
      expect(page.nextCursor, 'next');
      expect(catalog.sellerIds, ['ana']);
      expect(catalog.sellerPages, [1]);
    },
  );

  test('sellerListingsProvider deja el error y se reintenta', () async {
    final catalog = FakeCatalogRepository()..failSellerListings = true;
    final container = containerFor(catalog: catalog);

    await expectLater(
      container.read(sellerListingsProvider('ana').future),
      throwsA(isA<ApiFailure>()),
    );
    expect(
      container.read(sellerListingsProvider('ana')),
      isA<AsyncError<ProductPage>>(),
    );

    catalog
      ..failSellerListings = false
      ..sellerListingsResponse = const ProductPage(total: 1);
    container.invalidate(sellerListingsProvider('ana'));

    expect(
      (await container.read(sellerListingsProvider('ana').future)).total,
      1,
    );
  });
}
