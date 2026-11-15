import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/domain/reservation_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

/// "Hoy" o "Mañana" de una hora de `Apartar`.
String pickupDay(DateTime local, DateTime nowLocal) =>
    DateUtils.isSameDay(local, nowLocal) ? 'Hoy' : 'Mañana';

/// `Apartar` (HU-52): cuando y donde pasa quien aparta. Devuelve el apartado
/// creado, o `null` si se cerro.
Future<Reservation?> showReserveSheet(
  BuildContext context, {
  required ProductSummary product,
}) => showMusubiPanel<Reservation>(
  context,
  builder: (_) => ReserveSheet(product: product),
);

/// La hoja de `Apartar`: el producto, "Te lo guarda 24 h · Pagas al
/// recoger", "¿Cuándo pasas?" (tres horas), "¿Dónde?" (los puntos del campus)
/// y "Apartar · hoy 1:00 p. m.".
class ReserveSheet extends ConsumerStatefulWidget {
  const new({required this.product, super.key});

  final ProductSummary product;

  @override
  ConsumerState<ReserveSheet> createState() => _ReserveSheetState();
}

class _ReserveSheetState extends ConsumerState<ReserveSheet> {
  late final DateTime _now = ref.read(clockProvider)().toLocal();
  late final List<PickupSlot> _slots = PickupSlots.around(_now);
  int _slot = 0;
  String? _point;
  bool _sending = false;

