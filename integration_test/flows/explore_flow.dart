import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/orders/domain/reservation_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

import '../../test/integration/support/live_api.dart';
import '../../test/integration/support/live_flows.dart';
import '../support/device_app.dart';

/// `Buscar`, `Producto`, `Chat` y `Apartar` / `Apartado-listo` en el telefono
/// (HU-09, HU-11, HU-20, HU-52). Quien vende se prepara por la API.
void exploreFlow() {
  testWidgets('buscar, abrir el producto y escribirle a quien vende', (
    tester,
  ) async {
    final valeria = await liveUser(name: 'Valeria Integración');
    final ana = await liveUser();
    addTearDown(valeria.dispose);
    addTearDown(ana.dispose);
    final word = 'Kalimba${DateTime.now().millisecondsSinceEpoch}';
    final product = await publishProduct(valeria, title: '$word de 17 notas');
    final app = await DeviceApp.open(
      tester,
      tokens: ana.signedIn.tokens,
      at: AppRoutes.search,
    );

    await app.type('search-input', word);
    await app.submit();
    await app.tapText(product.title);
    await app.tapLabel('Enviar mensaje');
    await app.type('chat-input', '¿Sigue disponible?');
    await app.tapLabel('Enviar');
    await app.see('¿Sigue disponible?');

    final inbox = await valeria.read(chatRepositoryProvider).inbox();
    expect(inbox.items, isNotEmpty);
  });

  testWidgets('apartar 24 h y que quien vende entregue con el codigo', (
    tester,
  ) async {
    final valeria = await liveUser(name: 'Valeria Integración');
    final luis = await liveUser(name: 'Luis Integración');
    addTearDown(valeria.dispose);
    addTearDown(luis.dispose);
    final product = await publishProduct(valeria, title: 'Juego de escuadras');
    final app = await DeviceApp.open(
      tester,
      tokens: luis.signedIn.tokens,
      at: AppRoutes.product(product.id),
    );

    await app.tapText('Apartar');
    await app.tapKey('reserve-confirm');
    await app.waitFor(find.byKey(const Key('reservation-qr')));

    // Quien vende escanea o escribe el codigo (aqui, por la API).
    final mine = await luis
        .read(reservationRepositoryProvider)
        .mine(ReservationTab.buyer);
    final reservation = mine.items.single;
    final seller = valeria.read(reservationRepositoryProvider);
    await seller.verify(reservation.id, reservation.code!);
    final collected = await seller.complete(reservation.id);

    expect(collected.status, ReservationStatus.collected);
  });
}
