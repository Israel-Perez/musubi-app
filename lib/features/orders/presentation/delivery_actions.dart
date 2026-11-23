import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/platform/device_calendar.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

// HU-62: "Agregar al calendario" y "Ya llegué" de un pedido confirmado. La
// maqueta no los tiene: se agregan sin quitar nada (lineamiento 4), con las
// piezas de la maqueta (02-04).

/// "Hoy a la 1:00 p. m.", "Mañana a las 9:30 a. m." o
/// "lun 5 oct a la 1:00 p. m." (horas locales).
String deliveryWhen(DateTime at, DateTime now) {
  final day = DateTime(at.year, at.month, at.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = day.difference(today).inDays;
  final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final time = '${hour == 1 ? 'a la' : 'a las'} ${clockTime(at)}';
  return switch (days) {
    0 => 'Hoy $time',
    1 => 'Mañana $time',
    _ => '${shortDate(at)} $time',
  };
}

String _first(String name) => name.trim().split(RegExp(r'\s+')).first;

/// La entrega como evento del calendario: 30 minutos en el punto del campus.
CalendarEvent deliveryEvent(Order order) => CalendarEvent(
  title: 'Entrega de ${order.item.title} · Musubi',
  start: order.deliveryAt,
  end: order.deliveryAt.add(const Duration(minutes: 30)),
  location: [
    order.pointName,
    if (order.detail != null) order.detail!,
  ].join(', '),
  description:
      'Pedido #${order.number} con ${_first(order.otherName)}. Ábrelo en '
      'Musubi para ver los detalles.',
);

/// "Agregar al calendario": abre la app de calendario con la entrega llena.
Future<void> addDeliveryToCalendar(
  BuildContext context,
  WidgetRef ref,
  Order order,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await ref
      .read(deviceCalendarProvider)
      .add(deliveryEvent(order));
  if (!opened) {
    showMusubiSnack(
      messenger,
      'No encontramos una app de calendario en tu teléfono.',
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
    );
  }
}

/// "Ya llegué": avisa a la otra parte y deja el aviso en el chat. Regresa
/// `true` si se aviso.
Future<bool> sayArrived(
  BuildContext context,
  WidgetRef ref,
  Order order,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(orderRepositoryProvider).arrived(order.id);
    ref
      ..invalidate(orderProvider(order.id))
      ..invalidate(openOrderProvider(order.conversationId));
    showMusubiSnack(
      messenger,
      'Le avisamos a ${_first(order.otherName)} que ya llegaste.',
      icon: MusubiIcons.circleCheck,
    );
    return true;
  } on ApiFailure catch (failure) {
    showMusubiSnack(
      messenger,
      failure.message,
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
    );
    return false;
  }
}

/// La tarjeta "Entrega" de `Pedido-pago` en un pedido confirmado: cuando y
/// donde, "Agregar al calendario" y, desde 2 horas antes, "Ya llegué".
class DeliveryCard extends ConsumerStatefulWidget {
  const new({required this.order, required this.now, super.key});

  final Order order;
  final DateTime now;

  @override
  ConsumerState<DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends ConsumerState<DeliveryCard> {
  bool _arriving = false;

  Future<void> _arrived() async {
    setState(() => _arriving = true);
    await sayArrived(context, ref, widget.order);
    if (mounted) setState(() => _arriving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final order = widget.order;
    final other = _first(order.otherName);
    final status = order.iArrived
        ? 'Ya le avisaste a $other que llegaste.'
        : order.otherArrived
        ? '$other ya llegó a ${order.pointName}.'
        : null;
    return Container(
      key: const Key('order-delivery-card'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 12,
            children: [
              MusubiIcon(MusubiIcons.calendar, size: 20, color: c.brand),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      deliveryWhen(
                        order.deliveryAt.toLocal(),
                        widget.now.toLocal(),
                      ),
                      style: MusubiType.style(
                        15,
                        line: 20,
                        weight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      'En ${order.pointName} con $other',
                      style: MusubiType.style(
                        13,
                        line: 18,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status != null)
            Row(
              key: const Key('order-arrival-status'),
              spacing: 8,
              children: [
                MusubiIcon(MusubiIcons.mapPin, size: 16, color: c.successText),
                Expanded(
                  child: Text(
                    status,
                    style: MusubiType.style(
                      13,
                      line: 18,
                      weight: FontWeight.w700,
                      color: c.successText,
                    ),
                  ),
                ),
              ],
            ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: MusubiButton(
                  key: const Key('order-add-calendar'),
                  label: 'Agregar al calendario',
                  kind: MusubiButtonKind.secondary,
                  height: 44,
                  fontSize: 14,
                  icon: MusubiIcons.calendar,
                  iconSize: 16,
                  gap: 6,
                  onPressed: () =>
                      addDeliveryToCalendar(context, ref, widget.order),
                ),
              ),
              if (order.canSayArrived(widget.now))
                Expanded(
                  child: MusubiButton(
                    key: const Key('order-arrived'),
                    label: 'Ya llegué',
                    loadingLabel: 'Avisando…',
                    loading: _arriving,
                    height: 44,
                    fontSize: 14,
                    icon: MusubiIcons.mapPin,
                    iconSize: 16,
                    gap: 6,
                    onPressed: _arriving ? null : _arrived,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La franja del chat con un pedido confirmado cuya entrega ya es pronto
/// (desde 2 horas antes): "Hoy a la 1:00 p. m. en Biblioteca" y "Ya llegué".
class ArrivalBar extends ConsumerStatefulWidget {
  const new({required this.order, required this.now, super.key});

  final Order order;
  final DateTime now;

  /// Si se muestra para ese pedido.
  static bool showsFor(Order? order, DateTime now) =>
      order != null &&
      order.status == OrderStatus.confirmed &&
      !now.isBefore(order.deliveryAt.subtract(Order.arrivalLead));

  @override
  ConsumerState<ArrivalBar> createState() => _ArrivalBarState();
}

class _ArrivalBarState extends ConsumerState<ArrivalBar> {
  bool _arriving = false;

  Future<void> _arrived() async {
    setState(() => _arriving = true);
    await sayArrived(context, ref, widget.order);
    if (mounted) setState(() => _arriving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final order = widget.order;
    final now = widget.now.toLocal();
    return DecoratedBox(
      key: const Key('chat-arrival-bar'),
      decoration: BoxDecoration(
        color: c.brandFaint,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        child: Row(
          spacing: 10,
          children: [
            MusubiIcon(MusubiIcons.mapPin, size: 18, color: c.brand),
            Expanded(
              child: Text(
                order.iArrived
                    ? 'Ya avisaste que llegaste a ${order.pointName}.'
                    : '${deliveryWhen(order.deliveryAt.toLocal(), now)} '
                          'en ${order.pointName}',
                style: MusubiType.style(
                  13,
                  line: 18,
                  weight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (!order.iArrived)
              MusubiButton(
                key: const Key('chat-arrived'),
                label: 'Ya llegué',
                loadingLabel: 'Avisando…',
                loading: _arriving,
                expand: false,
                height: 36,
                fontSize: 13,
                onPressed: _arriving ? null : _arrived,
              ),
          ],
        ),
      ),
    );
  }
}
