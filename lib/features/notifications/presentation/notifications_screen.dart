import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_dialog.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';
import 'package:musubi_app/features/notifications/presentation/notification_providers.dart';

/// Pregunta por los avisos en contexto (L-16f): la primera vez que la persona
/// manda un mensaje, crea un pedido o publica una solicitud. Una sola vez.
Future<void> askForPushInContext(BuildContext context, WidgetRef ref) async {
  final coordinator = ref.read(pushCoordinatorProvider);
  if (!await coordinator.shouldAsk() || !context.mounted) return;
  final yes = await showMusubiDialog(
    context,
    icon: MusubiIcons.bell,
    title: '¿Te avisamos?',
    message:
        'Te avisamos cuando te respondan, cuando llegue un pedido y cuando tu '
        'solicitud esté por vencer. Puedes apagarlo en Android cuando quieras.',
    confirmLabel: 'Activar avisos',
    cancelLabel: 'Ahora no',
    confirmKey: const Key('push-ask-yes'),
  );
  await (yes ? coordinator.request() : coordinator.decline());
}

/// `Notificaciones` (HU-31): pestanas, "Marcar leidas", Hoy, Ayer y antes;
/// tocar un aviso abre lo que corresponde.
class NotificationsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationTab _tab = NotificationTab.all;

  Future<void> _readAll() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
    } on ApiFailure {
      return;
    }
    ref
      ..invalidate(notificationsProvider)
      ..invalidate(unreadNotificationsProvider);
  }

  Future<void> _open(AppNotification n) async {
    final route = routeFor(n.target, n.targetId);
    if (!n.read) {
      unawaited(
        ref
            .read(notificationRepositoryProvider)
            .markRead(n.id)
            .then((_) {
              ref
                ..invalidate(notificationsProvider)
                ..invalidate(unreadNotificationsProvider);
            })
            .catchError((Object _) {}),
      );
    }
    if (route != null) await context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final page = ref.watch(notificationsProvider(_tab));
    final now = ref.watch(clockProvider)().toLocal();
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Pressable(
                    onTap: () => context.pop(),
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
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Notificaciones',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          17,
                          weight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Pressable(
                    key: const Key('notifications-read-all'),
                    onTap: () => unawaited(_readAll()),
                    semanticLabel: 'Marcar leídas',
                    builder: (context, _) => SizedBox(
                      height: MusubiSizes.minTouch,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Center(
                          child: Text(
                            'Marcar leídas',
                            style: MusubiType.style(
                              13.5,
                              weight: FontWeight.w700,
                              color: c.brandText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                spacing: 8,
                children: [
                  for (final tab in NotificationTab.values)
                    _TabChip(
                      tab: tab,
                      selected: tab == _tab,
                      onTap: () => setState(() => _tab = tab),
                    ),
                ],
              ),
            ),
            Expanded(
              child: switch (page) {
                AsyncData(:final value) when value.items.isEmpty => _Empty(
                  tab: _tab,
                ),
                AsyncData(:final value) => _List(
                  items: value.items,
                  now: now,
                  onOpen: (n) => unawaited(_open(n)),
                ),
                AsyncError(:final error) => ErrorView(
                  message: error is ApiFailure
                      ? error.message
                      : 'No pudimos cargar tus avisos.',
                  onRetry: () => ref.invalidate(notificationsProvider(_tab)),
                ),
                _ => const LoadingView(message: 'Cargando avisos…'),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const new({required this.tab, required this.selected, required this.onTap});

  final NotificationTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      key: Key('notifications-tab-${tab.name}'),
      onTap: onTap,
      semanticLabel: tab.label,
      selected: selected,
      builder: (context, _) => SizedBox(
        height: MusubiSizes.minTouch,
        child: Center(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? c.inverse : null,
              borderRadius: BorderRadius.circular(999),
              border: selected ? null : Border.all(color: c.border, width: 1.5),
            ),
            child: Center(
              child: Text(
                tab.label,
                style: MusubiType.style(
                  13.5,
                  weight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? c.onBrand : c.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avisos agrupados en Hoy, Ayer y Antes.
class _List extends StatelessWidget {
  const new({required this.items, required this.now, required this.onOpen});

  final List<AppNotification> items;
  final DateTime now;
  final ValueChanged<AppNotification> onOpen;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(now);
    String group(AppNotification n) {
      final day = DateUtils.dateOnly(n.createdAt.toLocal());
      final diff = today.difference(day).inDays;
      return diff <= 0 ? 'Hoy' : (diff == 1 ? 'Ayer' : 'Antes');
    }

    final children = <Widget>[];
    String? current;
    for (final n in items) {
      final g = group(n);
      if (g != current) {
        current = g;
        children.add(_GroupTitle(g));
      }
      children.add(_Row(notification: n, now: now, onTap: () => onOpen(n)));
    }
    return ListView(
      key: const Key('notifications-list'),
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
    child: Text(
      text.toUpperCase(),
      style: MusubiType.style(
        12,
        weight: FontWeight.w800,
        em: 0.08,
        color: context.musubi.textSecondary,
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const new({
    required this.notification,
    required this.now,
    required this.onTap,
  });

  final AppNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final n = notification;
    final (icon, background, ink) = switch (n.type) {
      'order_created' => (MusubiIcons.package, c.successSoft, c.successText),
      'agreement_confirmed' ||
      'offer_accepted' => (MusubiIcons.handshake, c.successSoft, c.successText),
      'offer_received' ||
      'offer_rejected' => (MusubiIcons.hand, c.brandSoft, c.brand),
      'request_expiring' ||
      'request_expired' => (MusubiIcons.clock, c.warningSoft, c.warningText),
      _ => (MusubiIcons.bell, c.surface, c.textPrimary),
    };
    final at = n.createdAt.toLocal();
    final today = DateUtils.dateOnly(now) == DateUtils.dateOnly(at);
    return Pressable(
      key: Key('notification-${n.id}'),
      onTap: onTap,
      semanticLabel: n.read ? n.title : '${n.title}, no leída',
      builder: (context, _) => Container(
        color: n.read ? null : c.brandFaint,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: MusubiIcon(icon, size: 22, strokeWidth: 1.9, color: ink),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: MusubiType.style(
                            14.5,
                            weight: n.read ? FontWeight.w700 : FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        today ? clockTime(at) : shortDay(at, now),
                        style: MusubiType.style(
                          12,
                          weight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    n.body,
                    style: MusubiType.style(
                      13,
                      line: 18,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 8,
              child: n.read
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        key: const Key('notification-unread'),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.brand,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "ayer", "lun", "28/10".
String shortDay(DateTime at, DateTime now) {
  final diff = DateUtils.dateOnly(now)
      .difference(DateUtils.dateOnly(at))
      .inDays;
  if (diff == 1) return 'ayer';
  if (diff < 7) {
    const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return days[at.weekday - 1];
  }
  return '${at.day}/${at.month.toString().padLeft(2, '0')}';
}

class _Empty extends StatelessWidget {
  const new({required this.tab});

  final NotificationTab tab;

  @override
  Widget build(BuildContext context) => EmptyView(
    icon: MusubiIcons.bell,
    title: 'Sin avisos por ahora',
    message: switch (tab) {
      NotificationTab.matches =>
        'Aquí verás cuando alguien busque algo que vendes.',
      NotificationTab.orders => 'Aquí verás tus pedidos y acuerdos.',
      NotificationTab.requests =>
        'Aquí verás las ofertas a tus solicitudes y cuándo vencen.',
      NotificationTab.all =>
        'Aquí verás tus pedidos, ofertas y solicitudes por vencer.',
    },
  );
}