  Future<void> _reserve(List<MeetingPoint> points) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final point = _point ?? _defaultPoint(points)?.slug;
    if (point == null || _slots.isEmpty) return;
    setState(() => _sending = true);
    try {
      final reservation = await ref
          .read(reservationRepositoryProvider)
          .create(
            productId: widget.product.id,
            meetingPoint: point,
            pickupAt: _slots[_slot].at,
          );
      ref.invalidate(myReservationsProvider);
      navigator.pop(reservation);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _sending = false);
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  MeetingPoint? _defaultPoint(List<MeetingPoint> points) {
    for (final point in points) {
      if (point.suggested) return point;
    }
    return points.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final media = MediaQuery.of(context);
    final product = widget.product;
    final points = ref.watch(meetingPointsProvider);
    final list = points.value ?? const <MeetingPoint>[];
    final selected = _point ?? _defaultPoint(list)?.slug;
    final slot = _slots.elementAtOrNull(_slot);
    final cta = slot == null
        ? 'Apartar'
        : 'Apartar · ${pickupDay(slot.at, _now).toLowerCase()} '
              '${clockTime(slot.at)}';
    // La hoja empieza a 236 de arriba, como en la maqueta (844 de alto).
    final height = math.min(
      media.size.height - 236,
      media.size.height - media.viewPadding.top - 24,
    );
    return Container(
      height: math.max(height, 480),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MusubiSizes.radiusSheet),
        ),
      ),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        label: 'Apartar',
        explicitChildNodes: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.borderStrong,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 10, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Apartar',
                        style: MusubiType.style(
                          22,
                          weight: FontWeight.w800,
                          line: 28,
                          em: -0.02,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Pressable(
                    key: const Key('reserve-close'),
                    onTap: () => Navigator.of(context).pop(),
                    semanticLabel: 'Cerrar',
                    builder: (context, _) => SizedBox.square(
                      dimension: MusubiSizes.minTouch,
                      child: Center(
                        child: MusubiIcon(
                          MusubiIcons.x,
                          size: 22,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: ReservedProductRow(
                        title: product.title,
                        meta: _meta(product),
                        photoUrl: product.photoUrl,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: c.warningSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        spacing: 10,
                        children: [
                          MusubiIcon(
                            MusubiIcons.clock,
                            size: 18,
                            strokeWidth: 2.2,
                            color: c.warningText,
                          ),
                          Expanded(
                            child: Text(
                              'Te lo guarda 24 h · Pagas al recoger',
                              style: MusubiType.style(
                                13.5,
                                weight: FontWeight.w800,
                                line: 18,
                                color: c.warningText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _Label('¿Cuándo pasas?'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Row(
                        spacing: 8,
                        children: [
                          for (var i = 0; i < _slots.length; i++)
                            Expanded(
                              child: _SlotButton(
                                key: Key('reserve-slot-$i'),
                                day: pickupDay(_slots[i].at, _now),
                                time: clockTime(_slots[i].at),
                                selected: i == _slot,
                                onTap: () => setState(() => _slot = i),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const _Label('¿Dónde?'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: switch (points) {
                        AsyncError() when list.isEmpty => Pressable(
                          onTap: () => ref.invalidate(meetingPointsProvider),
                          semanticLabel: 'Reintentar',
                          builder: (context, _) => SizedBox(
                            height: 48,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No pudimos cargar los puntos. Reintentar',
                                style: MusubiType.style(
                                  14,
                                  weight: FontWeight.w700,
                                  color: c.brandText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _ when list.isEmpty => const SizedBox(
                          height: 48,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: MusubiSpinner(),
                          ),
                        ),
                        _ => Wrap(
                          spacing: 8,
                          children: [
                            for (final point in list)
                              _PointChip(
                                key: Key('reserve-point-${point.slug}'),
                                name: point.name,
                                selected: point.slug == selected,
                                onTap: () =>
                                    setState(() => _point = point.slug),
                              ),
                          ],
                        ),
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  math.max<double>(30, media.viewPadding.bottom),
                ),
                child: Column(
                  spacing: 8,
                  children: [
                    MusubiButton(
                      key: const Key('reserve-confirm'),
                      label: cta,
                      icon: MusubiIcons.bookmark,
                      iconSize: 20,
                      loading: _sending,
                      loadingLabel: 'Apartando…',
                      onPressed: slot == null || selected == null
                          ? null
                          : () => unawaited(_reserve(list)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 6,
                      children: [
                        MusubiIcon(
                          MusubiIcons.qrCodeLite,
                          size: 14,
                          strokeWidth: 2.2,
                          color: c.textSecondary,
                        ),
                        Flexible(
                          child: Text(
                            'Recibirás un QR y un código para recogerlo',
                            style: MusubiType.style(
                              12.5,
                              weight: FontWeight.w600,
                              line: 17,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _meta(ProductSummary product) {
    final seller = product.sellerName;
    return seller == null || seller.isEmpty
        ? formatPrice(product.priceCents)
        : '${formatPrice(product.priceCents)} · ${shortPersonName(seller)}';
  }
}

/// La foto (56, radio 14), el nombre y "$450 · Valeria C." (`Apartar`).
class ReservedProductRow extends StatelessWidget {
  const new({
    required this.title,
    required this.meta,
    required this.photoUrl,
    super.key,
  });

  final String title;
  final String meta;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Row(
      spacing: 12,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox.square(
            dimension: 56,
            child: ProductPhoto(url: photoUrl),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MusubiType.style(
                  15,
                  weight: FontWeight.w800,
                  line: 20,
                  color: c.textPrimary,
                ),
              ),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MusubiType.style(
                  13,
                  weight: FontWeight.w600,
                  line: 18,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Text(
      text,
      style: MusubiType.style(
        14,
        weight: FontWeight.w800,
        line: 18,
        color: context.musubi.textPrimary,
      ),
    ),
  );
}

/// "Hoy / 1:00 p. m." (64 de alto, borde de 2).
class _SlotButton extends StatelessWidget {
  const new({
    required this.day,
    required this.time,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String day;
  final String time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '$day $time',
      builder: (context, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 64,
        decoration: BoxDecoration(
          color: selected ? c.brandSoft : c.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? c.brandBorder : c.border,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 2,
          children: [
            Text(
              day,
              style: MusubiType.style(
                12.5,
                weight: FontWeight.w700,
                line: 16,
                color: selected ? c.brandStrongText : c.textSecondary,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                time,
                maxLines: 1,
                style: MusubiType.style(
                  15,
                  weight: FontWeight.w800,
                  line: 20,
                  color: selected ? c.brandStrongText : c.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un punto del campus (pastilla de 40 en un toque de 48).
class _PointChip extends StatelessWidget {
  const new({
    required this.name,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final ink = selected ? c.background : c.textPrimary;
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: name,
      builder: (context, _) => SizedBox(
        height: 48,
        child: Center(
          widthFactor: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            padding: const EdgeInsets.only(left: 12, right: 14),
            decoration: BoxDecoration(
              color: selected ? c.textPrimary : c.elevated,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
              border: Border.all(
                color: selected ? c.textPrimary : c.border,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                MusubiIcon(
                  MusubiIcons.mapPinRound,
                  size: 15,
                  strokeWidth: 2.2,
                  color: ink,
                ),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      14,
                      weight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
