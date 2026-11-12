import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

/// La linea gris de una fila de "Mis pedidos" (maqueta `Perfil`):
/// "Entrega jue 8 oct · $500", "Falta tu pago · $290" o "26 sep · $420".
String orderLine(Order order) {
  final when = switch (order.status) {
    OrderStatus.pending when !order.paysCash => 'Falta tu pago',
    OrderStatus.pending => 'Por aceptar',
    OrderStatus.confirmed => 'Entrega ${shortDate(order.deliveryAt.toLocal())}',
    // Completado o cancelado: el dia en que paso.
    _ => dayMonth((order.updatedAt ?? order.deliveryAt).toLocal()),
  };
  return '$when · ${formatPrice(order.item.totalCents)}';
}

/// Pildora del estado (maqueta `Perfil` → "Mis pedidos"). La de "Cancelado"
/// no esta en la maqueta: va en gris con `circle-x`, como el aviso de HU-24.
class OrderStatusPill extends StatelessWidget {
  const new({required this.status, super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final (background, ink, icon, stroke) = switch (status) {
      OrderStatus.pending => (
        c.warningSoft,
        c.warningText,
        MusubiIcons.clock,
        2.6,
      ),
      OrderStatus.confirmed => (
        c.brandSoft,
        c.brandStrongText,
        MusubiIcons.check,
        3.0,
      ),
      OrderStatus.completed => (
        c.successSoft,
        c.successText,
        MusubiIcons.circleCheck,
        2.6,
      ),
      OrderStatus.cancelled => (
        c.surface,
        c.textSecondary,
        MusubiIcons.circleX,
        2.6,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          MusubiIcon(icon, size: 12, strokeWidth: stroke, color: ink),
          Text(
            status.label,
            style: MusubiType.style(11.5, weight: FontWeight.w800, color: ink),
          ),
        ],
      ),
    );
  }
}

/// Una compra: foto de 44, nombre, la linea gris y su estado. Al tocarla,
/// "Tu pedido" (`Pedido-pago`), que muestra cantidad, lugar y fecha.
class OrderRow extends StatelessWidget {
  const new({required this.order, required this.onTap, super.key});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final line = orderLine(order);
    return Pressable(
      key: Key('my-order-${order.id}'),
      onTap: onTap,
      semanticLabel: '${order.item.title}, $line, ${order.status.label}',
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          spacing: 12,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox.square(
                dimension: MusubiSizes.minTouch,
                child: ProductPhoto(url: order.item.photoUrl),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 1,
                children: [
                  Text(
                    order.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      14,
                      weight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            OrderStatusPill(status: order.status),
          ],
        ),
      ),
    );
  }
}

/// "Mis pedidos" de `Perfil` (HU-25): mis tres compras mas nuevas y
/// "Ver todos". Si no carga, el resto del Perfil sigue.
class RecentOrdersSection extends ConsumerWidget {
  const new({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, String route) async {
    await context.push(route);
    // Al volver, el estado pudo cambiar (pago, entrega o cancelacion).
    ref.invalidate(recentOrdersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final recent = ref.watch(recentOrdersProvider);
    final hint = MusubiType.style(
      13,
      weight: FontWeight.w600,
      color: c.textSecondary,
    );
    final link = Pressable(
      key: const Key('profile-orders-all'),
      onTap: () => unawaited(_open(context, ref, AppRoutes.myOrders)),
      semanticLabel: 'Ver todos mis pedidos',
      builder: (context, _) => SizedBox(
        height: MusubiSizes.minTouch,
        child: Center(
          child: Text(
            'Ver todos',
            style: MusubiType.style(
              13.5,
              weight: FontWeight.w700,
              color: c.brandText,
            ),
          ),
        ),
      ),
    );
    // El enlace mide 44 y se come 10 arriba y abajo del renglon de 24
    // (`margin:-10px 0` de la maqueta); va dentro del Stack para que el
    // toque llegue en todo su alto.
    return Padding(
      key: const Key('profile-orders'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 24,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Mis pedidos',
                        style: MusubiType.style(
                          16,
                          weight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ...switch (recent) {
                  AsyncData(:final value) when value.items.isEmpty => [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Cuando compres algo, aquí verás cómo va tu pedido.',
                        key: const Key('profile-orders-empty'),
                        style: hint,
                      ),
                    ),
                  ],
                  AsyncData(:final value) => [
                    for (final order in value.items)
                      OrderRow(
                        order: order,
                        onTap: () => unawaited(
                          _open(context, ref, AppRoutes.order(order.id)),
                        ),
                      ),
                  ],
                  AsyncError(:final error) => [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            error is ApiFailure
                                ? error.message
                                : 'No pudimos cargar tus pedidos.',
                            style: hint,
                          ),
                        ),
                        Pressable(
                          onTap: () => ref.invalidate(recentOrdersProvider),
                          semanticLabel: 'Reintentar',
                          builder: (context, _) => SizedBox(
                            height: MusubiSizes.minTouch,
                            child: Center(
                              child: Text(
                                'Reintentar',
                                style: MusubiType.style(
                                  13.5,
                                  weight: FontWeight.w700,
                                  color: c.brandText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  _ => [
                    for (var i = 0; i < 2; i++)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: SkeletonShimmer(
                          child: Row(
                            spacing: 12,
                            children: [
                              SkeletonBox(width: 44, height: 44, radius: 11),
                              Expanded(child: SkeletonBox(height: 14)),
                            ],
                          ),
                        ),
                      ),
                  ],
                },
              ],
            ),
          ),
          Positioned(top: 8, right: 0, child: link),
        ],
      ),
    );
  }
}
