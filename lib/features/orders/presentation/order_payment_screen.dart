import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

/// "Tu pedido" (`Pedido-pago`, HU-23): el estado (Pendiente, Confirmado,
/// Completado o Cancelado), lo que se compra con su entrega y "¿Cómo quieres
/// pagar?". La transferencia sale deshabilitada ("… aún no registra su
/// cuenta") hasta HU-55; "Confirmar pago en efectivo" lo registra (RN-18).
/// HU-24 ("Tu venta" para quien vende): "Aceptar pedido" cuando ya se eligio
/// el pago, "Confirmar entrega" de cada parte (`Pedido-entrega`) y "Rechazar"
/// o "Cancelar pedido" con un motivo de la lista (`Pedido-efectivo`).
/// NOTE (HU-55): `Pago-transferencia` y el codigo de entrega
/// (`Pedido-efectivo`). NOTE (HU-27): "Calificar" al completarse.
class OrderPaymentScreen extends ConsumerStatefulWidget {
  const new({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends ConsumerState<OrderPaymentScreen> {
  bool _paying = false;

  /// La accion de HU-24 en curso (gira su boton y no acepta otro toque).
  _Action? _busy;

  Future<void> _act(
    Order order,
    _Action action,
    Future<Order> Function() call,
    String done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = action);
    try {
      await call();
      if (!mounted) return;
      ref
        ..invalidate(orderProvider(order.id))
        ..invalidate(openOrderProvider(order.conversationId));
      showMusubiSnack(messenger, done, icon: MusubiIcons.circleCheck);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _accept(Order order) => _act(
    order,
    _Action.accept,
    () => ref.read(orderRepositoryProvider).accept(order.id),
    'Pedido aceptado. Le avisamos a ${_first(order.buyerName)}.',
  );

  Future<void> _handover(Order order) => _act(
    order,
    _Action.handover,
    () => ref.read(orderRepositoryProvider).confirmHandover(order.id),
    'Listo: confirmaste la entrega.',
  );

  Future<void> _cancel(Order order) async {
    final rejecting = !order.isBuyer && order.status == OrderStatus.pending;
    final reason = await showMusubiPanel<CancelReason>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('order-cancel-reasons'),
        title: rejecting ? 'Rechazar pedido' : 'Cancelar pedido',
        bodyInset: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MusubiOptions<CancelReason>(
              plain: true,
              options: [
                for (final reason
                    in order.isBuyer
                        ? CancelReason.forBuyer
                        : CancelReason.forSeller)
                  MusubiOption(value: reason, label: reason.label),
              ],
              onPick: (reason) => Navigator.of(context).pop(reason),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: PanelNote(
                'Elige el motivo. Le avisaremos a '
                '${_first(order.otherName)}.',
              ),
            ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    await _act(
      order,
      _Action.cancel,
      () => ref.read(orderRepositoryProvider).cancel(order.id, reason),
      rejecting ? 'Rechazaste el pedido.' : 'Cancelaste el pedido.',
    );
  }

  Future<void> _payCash(Order order) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _paying = true);
    try {
      await ref.read(orderRepositoryProvider).payCash(order.id);
      if (!mounted) return;
      ref
        ..invalidate(orderProvider(order.id))
        ..invalidate(openOrderProvider(order.conversationId));
      showMusubiSnack(
        messenger,
        'Listo: pagas en efectivo al recibir.',
        icon: MusubiIcons.circleCheck,
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _help(Order order) => showMusubiPanel<void>(
    context,
    builder: (context) => MusubiPanel(
      key: const Key('order-help'),
      title: '¿Cómo funciona tu pedido?',
      actions: [
        MusubiButton(
          label: 'Entendido',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Text(
        order.isBuyer
            ? 'Tu pedido queda Pendiente hasta que '
                  '${_first(order.sellerName)} lo acepte. Se ven en '
                  '${order.pointName} el día acordado y pagas al recibir. '
                  'Cuando los dos confirmen la entrega, se completa. Musubi '
                  'no cobra comisión ni procesa el dinero.'
            : 'Acepta el pedido cuando ${_first(order.buyerName)} elija cómo '
                  'pagar: la pieza queda apartada. Se ven en '
                  '${order.pointName} el día acordado y, cuando los dos '
                  'confirmen la entrega, se completa. Musubi no cobra '
                  'comisión ni procesa el dinero.',
        style: MusubiType.style(
          14,
          line: 20,
          color: context.musubi.textSecondary,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final order = ref.watch(orderProvider(widget.orderId));
    return Scaffold(
      backgroundColor: c.background,
      body: switch (order) {
        AsyncData(:final value) => _Body(
          order: value,
          paying: _paying,
          busy: _busy,
          onBack: () => context.pop(),
          onHelp: () => unawaited(_help(value)),
          onPayCash: () => unawaited(_payCash(value)),
          onAccept: () => unawaited(_accept(value)),
          onHandover: () => unawaited(_handover(value)),
          onCancel: () => unawaited(_cancel(value)),
        ),
        AsyncError(:final error) => SafeArea(
          child: ErrorView(
            message: error is ApiFailure
                ? error.message
                : 'No pudimos cargar tu pedido.',
            onRetry: () => ref.invalidate(orderProvider(widget.orderId)),
          ),
        ),
        _ => const Center(child: MusubiSpinner()),
      },
    );
  }
}

String _first(String name) => name.trim().split(RegExp(r'\s+')).first;

/// Las acciones de HU-24.
enum _Action { accept, handover, cancel }

class _Body extends StatelessWidget {
  const new({
    required this.order,
    required this.paying,
    required this.busy,
    required this.onBack,
    required this.onHelp,
    required this.onPayCash,
    required this.onAccept,
    required this.onHandover,
    required this.onCancel,
  });

  final Order order;
  final bool paying;
  final _Action? busy;
  final VoidCallback onBack;
  final VoidCallback onHelp;
  final VoidCallback onPayCash;
  final VoidCallback onAccept;
  final VoidCallback onHandover;
  final VoidCallback onCancel;

  /// El aviso gris debajo del pedido: como se paga, que falta y como termino.
  (MusubiIconData, String) _notice() {
    final buyer = _first(order.buyerName);
    final other = _first(order.otherName);
    final cancellation = order.cancellation;
    switch (order.status) {
      case OrderStatus.cancelled:
        final reason = cancellation?.reason.label ?? 'Otro motivo';
        final who = switch (cancellation) {
          OrderCancellation(bySystem: true) => 'Se canceló',
          OrderCancellation(:final byBuyer) when byBuyer == order.isBuyer =>
            'Cancelaste',
          _ => '$other canceló',
        };
        return (MusubiIcons.circleX, '$who el pedido: $reason.');
      case OrderStatus.completed:
        return (
          MusubiIcons.circleCheck,
          'Pedido completado. ¡Gracias por usar Musubi!',
        );
      case OrderStatus.confirmed:
        if (order.iConfirmed) {
          return (
            MusubiIcons.clock,
            'Ya confirmaste la entrega. Falta que $other la confirme.',
          );
        }
        final otherConfirmed = order.isBuyer
            ? order.sellerConfirmed
            : order.buyerConfirmed;
        if (otherConfirmed) {
          return (
            MusubiIcons.circleCheck,
            order.isBuyer
                ? '$other marcó el pedido como entregado. Confírmalo cuando '
                      'lo tengas.'
                : '$other confirmó que lo recibió. Confirma que lo '
                      'entregaste.',
          );
        }
        return (
          MusubiIcons.banknote,
          order.isBuyer
              ? 'Pedido aceptado. Pagas en efectivo al recibir.'
              : '$buyer pagará en efectivo al recibir.',
        );
      case OrderStatus.pending:
        if (order.isBuyer) {
          return (MusubiIcons.banknote, 'Pagas en efectivo al recibir.');
        }
        return order.paysCash
            ? (
                MusubiIcons.banknote,
                '$buyer pagará en efectivo al recibir. Acepta el pedido para '
                    'apartar la pieza.',
              )
            : (
                MusubiIcons.clock,
                '$buyer aún no elige cómo pagar. Podrás aceptar el pedido '
                    'cuando lo elija.',
              );
    }
  }

  /// El boton principal segun el estado y quien mira.
  Widget _primary() {
    final choosing = order.isBuyer && order.status == OrderStatus.pending;
    if (choosing && !order.paysCash) {
      return MusubiButton(
        key: const Key('order-pay-cash-confirm'),
        label: 'Confirmar pago en efectivo',
        loadingLabel: 'Confirmando…',
        loading: paying,
        onPressed: paying ? null : onPayCash,
      );
    }
    if (!order.isBuyer && order.status == OrderStatus.pending) {
      return MusubiButton(
        key: const Key('order-accept'),
        label: 'Aceptar pedido',
        loadingLabel: 'Aceptando…',
        loading: busy == _Action.accept,
        icon: MusubiIcons.circleCheck,
        iconSize: 20,
        iconStrokeWidth: 2.2,
        dimmed: !order.paysCash,
        onPressed: order.paysCash && busy == null ? onAccept : null,
      );
    }
    if (order.status == OrderStatus.confirmed && !order.iConfirmed) {
      return MusubiButton(
        key: const Key('order-handover'),
        label: order.isBuyer ? 'Confirmar entrega' : 'Marcar como entregado',
        loadingLabel: 'Confirmando…',
        loading: busy == _Action.handover,
        icon: MusubiIcons.circleCheck,
        iconSize: 20,
        iconStrokeWidth: 2.2,
        onPressed: busy == null ? onHandover : null,
      );
    }
    return MusubiButton(
      key: const Key('order-back-to-chat'),
      label: 'Volver al chat',
      kind: MusubiButtonKind.secondary,
      icon: MusubiIcons.messageCircle,
      onPressed: onBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final seller = _first(order.sellerName);
    final buyer = order.isBuyer;
    final at = order.deliveryAt.toLocal();
    final choosing = buyer && order.status == OrderStatus.pending;
    final total = formatPrice(order.item.totalCents);
    final bottom = math.max<double>(
      30,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _IconButton(
                  icon: MusubiIcons.chevronLeft,
                  size: 24,
                  label: 'Regresar',
                  onTap: onBack,
                ),
                Column(
                  children: [
                    Text(
                      buyer ? 'Tu pedido' : 'Tu venta',
                      style: MusubiType.style(
                        17,
                        weight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      '#${order.number}',
                      style: MusubiType.style(
                        12,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
                _IconButton(
                  key: const Key('order-help-button'),
                  icon: MusubiIcons.circleHelp,
                  size: 22,
                  label: 'Ayuda',
                  onTap: onHelp,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Stepper(status: order.status),
                const SizedBox(height: 12),
                _ItemCard(order: order, at: at),
                if (choosing) ...[
                  const SizedBox(height: 18),
                  Semantics(
                    header: true,
                    child: Text(
                      '¿Cómo quieres pagar?',
                      style: MusubiType.style(
                        16,
                        line: 21,
                        weight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'El pago va directo a $seller. Elige una opción.',
                    style: MusubiType.style(
                      13,
                      line: 18,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PayOption(
                    key: const Key('order-pay-transfer'),
                    icon: MusubiIcons.arrowRightLeft,
                    iconColor: c.brand,
                    iconBackground: c.brandSoft,
                    title: 'Transferencia',
                    subtitle: 'Pagas ahora desde la app de tu banco',
                    chip: '$seller aún no registra su cuenta',
                    chipBackground: c.mutedChip,
                    selected: false,
                    enabled: order.transferAvailable,
                  ),
                  const SizedBox(height: 8),
                  _PayOption(
                    key: const Key('order-pay-cash'),
                    icon: MusubiIcons.banknote,
                    iconColor: c.successText,
                    iconBackground: c.successSoft,
                    title: 'Efectivo al entregar',
                    subtitle: 'Pagas en persona al recibir en el campus',
                    chip: 'Siempre disponible',
                    chipBackground: c.surface,
                    selected: true,
                    enabled: true,
                  ),
                  const SizedBox(height: 12),
                  _HowItWorks(
                    steps: [
                      'Se ven en ${order.pointName} el ${shortDate(at)}',
                      'Revisas que todo esté bien y le pagas $total',
                      'Los dos confirman la entrega y se completa tu pedido',
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 18),
                  _Notice(icon: _notice().$1, text: _notice().$2),
                  if (order.status == OrderStatus.confirmed &&
                      order.isBuyer &&
                      !order.iConfirmed) ...[
                    const SizedBox(height: 10),
                    const _Hint(
                      'Revisa el producto antes de confirmar la entrega.',
                    ),
                  ],
                ],
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
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Row(
                  spacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: MusubiType.style(
                            12,
                            weight: FontWeight.w700,
                            color: c.textSecondary,
                          ),
                        ),
                        Text(
                          formatPrice(order.item.totalCents),
                          style: MusubiType.style(
                            22,
                            weight: FontWeight.w800,
                            em: -0.02,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Expanded(child: _primary()),
                  ],
                ),
                if (order.status.open)
                  MusubiButton(
                    key: const Key('order-cancel'),
                    label: !buyer && order.status == OrderStatus.pending
                        ? 'Rechazar pedido'
                        : 'Cancelar pedido',
                    loadingLabel: 'Cancelando…',
                    loading: busy == _Action.cancel,
                    kind: MusubiButtonKind.quiet,
                    height: 44,
                    icon: MusubiIcons.circleX,
                    iconSize: 16,
                    iconStrokeWidth: 2.2,
                    fontSize: 14,
                    gap: 6,
                    foreground: c.error,
                    onPressed: busy == null ? onCancel : null,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.size,
    required this.label,
    required this.onTap,
    super.key,
  });

  final MusubiIconData icon;
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: label,
    builder: (context, _) => SizedBox.square(
      dimension: MusubiSizes.minTouch,
      child: Center(
        child: MusubiIcon(
          icon,
          size: size,
          strokeWidth: 1.9,
          color: context.musubi.textPrimary,
        ),
      ),
    ),
  );
}

/// Pendiente → Confirmado → Completado, y Cancelado aparte (punteado).
class _Stepper extends StatelessWidget {
  const new({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    const steps = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.completed,
    ];
    final reached = steps.indexOf(status);
    return Semantics(
      label: 'Estado del pedido: ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      top: 13,
                      left: 0,
                      right: 0,
                      child: FractionallySizedBox(
                        widthFactor: 2 / 3,
                        child: Container(height: 2, color: c.border),
                      ),
                    ),
                    Row(
                      children: [
                        for (final (i, step) in steps.indexed)
                          Expanded(
                            child: _Step(
                              label: step.label,
                              state: i < reached
                                  ? _StepState.done
                                  : i == reached
                                  ? _StepState.current
                                  : _StepState.next,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: c.border,
              ),
              SizedBox(
                width: 72,
                child: _Step(
                  label: OrderStatus.cancelled.label,
                  state: status == OrderStatus.cancelled
                      ? _StepState.cancelled
                      : _StepState.cancellable,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StepState { done, current, next, cancellable, cancelled }

class _Step extends StatefulWidget {
  const new({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  State<_Step> createState() => _StepState2();
}

// El paso actual late como en la maqueta (`Pedido-pago__pulse`, 2 s), tres
// veces y no sin fin.
class _StepState2 extends State<_Step> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    if (widget.state == _StepState.current) {
      _pulse.repeat(count: 3);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final state = widget.state;
    final current = state == _StepState.current;
    final circle = switch (state) {
      _StepState.current => AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          // 0 → 50 % crece la sombra a 6 px y se apaga; 50 → 100 % vuelve.
          final t = _pulse.value;
          final spread = t <= 0.5 ? 6 * (t / 0.5) : 6 * ((1 - t) / 0.5);
          final alpha = t <= 0.5
              ? 0.45 * (1 - t / 0.5)
              : 0.45 * ((t - 0.5) / 0.5);
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c.background,
              shape: BoxShape.circle,
              border: Border.all(color: c.warning, width: 2),
              boxShadow: [
                BoxShadow(
                  color: c.warning.withValues(alpha: alpha),
                  spreadRadius: spread,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Center(
          child: MusubiIcon(
            MusubiIcons.clock,
            size: 14,
            strokeWidth: 2.6,
            color: c.warningText,
          ),
        ),
      ),
      _StepState.done => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
        child: Center(
          child: MusubiIcon(
            MusubiIcons.check,
            size: 14,
            strokeWidth: 3,
            color: c.onBrand,
          ),
        ),
      ),
      _StepState.next => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c.background,
          shape: BoxShape.circle,
          border: Border.all(color: c.borderStrong, width: 2),
        ),
      ),
      _StepState.cancellable => SizedBox.square(
        dimension: 28,
        child: CustomPaint(
          painter: _DashedCircle(color: c.neutralStrong),
          child: Center(
            child: MusubiIcon(
              MusubiIcons.x,
              size: 13,
              strokeWidth: 2.6,
              color: c.chevron,
            ),
          ),
        ),
      ),
      _StepState.cancelled => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
        child: Center(
          child: MusubiIcon(
            MusubiIcons.x,
            size: 13,
            strokeWidth: 2.6,
            color: c.onBrand,
          ),
        ),
      ),
    };
    return Column(
      spacing: 6,
      children: [
        circle,
        Text(
          widget.label,
          style: MusubiType.style(
            11.5,
            weight: current || state == _StepState.cancelled
                ? FontWeight.w800
                : FontWeight.w600,
            color: switch (state) {
              _StepState.current => c.warningText,
              _StepState.cancelled => c.error,
              _ => c.textSecondary,
            },
          ),
        ),
      ],
    );
  }
}

/// `border: 2px dashed` de un circulo de 28.
class _DashedCircle extends CustomPainter {
  const new({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Offset.zero & size;
    const dashes = 12;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(1), i * sweep, sweep / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle oldDelegate) => oldDelegate.color != color;
}

/// La foto, el nombre, quien vende (con su palomita), el precio y la entrega.
class _ItemCard extends StatelessWidget {
  const new({required this.order, required this.at});

  final Order order;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final item = order.item;
    final who = order.isBuyer
        ? 'Vende ${order.sellerName}'
        : 'Compra ${order.buyerName}';
    final quantity = item.quantity > 1 ? ' · ${item.quantity} piezas' : '';
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              spacing: 12,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 50,
                    child: ProductPhoto(url: item.photoUrl),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          14,
                          weight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      Row(
                        spacing: 4,
                        children: [
                          Flexible(
                            child: Text(
                              '$who$quantity',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MusubiType.style(
                                12.5,
                                weight: FontWeight.w600,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          if (order.isBuyer) const VerifiedBadge(size: 13),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    formatPrice(item.totalCents),
                    style: MusubiType.style(
                      16,
                      weight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: c.border,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                MusubiIcon(MusubiIcons.mapPin, size: 15, color: c.brand),
                Expanded(
                  child: Text(
                    'Entrega: ${order.pointName} · ${shortDate(at)}, '
                    '${clockTime(at)}'
                    '${order.detail == null ? '' : '\n${order.detail}'}',
                    style: MusubiType.style(
                      12.5,
                      weight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una forma de pago (`role=radio`): borde rojo si esta elegida y al 55 %
/// si no se puede elegir.
class _PayOption extends StatelessWidget {
  const new({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.chip,
    required this.chipBackground,
    required this.selected,
    required this.enabled,
    super.key,
  });

  final MusubiIconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String chip;
  final Color chipBackground;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: title,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? c.brand : c.border, width: 2),
          ),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: MusubiIcon(
                    icon,
                    size: 21,
                    strokeWidth: 1.9,
                    color: iconColor,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      title,
                      style: MusubiType.style(
                        15,
                        line: 20,
                        weight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: MusubiType.style(
                        12.5,
                        line: 17,
                        color: c.textSecondary,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: chipBackground,
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusChip,
                        ),
                      ),
                      child: Text(
                        chip,
                        style: MusubiType.style(
                          11,
                          weight: FontWeight.w800,
                          color: c.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.brand : c.neutralStrong,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Así funciona": tres pasos con su numero en negro (sube 6 px al entrar).
class _HowItWorks extends StatelessWidget {
  const new({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text(
              'ASÍ FUNCIONA',
              style: MusubiType.style(
                11.5,
                weight: FontWeight.w800,
                em: 0.08,
                color: c.textSecondary,
              ),
            ),
            for (final (i, step) in steps.indexed)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: c.inverse,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: MusubiType.style(
                          11,
                          weight: FontWeight.w800,
                          color: c.onBrand,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: MusubiType.style(
                        13,
                        line: 18,
                        weight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Aviso gris: como se paga, que falta y como termino el pedido.
class _Notice extends StatelessWidget {
  const new({required this.icon, required this.text});

  final MusubiIconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      key: const Key('order-payment-notice'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 10,
        children: [
          MusubiIcon(
            icon,
            size: 20,
            color: icon == MusubiIcons.circleX ? c.error : c.successText,
          ),
          Expanded(
            child: Text(
              text,
              style: MusubiType.style(
                13.5,
                line: 19,
                weight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Revisa que la calculadora funcione antes de confirmar." (`Pedido-entrega`):
/// gris de 12.5 con el icono de informacion.
class _Hint extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Row(
      spacing: 8,
      children: [
        MusubiIcon(
          MusubiIcons.info,
          size: 16,
          strokeWidth: 1.9,
          color: c.textSecondary,
        ),
        Expanded(
          child: Text(
            text,
            style: MusubiType.style(
              12.5,
              line: 18,
              weight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
