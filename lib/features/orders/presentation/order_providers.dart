import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/network/offline_cache.dart';
import 'package:musubi_app/features/orders/data/http_order_repository.dart';
import 'package:musubi_app/features/orders/data/http_reservation_repository.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/domain/order_repository.dart';
import 'package:musubi_app/features/orders/domain/payment_models.dart';
import 'package:musubi_app/features/orders/domain/reservation_models.dart';

/// Pedidos (HU-23). En pruebas, un fake.
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => HttpOrderRepository(
    ref.watch(dioProvider),
    ref.watch(appConfigProvider).apiBaseUrl,
  ),
);

/// La cuenta para recibir pagos (HU-55). En pruebas, un fake.
final payoutRepositoryProvider = Provider<PayoutRepository>(
  (ref) => HttpPayoutRepository(ref.watch(dioProvider)),
);

/// Mi cuenta para recibir pagos (`Ajustes` y `Cuenta-pagos`). Para recargar:
/// `ref.invalidate(payoutStatusProvider)`.
final FutureProvider<PayoutStatus> payoutStatusProvider =
    FutureProvider.autoDispose<PayoutStatus>(
      (ref) => ref.watch(payoutRepositoryProvider).mine(),
      retry: (_, _) => null,
    );

/// Los bancos de la CLABE (se llenan al escribirla).
final FutureProvider<List<PayoutBank>> payoutBanksProvider =
    FutureProvider.autoDispose<List<PayoutBank>>(
      (ref) => ref.watch(payoutRepositoryProvider).banks(),
      retry: (_, _) => null,
    );

/// La cuenta para transferir de un pedido (`Pago-transferencia`,
/// `Pago-validando` y `Pago-vendedor`).
final FutureProviderFamily<TransferDetails, String> transferProvider =
    FutureProvider.autoDispose.family<TransferDetails, String>(
      (ref, id) => ref.watch(orderRepositoryProvider).transfer(id),
      retry: (_, _) => null,
    );

/// Los puntos de entrega del campus ("Entrega" del resumen).
final FutureProvider<List<MeetingPoint>> meetingPointsProvider =
    FutureProvider.autoDispose<List<MeetingPoint>>(
      (ref) => ref.watch(orderRepositoryProvider).meetingPoints(),
      retry: (_, _) => null,
    );

/// El pedido abierto (pendiente o confirmado) de una conversacion, o `null`:
/// decide que hace el aviso del chat. Para recargar:
/// `ref.invalidate(openOrderProvider(conversationId))`.
final FutureProviderFamily<Order?, String> openOrderProvider = FutureProvider
    .autoDispose
    .family<Order?, String>((ref, conversationId) async {
      final orders = await ref
          .watch(orderRepositoryProvider)
          .byConversation(conversationId);
      for (final order in orders) {
        if (order.status.open) return order;
      }
      return null;
    }, retry: (_, _) => null);

/// "Tu pedido" (`Pedido-pago`). Para recargar:
/// `ref.invalidate(orderProvider(id))`.
final FutureProviderFamily<Order, String> orderProvider = FutureProvider
    .autoDispose
    .family<Order, String>(
      (ref, id) => ref.watch(orderRepositoryProvider).get(id),
      retry: (_, _) => null,
    );

/// "Mis pedidos" de `Perfil` (HU-25): mis tres compras mas nuevas. Se recarga
/// con `ref.invalidate(recentOrdersProvider)`.
final FutureProvider<MyOrdersPage> recentOrdersProvider =
    FutureProvider.autoDispose<MyOrdersPage>(
      (ref) => ref.watch(orderRepositoryProvider).mine(limit: 3),
      retry: (_, _) => null,
    );

/// La primera pagina de mis ventas (HU-26): "Vendidos" de `Mis-productos`.
/// "Ver más" pide las siguientes con el repositorio.
final FutureProvider<SalesPage> salesProvider =
    FutureProvider.autoDispose<SalesPage>(
      (ref) => ref.watch(orderRepositoryProvider).sales(),
      retry: (_, _) => null,
    );

/// La primera pagina de una pestana de "Mis pedidos" (HU-25); "Ver más" pide
/// las siguientes con el repositorio.
final FutureProviderFamily<MyOrdersPage, MyOrdersTab> myOrdersProvider =
    FutureProvider.autoDispose.family<MyOrdersPage, MyOrdersTab>((ref, tab) {
      refreshWithOfflineCopies(ref, const {ApiPaths.myOrders});
      return ref.watch(orderRepositoryProvider).mine(tab: tab);
    }, retry: (_, _) => null);

/// Los apartados (HU-52). En pruebas, un fake.
final reservationRepositoryProvider = Provider<ReservationRepository>(
  (ref) => HttpReservationRepository(
    ref.watch(dioProvider),
    ref.watch(appConfigProvider).apiBaseUrl,
  ),
);

/// Un apartado (`Apartado-listo`, `Verificar-comprador` y
/// `Apartado-verificado`). Para recargar:
/// `ref.invalidate(reservationProvider(id))`.
final FutureProviderFamily<Reservation, String> reservationProvider =
    FutureProvider.autoDispose.family<Reservation, String>(
      (ref, id) => ref.watch(reservationRepositoryProvider).get(id),
      retry: (_, _) => null,
    );

/// Una pestana de `Mis-apartados` (y la tarjeta "Mis apartados" de `Perfil`,
/// con la de "Yo aparté"). Para recargar:
/// `ref.invalidate(myReservationsProvider)`.
final FutureProviderFamily<ReservationPage, ReservationTab>
myReservationsProvider = FutureProvider.autoDispose
    .family<ReservationPage, ReservationTab>(
      (ref, tab) => ref.watch(reservationRepositoryProvider).mine(tab),
      retry: (_, _) => null,
    );
