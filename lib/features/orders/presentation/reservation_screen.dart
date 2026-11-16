import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/orders/domain/reservation_models.dart';
import 'package:musubi_app/features/orders/presentation/my_reservations_screen.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:qr_flutter/qr_flutter.dart';

String _first(String name) => name.trim().split(RegExp(r'\s+')).first;

/// "Hoy", "Mañana", "Ayer" o "jue 8 oct" de una hora local.
String pickupDayLabel(DateTime local, DateTime nowLocal) {
  final day = DateUtils.dateOnly(local);
  final today = DateUtils.dateOnly(nowLocal);
  return switch (day.difference(today).inDays) {
    0 => 'Hoy',
    1 => 'Mañana',
    -1 => 'Ayer',
    _ => shortDate(local),
  };
}

/// "Hoy · 1:00 p. m." (la hora de recoger).
String pickupLine(DateTime at, DateTime now) {
  final local = at.toLocal();
  return '${pickupDayLabel(local, now.toLocal())} · ${clockTime(local)}';
}

/// "Vence en 24 h", "Vence en 3 h" o "Vence en 40 min".
String expiresLabel(DateTime expiresAt, DateTime now) {
  final left = expiresAt.difference(now);
  if (left.inMinutes < 60) {
    return 'Vence en ${left.inMinutes.clamp(1, 59)} min';
  }
  return 'Vence en ${(left.inMinutes / 60).ceil()} h';
}

