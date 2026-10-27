import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';

import '../../helpers/fake_listings_repository.dart';

// HU-06: el borrador de `Vender-1…4`.
void main() {
  ProviderContainer container0() => ProviderContainer.test(
    overrides: [
      listingsRepositoryProvider.overrideWithValue(FakeListingsRepository()),
    ],
  );

  test('hasta 8 fotos: las de mas no entran', () {
    final container = container0();
    final draft = container.read(sellDraftProvider.notifier);

    final added = draft.addPhotos([for (var i = 0; i < 10; i++) 'f$i.jpg']);

    expect(added, 8);
    expect(container.read(sellDraftProvider).room, 0);
  });

  test('reordenar cambia la portada', () {
    final container = container0();
    final draft = container.read(sellDraftProvider.notifier)
      ..addPhotos(['a.jpg', 'b.jpg', 'c.jpg'])
      ..movePhoto(2, 0);

    expect(container.read(sellDraftProvider).photos.map((p) => p.path), [
      'c.jpg',
      'a.jpg',
      'b.jpg',
    ]);
    draft.movePhoto(0, 2);
    expect(container.read(sellDraftProvider).photos.first.path, 'a.jpg');
  });

  test('piezas de 1 a 10 y la etiqueta de la vista previa', () {
    final container = container0();
    final draft = container.read(sellDraftProvider.notifier)..step(-1);
    expect(container.read(sellDraftProvider).quantity, 1);

    for (var i = 0; i < 12; i++) {
      draft.step(1);
    }
    expect(container.read(sellDraftProvider).quantity, 10);
    expect(
      container.read(sellDraftProvider).summaryLabel,
      'Usado · Como nuevo · 10 disponibles',
    );
    draft.setCondition(ProductCondition.brandNew);
    expect(
      container.read(sellDraftProvider).summaryLabel,
      'Nuevo · Sin usar · 10 disponibles',
    );
  });

  test('Vender un producto empieza de cero salvo con borrador guardado', () {
    final container = container0();
    final draft = container.read(sellDraftProvider.notifier)
      ..setTitle('Bata de laboratorio')
      ..start();
    expect(container.read(sellDraftProvider).title, '');

    draft
      ..setTitle('Bata de laboratorio')
      ..save()
      ..start();
    expect(container.read(sellDraftProvider).title, 'Bata de laboratorio');
  });
}
