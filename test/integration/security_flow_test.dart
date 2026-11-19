@Tags(['integration', 'security'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';

import 'support/live_api.dart';
import 'support/live_flows.dart';

Matcher _failsWith(int status) =>
    throwsA(isA<ApiFailure>().having((f) => f.status, 'status', status));

/// Seguridad de la sesion de la app contra la API real (02-10, MASVS-AUTH y
/// OWASP API1/API2): un token cerrado no vuelve a servir, un visitante no
/// entra a lo privado y nadie lee el pedido o el apartado de otra persona.
void main() {
  group('Seguridad contra la API real', skip: liveSkip, () {
    test(
      'cerrar sesion: el access token viejo ya no sirve en la API',
      () async {
        final ana = await liveUser();
        addTearDown(ana.dispose);
        final stolen = ana.signedIn.tokens;

        await ana.read(sessionControllerProvider.notifier).logOut();
        // Alguien copio los tokens antes del logout y los usa en otro telefono.
        final thief = LiveSession.visitor();
        addTearDown(thief.dispose);
        await thief.read(sessionControllerProvider.notifier).signIn(stolen);

        await expectLater(
          thief.read(profileRepositoryProvider).me(),
          _failsWith(401),
        );
        // El refresh token tambien se revoco: la app cierra esa sesion.
        expect(thief.read(sessionControllerProvider), isA<Visitor>());
        expect(thief.store.saved, isNull);
      },
    );

    test('un token alterado se rechaza y la sesion termina', () async {
      final ana = await liveUser();
      addTearDown(ana.dispose);
      final real = ana.signedIn.tokens;
      final parts = real.accessToken.split('.');
      final tampered = SessionTokens(
        accessToken: '${parts[0]}.${parts[1]}x.${parts[2]}',
        accessExpiresAt: real.accessExpiresAt,
        refreshToken: 'no-es-un-refresh-token',
      );
      final phone = LiveSession.visitor();
      addTearDown(phone.dispose);
      await phone.read(sessionControllerProvider.notifier).signIn(tampered);

      await expectLater(
        phone.read(profileRepositoryProvider).me(),
        _failsWith(401),
      );
      expect(phone.read(sessionControllerProvider), isA<Visitor>());
    });

    test('un visitante no entra a lo que pide sesion', () async {
      final visitor = LiveSession.visitor();
      addTearDown(visitor.dispose);

      await expectLater(
        visitor.read(favoritesRepositoryProvider).list(),
        _failsWith(401),
      );
      await expectLater(
        visitor.read(profileRepositoryProvider).me(),
        _failsWith(401),
      );
    });

    test('nadie lee el pedido ni el apartado de otra persona', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      final outsider = await liveUser(name: 'Otra Persona');
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      addTearDown(outsider.dispose);
      final product = await publishProduct(valeria, title: 'Calculadora Casio');
      final order = await placeOrder(ana, (await openChat(ana, product.id)).id);
      final reserved = await publishProduct(valeria, title: 'Bata talla M');
      final points = await ana.read(orderRepositoryProvider).meetingPoints();
      final reservation = await ana
          .read(reservationRepositoryProvider)
          .create(
            productId: reserved.id,
            meetingPoint: points.first.slug,
            pickupAt: tomorrowAtOne(),
          );

      // Ajeno es como inexistente: 404, sin decir que existe (OWASP API1).
      await expectLater(
        outsider.read(orderRepositoryProvider).get(order.id),
        _failsWith(404),
      );
      await expectLater(
        outsider.read(reservationRepositoryProvider).get(reservation.id),
        _failsWith(404),
      );
      await expectLater(
        outsider.read(orderRepositoryProvider).accept(order.id),
        _failsWith(404),
      );
    });
  });
}
