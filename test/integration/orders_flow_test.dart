@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/domain/reservation_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';

import 'support/live_api.dart';
import 'support/live_flows.dart';

/// CLABE de BBVA Mexico con su digito verificador (de prueba).
const _clabe = '012180015488214829';

/// Pantallas `Pedido-pago`, `Pago-transferencia`, `Pago-validando`,
/// `Pago-vendedor`, `Pedido-entrega`, `Pedido-efectivo`, `Mis-pedidos`,
/// `Ventas`, `Calificar`, `Cuenta-pagos` y los apartados (`Apartado-listo`,
/// `Mis-apartados`, `Verificar-comprador`) contra la API real (HU-23, HU-24,
/// HU-25, HU-26, HU-27, HU-45, HU-52, HU-55 y "Ya llegué" de HU-62).
void main() {
  group('Pedidos contra la API real', skip: liveSkip, () {
    test('pedido, entrega de las dos partes y calificaciones', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(valeria, title: 'Calculadora Casio');
      final conversation = await openChat(ana, product.id);
      final order = await placeOrder(ana, conversation.id);
      final buyer = ana.read(orderRepositoryProvider);
      final seller = valeria.read(orderRepositoryProvider);

      final inChat = await buyer.byConversation(conversation.id);
      await buyer.payCash(order.id);
      final accepted = await seller.accept(order.id);
      await seller.confirmHandover(order.id);
      final completed = await buyer.confirmHandover(order.id);
      await ana
          .read(reputationRepositoryProvider)
          .rate(
            order.id,
            const NewRating(
              stars: 5,
              tags: [RatingTag.onTime],
              comment: 'Muy puntual.',
            ),
          );
      await valeria
          .read(reputationRepositoryProvider)
          .rate(
            order.id,
            const NewRating(stars: 4, tags: [RatingTag.paidAsAgreed]),
          );
      final opinions = await ana
          .read(reputationRepositoryProvider)
          .opinions(valeria.user.id);
      final mine = await buyer.mine(tab: MyOrdersTab.completed);
      final sales = await seller.sales();

      expect(inChat.map((o) => o.id), contains(order.id));
      expect(accepted.status, OrderStatus.confirmed);
      expect(completed.status, OrderStatus.completed);
      expect(opinions.items, isNotEmpty);
      expect(mine.items.map((o) => o.id), contains(order.id));
      expect(sales.items.map((o) => o.id), contains(order.id));
    });

    test('Ya llegué: antes de 2 horas la API lo rechaza (HU-62)', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(valeria, title: 'Escuadras');
      final order = await placeOrder(ana, (await openChat(ana, product.id)).id);
      final buyer = ana.read(orderRepositoryProvider);
      await buyer.payCash(order.id);
      final accepted = await valeria
          .read(orderRepositoryProvider)
          .accept(order.id);

      // La entrega es mañana a la 1:00 p. m.: todavía falta.
      final early = await buyer
          .arrived(order.id)
          .then<ApiFailure?>(
            (_) => null,
            onError: (Object e) => e as ApiFailure,
          );

      expect(accepted.status, OrderStatus.confirmed);
      expect(accepted.canSayArrived(DateTime.now()), isFalse);
      expect(early?.code, 'orders.arrival_too_early');
      expect(early?.message, startsWith('Todavía falta para la entrega'));
    });

    test('en efectivo: el codigo de 4 digitos completa el pedido', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(valeria, title: 'Audífonos');
      final order = await placeOrder(ana, (await openChat(ana, product.id)).id);
      final buyer = ana.read(orderRepositoryProvider);
      final seller = valeria.read(orderRepositoryProvider);

      await buyer.payCash(order.id);
      await seller.accept(order.id);
      final code = (await buyer.get(order.id)).deliveryCode!;
      final wrong = seller.deliveryCode(
        order.id,
        code == '0000' ? '1111' : '0000',
      );
      await expectLater(
        wrong,
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'orders.invalid_code',
          ),
        ),
      );
      final completed = await seller.deliveryCode(order.id, code);

      expect(code, matches(RegExp(r'^\d{4}$')));
      expect(completed.status, OrderStatus.completed);
    });

    test(
      'por transferencia: cuenta, referencia, "no me llega" y "si me llego"',
      () async {
        final valeria = await liveUser(name: 'Valeria Integración');
        final ana = await liveUser();
        addTearDown(valeria.dispose);
        addTearDown(ana.dispose);
        final payouts = valeria.read(payoutRepositoryProvider);
        final banks = await payouts.banks();
        final account = await payouts.save(
          holderName: 'Valeria Integración',
          clabe: _clabe,
        );
        final status = await payouts.mine();
        final product = await publishProduct(valeria, title: 'Tablet Samsung');
        final order = await placeOrder(
          ana,
          (await openChat(ana, product.id)).id,
        );
        final buyer = ana.read(orderRepositoryProvider);
        final seller = valeria.read(orderRepositoryProvider);

        await buyer.payTransfer(order.id);
        final details = await buyer.transfer(order.id);
        await buyer.reportTransfer(order.id, '4829173');
        await seller.transferNotReceived(order.id);
        await buyer.reportTransfer(order.id, '4829174');
        final confirmed = await seller.accept(order.id);
        await payouts.remove();

        expect(banks.map((b) => b.code), contains('012'));
        expect(account.clabeLast4, '4829');
        expect(status.account?.bankName, 'BBVA México');
        expect(details.clabe.replaceAll(' ', ''), _clabe);
        expect(confirmed.status, OrderStatus.confirmed);
        expect((await payouts.mine()).account, isNull);
      },
    );

    test('cancelar un pedido con su motivo', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(valeria, title: 'Mochila');
      final order = await placeOrder(ana, (await openChat(ana, product.id)).id);

      final cancelled = await ana
          .read(orderRepositoryProvider)
          .cancel(order.id, CancelReason.changedMind);

      expect(cancelled.status, OrderStatus.cancelled);
    });

    test('apartar, verificar el codigo y entregar', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final luis = await liveUser(name: 'Luis Integración');
      addTearDown(valeria.dispose);
      addTearDown(luis.dispose);
      final product = await publishProduct(
        valeria,
        title: 'Juego de escuadras',
      );
      final points = await luis.read(orderRepositoryProvider).meetingPoints();
      final buyer = luis.read(reservationRepositoryProvider);
      final seller = valeria.read(reservationRepositoryProvider);

      final reservation = await buyer.create(
        productId: product.id,
        meetingPoint: points.first.slug,
        pickupAt: pickupSlot(),
      );
      final bought = await buyer.mine(ReservationTab.buyer);
      final sold = await seller.mine(ReservationTab.seller);
      final forSeller = await seller.get(reservation.id);
      final verified = await seller.verify(reservation.id, reservation.code!);
      final collected = await seller.complete(reservation.id);

      expect(reservation.code, matches(RegExp(r'^\d{6}$')));
      expect(bought.items.map((r) => r.id), contains(reservation.id));
      expect(sold.items.map((r) => r.id), contains(reservation.id));
      expect(forSeller.code, isNull);
      expect(verified.verifiedAt, isNotNull);
      expect(collected.status, ReservationStatus.collected);
    });

    test('cancelar un apartado regresa la pieza', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final luis = await liveUser(name: 'Luis Integración');
      addTearDown(valeria.dispose);
      addTearDown(luis.dispose);
      final product = await publishProduct(
        valeria,
        title: 'Bata de laboratorio',
      );
      final points = await luis.read(orderRepositoryProvider).meetingPoints();
      final reservations = luis.read(reservationRepositoryProvider);
      final reservation = await reservations.create(
        productId: product.id,
        meetingPoint: points.first.slug,
        pickupAt: pickupSlot(),
      );

      final cancelled = await reservations.cancel(reservation.id);

      expect(cancelled.status, ReservationStatus.cancelled);
    });
  });
}
