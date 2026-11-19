import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';

import '../../test/integration/support/live_api.dart';
import '../support/device_app.dart';

/// `Publicar`, `Vender-1…4`, `Vender-listo` y `Mis-productos` en el telefono
/// (HU-06, HU-08), con la moderacion del texto (02-07).
void sellFlow() {
  Future<void> fillSell(DeviceApp app, String title) async {
    await app.tapText('Publicar');
    await app.tapKey('publish-sell');
    await app.tapKey('sell-camera');
    await app.tapText('Continuar');
    await app.type('sell-title', title);
    await app.type('sell-description', 'La usé un semestre.');
    await app.tapText('Continuar');
    await app.type('sell-price', '450');
    await app.tapKey('sell-category-calculadoras');
    await app.tapText('Continuar');
    await app.tapKey('sell-publish');
  }

  testWidgets('publicar con foto y verlo en Mis productos', (tester) async {
    final valeria = await liveUser(name: 'Valeria Integración');
    addTearDown(valeria.dispose);
    final title = 'Calculadora ${DateTime.now().millisecondsSinceEpoch}';
    final app = await DeviceApp.open(
      tester,
      tokens: valeria.signedIn.tokens,
      at: AppRoutes.home,
    );

    await fillSell(app, title);
    await app.see('¡Tu producto ya está publicado!');
    await app.tapText('Ver mis productos');
    await app.see('Mis productos');

    final mine = await valeria.read(listingsRepositoryProvider).mine();
    expect(mine.map((l) => l.product.title), contains(title));
  });

  testWidgets('un nombre inapropiado no se publica', (tester) async {
    final valeria = await liveUser(name: 'Valeria Integración');
    addTearDown(valeria.dispose);
    final app = await DeviceApp.open(
      tester,
      tokens: valeria.signedIn.tokens,
      at: AppRoutes.home,
    );

    await fillSell(app, 'Vendo esto [[inapropiado]]');
    await app.settle(const Duration(seconds: 2));

    expect(find.text('¡Tu producto ya está publicado!'), findsNothing);
    expect(find.byKey(const Key('sell-publish')), findsOneWidget);
    expect(await valeria.read(listingsRepositoryProvider).mine(), isEmpty);
  });
}