/// "¿Cancelar el apartado?" (`Apartado-listo`). Devuelve `true` con "Sí,
/// cancelar".
Future<bool> confirmCancelReservation(
  BuildContext context,
  Reservation reservation,
) async {
  final other = _first(reservation.otherName);
  final confirmed = await showMusubiSheet<bool>(
    context,
    style: MusubiSheetStyle.screen,
    builder: (context) {
      final c = context.musubi;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 18),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: MusubiIcon(
                MusubiIcons.circleX,
                size: 26,
                color: c.dangerText,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Semantics(
              header: true,
              child: Text(
                '¿Cancelar el apartado?',
                textAlign: TextAlign.center,
                style: MusubiType.style(
                  21,
                  weight: FontWeight.w800,
                  line: 27,
                  em: -0.02,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              reservation.isBuyer
                  ? '$other podrá venderlo a alguien más.'
                  : '$other ya no podrá recogerlo y la pieza vuelve a tu '
                        'publicación.',
              textAlign: TextAlign.center,
              style: MusubiType.style(14.5, line: 21, color: c.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              spacing: 8,
              children: [
                Pressable(
                  key: const Key('reservation-cancel-confirm'),
                  onTap: () => Navigator.of(context).pop(true),
                  semanticLabel: 'Sí, cancelar',
                  builder: (context, pressed) => Container(
                    height: MusubiSizes.buttonHeightSheet,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: pressed ? c.brandPressed : c.dangerText,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Sí, cancelar',
                      style: MusubiType.style(
                        16,
                        weight: FontWeight.w700,
                        color: c.isDark ? c.background : c.onBrand,
                      ),
                    ),
                  ),
                ),
                MusubiButton(
                  label: 'Conservarlo',
                  kind: MusubiButtonKind.secondary,
                  height: MusubiSizes.buttonHeightSheet,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Cancela el apartado y avisa; devuelve el apartado cancelado o `null`.
Future<Reservation?> cancelReservation(
  BuildContext context,
  WidgetRef ref,
  Reservation reservation,
) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!await confirmCancelReservation(context, reservation)) return null;
  try {
    final cancelled = await ref
        .read(reservationRepositoryProvider)
        .cancel(reservation.id);
    ref
      ..invalidate(reservationProvider(reservation.id))
      ..invalidate(myReservationsProvider);
    showMusubiSnack(
      messenger,
      'Cancelaste el apartado',
      icon: MusubiIcons.circleCheck,
    );
    return cancelled;
  } on ApiFailure catch (failure) {
    showMusubiSnack(
      messenger,
      failure.message,
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
    );
    return null;
  }
}

/// `Apartado-listo` (HU-52): el boleto rojo con el QR y el codigo de 6
/// digitos, el punto, la hora y "Vence en 24 h"; "Mensaje", "Mis apartados" y
/// "Cancelar apartado". Quien vende ve su tarjeta de "Me apartaron"; uno que
/// ya no esta activo dice como termino.
class ReservationScreen extends ConsumerWidget {
  const new({required this.reservationId, super.key, this.fromList = false});

  final String reservationId;

  /// Se abrio desde `Mis-apartados`: "Mis apartados" regresa.
  final bool fromList;

  void _close(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final reservation = ref.watch(reservationProvider(reservationId));
    final now = ref.watch(clockProvider)();
    return Scaffold(
      backgroundColor: c.background,
      body: switch (reservation) {
        AsyncData(:final value) => _Loaded(
          reservation: value,
          now: now,
          onClose: () => _close(context),
          onMessage: () => unawaited(
            context.push(AppRoutes.conversation(value.conversationId)),
          ),
          onList: () {
            if (fromList && context.canPop()) {
              context.pop();
            } else {
              context.pushReplacement(
                value.isBuyer
                    ? AppRoutes.myReservations
                    : AppRoutes.myReservationsTab('seller'),
              );
            }
          },
          onCancel: () => unawaited(cancelReservation(context, ref, value)),
          onVerify: () =>
              unawaited(context.push(AppRoutes.verifyBuyer(value.id))),
        ),
        AsyncError(:final error) => SafeArea(
          child: ErrorView(
            message: error is ApiFailure
                ? error.message
                : 'No pudimos abrir el apartado.',
            onRetry: () => ref.invalidate(reservationProvider(reservationId)),
          ),
        ),
        _ => const LoadingView(message: 'Cargando tu apartado…'),
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const new({
    required this.reservation,
    required this.now,
    required this.onClose,
    required this.onMessage,
    required this.onList,
    required this.onCancel,
    required this.onVerify,
  });

  final Reservation reservation;
  final DateTime now;
  final VoidCallback onClose;
  final VoidCallback onMessage;
  final VoidCallback onList;
  final VoidCallback onCancel;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final r = reservation;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Pressable(
                  key: const Key('reservation-close'),
                  onTap: onClose,
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
                Expanded(
                  child: Column(
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Apartado',
                          style: MusubiType.style(
                            17,
                            weight: FontWeight.w800,
                            line: 22,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '#${r.number}',
                        style: MusubiType.style(
                          12,
                          weight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MusubiSizes.minTouch),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(child: _StatusPill(reservation: r)),
                ),
                if (r.isBuyer)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: ReservationTicket(reservation: r),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: ReservationCard(
                      reservation: r,
                      now: now,
                      onVerify: r.active ? onVerify : null,
                    ),
                  ),
                _PlaceCard(reservation: r, now: now),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.background,
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottom > 24 ? bottom : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: MusubiButton(
                        key: const Key('reservation-message'),
                        label: 'Mensaje',
                        kind: MusubiButtonKind.secondary,
                        icon: MusubiIcons.messageCircle,
                        iconSize: 20,
                        iconStrokeWidth: 1.9,
                        height: MusubiSizes.buttonHeightSheet,
                        fontSize: 15.5,
                        onPressed: onMessage,
                      ),
                    ),
                    Expanded(
                      child: _DarkButton(
                        key: const Key('reservation-list'),
                        label: 'Mis apartados',
                        onTap: onList,
                      ),
                    ),
                  ],
                ),
                if (r.active)
                  Pressable(
                    key: const Key('reservation-cancel'),
                    onTap: onCancel,
                    semanticLabel: 'Cancelar apartado',
                    builder: (context, _) => SizedBox(
                      height: MusubiSizes.minTouch,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 6,
                        children: [
                          MusubiIcon(
                            MusubiIcons.circleX,
                            size: 16,
                            strokeWidth: 2.2,
                            color: c.dangerText,
                          ),
                          Text(
                            'Cancelar apartado',
                            style: MusubiType.style(
                              14,
                              weight: FontWeight.w700,
                              color: c.dangerText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Boton oscuro de la maqueta (`.dk`/"Mis apartados"): 54 de alto.
class _DarkButton extends StatelessWidget {
  const new({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, pressed) => Container(
        height: MusubiSizes.buttonHeightSheet,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressed ? c.textSecondary : c.textPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MusubiType.style(
            15.5,
            weight: FontWeight.w700,
            color: c.background,
          ),
        ),
      ),
    );
  }
}

/// "Valeria te lo guarda" (verde), o como termino el apartado.
class _StatusPill extends StatelessWidget {
  const new({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final r = reservation;
    final (text, icon, soft, ink, dot) = switch (r.status) {
      ReservationStatus.active when r.isBuyer => (
        '${_first(r.sellerName)} te lo guarda',
        MusubiIcons.check,
        c.successSoft,
        c.successText,
        c.success,
      ),
      ReservationStatus.active => (
        '${_first(r.buyerName)} lo apartó',
        MusubiIcons.check,
        c.successSoft,
        c.successText,
        c.success,
      ),
      ReservationStatus.collected => (
        'Entregado',
        MusubiIcons.check,
        c.successSoft,
        c.successText,
        c.success,
      ),
      ReservationStatus.cancelled => (
        'Apartado cancelado',
        MusubiIcons.x,
        c.surface,
        c.textSecondary,
        c.textSecondary,
      ),
      ReservationStatus.expired => (
        'El apartado venció',
        MusubiIcons.x,
        c.surface,
        c.textSecondary,
        c.textSecondary,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        height: 30,
        padding: const EdgeInsets.only(left: 6, right: 12),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              child: Center(
                child: MusubiIcon(
                  icon,
                  size: 12,
                  strokeWidth: 3.2,
                  color: c.isDark ? c.background : c.onBrand,
                ),
              ),
            ),
            Text(
              text,
              style: MusubiType.style(13, weight: FontWeight.w800, color: ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// El boleto rojo de `Apartado-listo`: el producto, la linea punteada con sus
/// muescas, el QR (196 de caja, 172 de codigo) y "O DICTA TU CÓDIGO 482 173".
/// Sin codigo (ya no esta activo) el boleto queda gris y sin QR.
class ReservationTicket extends StatelessWidget {
  const new({required this.reservation, super.key});

  final Reservation reservation;

  static const _paleText = Color(0xFFFFE3E4);

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final r = reservation;
    final qr = r.active ? r.qrPayload : null;
    final live = qr != null;
    final ink = live ? c.onBrand : c.textPrimary;
    final soft = live ? _paleText : c.textSecondary;
    final background = live ? c.brand : c.surface;
    return Semantics(
      container: true,
      label: 'Tu QR y código de apartado',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(26),
          boxShadow: live
              ? const [
                  BoxShadow(
                    color: Color(0x47A50F15),
                    offset: Offset(0, 16),
                    blurRadius: 34,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 12,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.onBrand, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ProductPhoto(url: r.photoUrl),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 1,
                    children: [
                      Text(
                        r.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          14.5,
                          weight: FontWeight.w800,
                          line: 19,
                          color: ink,
                        ),
                      ),
                      Text(
                        '${formatPrice(r.priceCents)} · '
                        '${shortPersonName(r.sellerName)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          12.5,
                          weight: FontWeight.w600,
                          line: 17,
                          color: soft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _Perforation(
              color: live ? const Color(0x73FFFFFF) : c.border,
              notch: c.background,
            ),
            if (live) ...[
              Center(
                child: Container(
                  width: 196,
                  height: 196,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFEFE),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: QrImageView(
                    key: const Key('reservation-qr'),
                    data: qr,
                    size: 172,
                    padding: const EdgeInsets.all(172 / 23),
                    backgroundColor: const Color(0xFFFEFEFE),
                    semanticsLabel: 'Código QR del apartado',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'O DICTA TU CÓDIGO',
                textAlign: TextAlign.center,
                style: MusubiType.style(
                  11,
                  weight: FontWeight.w800,
                  line: 14,
                  em: 0.12,
                  color: _paleText,
                ),
              ),
              const SizedBox(height: 2),
              Semantics(
                label: 'Código ${r.code?.split('').join(' ')}',
                excludeSemantics: true,
                child: Text(
                  r.spacedCode ?? '',
                  key: const Key('reservation-code'),
                  textAlign: TextAlign.center,
                  style:
                      MusubiType.style(
                        32,
                        weight: FontWeight.w800,
                        line: 38,
                        em: 0.12,
                        color: c.onBrand,
                      ).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  switch (r.status) {
                    ReservationStatus.collected =>
                      'Ya lo recogiste. Lo encuentras en "Mis pedidos".',
                    ReservationStatus.expired =>
                      'Pasaron 24 h sin recogerlo y la pieza regresó a la '
                          'publicación.',
                    _ =>
                      'Se canceló el apartado y la pieza regresó a la '
                          'publicación.',
                  },
                  textAlign: TextAlign.center,
                  style: MusubiType.style(
                    14,
                    weight: FontWeight.w600,
                    line: 20,
                    color: c.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// La linea punteada del boleto con una muesca a cada lado
/// (`margin: 14px -16px`, `border-top: 2px dashed` y circulos de 20).
class _Perforation extends StatelessWidget {
  const new({required this.color, required this.notch});

  final Color color;
  final Color notch;

  @override
  Widget build(BuildContext context) {
    Widget hole({required bool left}) => Positioned(
      left: left ? -26 : null,
      right: left ? null : -26,
      top: -9,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: notch, shape: BoxShape.circle),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(
        height: 2,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -16,
              right: -16,
              top: 0,
              height: 2,
              child: CustomPaint(painter: _DashPainter(color)),
            ),
            hole(left: true),
            hole(left: false),
          ],
        ),
      ),
    );
  }
}

/// `2px dashed` como Chrome: guiones del doble del grosor y huecos que se
/// ajustan para empezar y terminar con un guion.
class _DashPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 4.0;
    const idealGap = 2.0;
    final count = ((size.width + idealGap) / (dash + idealGap)).floor();
    if (count < 2) return;
    final gap = (size.width - count * dash) / (count - 1);
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    for (var i = 0; i < count; i++) {
      final x = i * (dash + gap);
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}

/// El punto (pin rojo) y la hora (calendario rojo) con "Vence en 24 h".
class _PlaceCard extends StatelessWidget {
  const new({required this.reservation, required this.now});

  final Reservation reservation;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final r = reservation;
    Widget row(
      MusubiIconData icon,
      String text, {
      Widget? trailing,
      bool divider = false,
    }) => Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: divider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: c.divider)),
            )
          : null,
      child: Row(
        spacing: 10,
        children: [
          MusubiIcon(icon, size: 18, strokeWidth: 2.2, color: c.brandText),
          Expanded(
            child: Text(
              text,
              style: MusubiType.style(
                14.5,
                weight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          row(MusubiIcons.mapPinRound, r.pointName, divider: true),
          row(
            MusubiIcons.calendar,
            pickupLine(r.pickupAt, now),
            trailing: r.active
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.warningSoft,
                      borderRadius: BorderRadius.circular(
                        MusubiSizes.radiusChip,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        MusubiIcon(
                          MusubiIcons.clock,
                          size: 12,
                          strokeWidth: 2.6,
                          color: c.warningText,
                        ),
                        Text(
                          expiresLabel(r.expiresAt, now),
                          style: MusubiType.style(
                            11.5,
                            weight: FontWeight.w800,
                            color: c.warningText,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
