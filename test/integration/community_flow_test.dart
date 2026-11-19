@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';
import 'package:musubi_app/features/notifications/presentation/notification_providers.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';

import 'support/live_api.dart';
import 'support/live_flows.dart';

/// Pantallas `Avisos`, `Reportar` y `Usuarios-bloqueados` contra la API real
/// (HU-28, HU-31, HU-57).
void main() {
  group('Avisos y reputacion contra la API real', skip: liveSkip, () {
    test(
      'avisos: llegan, se marcan leidos y se registra el telefono',
      () async {
        final valeria = await liveUser(name: 'Valeria Integración');
        final ana = await liveUser();
        addTearDown(valeria.dispose);
        addTearDown(ana.dispose);
        final product = await publishProduct(
          valeria,
          title: 'Calculadora Casio',
        );
        final order = await placeOrder(
          ana,
          (await openChat(ana, product.id)).id,
        );
        await ana
            .read(orderRepositoryProvider)
            .cancel(order.id, CancelReason.changedMind);
        final notifications = valeria.read(notificationRepositoryProvider);

        final page = await notifications.list(NotificationTab.orders);
        await notifications.markRead(page.items.first.id);
        final afterOne = await notifications.list(NotificationTab.all);
        await notifications.markAllRead();
        final afterAll = await notifications.list(NotificationTab.all);
        await notifications.registerDevice(
          'fid-integracion-${valeria.user.id}',
        );

        expect(page.items.map((n) => n.type), contains('order_created'));
        expect(afterOne.unread, lessThan(page.unread + 1));
        expect(afterAll.unread, 0);
      },
    );

    test('reportar, bloquear y desbloquear', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(valeria, title: 'Audífonos');
      final conversation = await openChat(ana, product.id);
      final reputation = ana.read(reputationRepositoryProvider);

      await reputation.report(
        UserReport(userId: valeria.user.id, conversationId: conversation.id),
        ReportReason.offPlatform,
        details: 'Me pidió pagar por fuera.',
      );
      await reputation.report(
        const GeneralReport(),
        ReportReason.other,
        details: 'No carga una foto.',
      );
      await reputation.block(valeria.user.id);
      final blocked = await reputation.blocked();
      await reputation.unblock(valeria.user.id);

      expect(blocked.map((b) => b.id), contains(valeria.user.id));
      expect(await reputation.blocked(), isEmpty);
    });
  });
}
