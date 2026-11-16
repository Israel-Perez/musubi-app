import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/orders/domain/reservation_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

/// `Mis-apartados` (HU-52): "Yo aparté (n)" y "Me apartaron (n)". Quien
/// aparto ve "Mostrar mi QR"; quien vende, "Verificar comprador" (y "Entrega
/// solo después de verificar").
class MyReservationsScreen extends ConsumerStatefulWidget {
  const new({super.key, this.initialTab = ReservationTab.buyer});

  final ReservationTab initialTab;

  @override
  ConsumerState<MyReservationsScreen> createState() =>
      _MyReservationsScreenState();
}

class _MyReservationsScreenState extends ConsumerState<MyReservationsScreen> {
  late ReservationTab _tab = widget.initialTab;

  /// Ultimos numeros: no parpadean a 0 mientras carga la otra pestana.
  (int, int) _counts = (0, 0);

  Future<void> _open(String route) async {
    await context.push(route, extra: true);
    if (mounted) ref.invalidate(myReservationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final page = ref.watch(myReservationsProvider(_tab));
    if (page.value case final value?) _counts = (value.bought, value.sold);
    final now = ref.watch(clockProvider)();
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.profile),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _Tabs(
                tab: _tab,
                bought: _counts.$1,
                sold: _counts.$2,
                onSelect: (tab) => setState(() => _tab = tab),
              ),
            ),
            Expanded(
              child: switch (page) {
                AsyncError(:final error) => ErrorView(
                  message: error is ApiFailure
                      ? error.message
                      : 'No pudimos cargar tus apartados.',
                  onRetry: () => ref.invalidate(myReservationsProvider(_tab)),
                ),
                AsyncData(:final value) when value.items.isEmpty => _Empty(
                  tab: _tab,
                ),
                AsyncData(:final value) => RefreshIndicator(
                  color: c.brand,
                  onRefresh: () {
                    ref.invalidate(myReservationsProvider(_tab));
                    return ref.read(myReservationsProvider(_tab).future);
                  },
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.viewPaddingOf(context).bottom + 24,
                    ),
                    children: [
                      for (final r in value.items) ...[
                        ReservationCard(
                          key: Key('reservation-card-${r.id}'),
                          reservation: r,
                          now: now,
                          onOpen: () =>
                              unawaited(_open(AppRoutes.reservation(r.id))),
                          onShowQr: () =>
                              unawaited(_open(AppRoutes.reservation(r.id))),
                          onVerify: () =>
                              unawaited(_open(AppRoutes.verifyBuyer(r.id))),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_tab == ReservationTab.seller) const _SellerNote(),
                    ],
                  ),
                ),
                _ => const LoadingView(message: 'Cargando tus apartados…'),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// "Regresar" (chevron de 24) y "Mis apartados" al centro.
class _Header extends StatelessWidget {
  const new({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: MusubiSizes.minTouch,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Pressable(
                key: const Key('my-reservations-back'),
                onTap: onBack,
                semanticLabel: 'Regresar',
                builder: (context, _) => SizedBox.square(
                  dimension: MusubiSizes.minTouch,
                  child: Center(
                    child: MusubiIcon(
                      MusubiIcons.chevronLeft,
                      strokeWidth: 1.9,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                'Mis apartados',
                style: MusubiType.style(
                  17,
                  weight: FontWeight.w800,
                  line: 22,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Yo aparté (2)" y "Me apartaron (1)": 48 de alto, pastillas de radio 13.
class _Tabs extends StatelessWidget {
  const new({
    required this.tab,
    required this.bought,
    required this.sold,
    required this.onSelect,
  });

  final ReservationTab tab;
  final int bought;
  final int sold;
  final ValueChanged<ReservationTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 3,
        children: [
          for (final (value, label) in [
            (ReservationTab.buyer, 'Yo aparté ($bought)'),
            (ReservationTab.seller, 'Me apartaron ($sold)'),
          ])
            Expanded(
              child: Pressable(
                key: Key('my-reservations-tab-${value.code}'),
                onTap: () => onSelect(value),
                selected: value == tab,
                semanticLabel: label,
                builder: (context, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == tab ? c.elevated : null,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: value == tab
                        ? const [
                            BoxShadow(
                              color: Color(0x241C1C1E),
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      14,
                      weight: value == tab ? FontWeight.w800 : FontWeight.w600,
                      color: value == tab ? c.textPrimary : c.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Una tarjeta de `Mis-apartados`. Activo y mio: borde rosa con "Mostrar mi
/// QR"; activo y de quien vende: "Verificar comprador". Los demas dicen como
/// terminaron ("Recogido · 12 oct").
class ReservationCard extends StatelessWidget {
  const new({
    required this.reservation,
    required this.now,
    super.key,
    this.onOpen,
    this.onShowQr,
    this.onVerify,
  });

  final Reservation reservation;
  final DateTime now;
  final VoidCallback? onOpen;
  final VoidCallback? onShowQr;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final r = reservation;
    final highlight = r.active && r.isBuyer;
    final action = switch (r) {
      _ when !r.active => null,
      _ when r.isBuyer && onShowQr != null => _CardButton(
        key: const Key('reservation-show-qr'),
        label: 'Mostrar mi QR',
        icon: MusubiIcons.qrCode,
        background: c.brand,
        pressed: c.brandPressed,
        ink: c.onBrand,
        onTap: onShowQr!,
      ),
      _ when !r.isBuyer && onVerify != null => _CardButton(
        key: const Key('reservation-verify'),
        label: 'Verificar comprador',
        icon: MusubiIcons.scanLine,
        background: c.textPrimary,
        pressed: c.textSecondary,
        ink: c.background,
        onTap: onVerify!,
      ),
      _ => null,
    };
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? c.brandFaint : c.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlight ? c.brandSoftBorder : c.border,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox.square(
                  dimension: 64,
                  child: ProductPhoto(url: r.photoUrl),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text(
                      r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        15,
                        weight: FontWeight.w800,
                        line: 20,
                        color: c.textPrimary,
                      ),
                    ),
                    if (r.isBuyer)
                      _Meta(
                        '${formatPrice(r.priceCents)} · '
                        '${shortPersonName(r.sellerName)}',
                      )
                    else
                      Row(
                        spacing: 6,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: c.warningSoft,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initialsOf(r.buyerName),
                              style: MusubiType.style(
                                8,
                                weight: FontWeight.w800,
                                color: c.warningText,
                              ),
                            ),
                          ),
                          Flexible(
                            child: _Meta(
                              '${shortPersonName(r.buyerName)} · '
                              '${formatPrice(r.priceCents)}',
                            ),
                          ),
                        ],
                      ),
                    _StatusChip(reservation: r, now: now),
                  ],
                ),
              ),
            ],
          ),
          ?action,
        ],
      ),
    );
    final open = onOpen;
    if (open == null) return card;
    return Pressable(
      onTap: open,
      semanticLabel: r.title,
      builder: (context, _) => card,
    );
  }
}

class _Meta extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: MusubiType.style(
      13,
      weight: FontWeight.w600,
      line: 17,
      color: context.musubi.textSecondary,
    ),
  );
}

/// "Por recoger · hoy 1:00 p. m.", "Recoge hoy 3:00 p. m.", "Recogido · 12
/// oct", "Entregado hoy", "Cancelado · 12 oct" o "Venció · 12 oct".
class _StatusChip extends StatelessWidget {
  const new({required this.reservation, required this.now});

  final Reservation reservation;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final r = reservation;
    final nowLocal = now.toLocal();
    final pickup = r.pickupAt.toLocal();
    final when = '${_day(pickup, nowLocal).toLowerCase()} ${clockTime(pickup)}';
    final ended = (r.updatedAt ?? r.pickupAt).toLocal();
    final endedToday = DateUtils.isSameDay(ended, nowLocal);
    final (text, icon, soft, ink) = switch (r.status) {
      ReservationStatus.active when r.isBuyer => (
        'Por recoger · $when',
        MusubiIcons.clock,
        c.warningSoft,
        c.warningText,
      ),
      ReservationStatus.active => (
        'Recoge $when',
        MusubiIcons.clock,
        c.warningSoft,
        c.warningText,
      ),
      ReservationStatus.collected when !r.isBuyer && endedToday => (
        'Entregado hoy',
        MusubiIcons.circleCheck,
        c.successSoft,
        c.successText,
      ),
      ReservationStatus.collected => (
        '${r.isBuyer ? 'Recogido' : 'Entregado'} · ${dayMonth(ended)}',
        MusubiIcons.circleCheck,
        c.successSoft,
        c.successText,
      ),
      ReservationStatus.cancelled => (
        'Cancelado · ${dayMonth(ended)}',
        MusubiIcons.circleX,
        c.surface,
        c.textSecondary,
      ),
      ReservationStatus.expired => (
        'Venció · ${dayMonth(ended)}',
        MusubiIcons.circleX,
        c.surface,
        c.textSecondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          MusubiIcon(icon, size: 12, strokeWidth: 2.6, color: ink),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.style(
                11.5,
                weight: FontWeight.w800,
                line: 16,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _day(DateTime local, DateTime nowLocal) {
    final days = DateUtils.dateOnly(local)
        .difference(DateUtils.dateOnly(nowLocal))
        .inDays;
    return switch (days) {
      0 => 'Hoy',
      1 => 'Mañana',
      _ => shortDate(local),
    };
  }
}

/// Boton de 48 de una tarjeta ("Mostrar mi QR" / "Verificar comprador").
class _CardButton extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.background,
    required this.pressed,
    required this.ink,
    required this.onTap,
    super.key,
  });

  final String label;
  final MusubiIconData icon;
  final Color background;
  final Color pressed;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: label,
    builder: (context, down) => Container(
      height: 48,
      decoration: BoxDecoration(
        color: down ? pressed : background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          MusubiIcon(icon, size: 19, color: ink),
          Text(
            label,
            style: MusubiType.style(15, weight: FontWeight.w700, color: ink),
          ),
        ],
      ),
    ),
  );
}

/// "Entrega solo después de verificar" (candado).
class _SellerNote extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 6,
      children: [
        MusubiIcon(
          MusubiIcons.lock,
          size: 14,
          strokeWidth: 2.2,
          color: c.textSecondary,
        ),
        Flexible(
          child: Text(
            'Entrega solo después de verificar',
            style: MusubiType.style(
              12.5,
              weight: FontWeight.w600,
              line: 17,
              color: c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const new({required this.tab});

  final ReservationTab tab;

  @override
  Widget build(BuildContext context) => switch (tab) {
    ReservationTab.buyer => EmptyView(
      title: 'Aún no apartas nada',
      message:
          'Aparta un producto desde su publicación: te lo guardan 24 h y '
          'pagas al recogerlo.',
      icon: MusubiIcons.bookmark,
      actionLabel: 'Ver productos',
      onAction: () => context.go(AppRoutes.home),
    ),
    ReservationTab.seller => const EmptyView(
      title: 'Nadie te ha apartado algo',
      message:
          'Cuando alguien aparte tu producto, aquí verificas su QR o su '
          'código para entregarlo.',
      icon: MusubiIcons.qrCode,
    ),
  };
}

/// "Mis apartados" de `Perfil`: tarjeta oscura con el QR, "1 por recoger hoy
/// · 1 te apartaron" y la flecha.
class MyReservationsTile extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final now = ref.watch(clockProvider)().toLocal();
    final mine = ref.watch(myReservationsProvider(ReservationTab.buyer)).value;
    final theirs = ref
        .watch(myReservationsProvider(ReservationTab.seller))
        .value;
    final toPick = [...?mine?.items.where((r) => r.active)];
    final toDeliver = [...?theirs?.items.where((r) => r.active)].length;
    final today = toPick.every(
      (r) => DateUtils.isSameDay(r.pickupAt.toLocal(), now),
    );
    final parts = [
      if (toPick.isNotEmpty)
        '${toPick.length} por recoger${today ? ' hoy' : ''}',
      if (toDeliver > 0) '$toDeliver te apartaron',
    ];
    final subtitle = parts.isEmpty
        ? 'Lo que apartas y lo que te apartan'
        : parts.join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Pressable(
        key: const Key('profile-reservations'),
        onTap: () => unawaited(context.push(AppRoutes.myReservations)),
        semanticLabel: 'Mis apartados, $subtitle',
        builder: (context, pressed) => Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          decoration: BoxDecoration(
            color: pressed ? c.textSecondary : c.textPrimary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.qrCode,
                    size: 22,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: [
                    Text(
                      'Mis apartados',
                      style: MusubiType.style(
                        15,
                        weight: FontWeight.w800,
                        line: 20,
                        color: c.background,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        12.5,
                        weight: FontWeight.w600,
                        line: 17,
                        color: c.isDark ? c.textSecondary : c.neutralStrong,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                height: 44,
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.chevronRight,
                    size: 20,
                    strokeWidth: 2.2,
                    color: c.background,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
