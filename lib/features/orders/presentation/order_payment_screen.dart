import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
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
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/delivery_actions.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/orders/presentation/payment_widgets.dart';

/// "Tu pedido" (`Pedido-pago`, HU-23): el estado (Pendiente, Confirmado,
/// Completado o Cancelado), lo que se compra con su entrega y "¿Cómo quieres
/// pagar?". HU-55 (D-01): "Transferencia" (si quien vende registro su cuenta)
/// lleva a `Pago-transferencia`; con la referencia enviada, `Pago-validando`
/// para quien compra y `Pago-vendedor` ("Sí, me llegó el pago" / "Todavía no
/// me llega") para quien vende. En efectivo, al aceptarse quien compra ve su
/// codigo de entrega (`Pedido-efectivo`) y quien vende lo escribe para
/// completar el pedido. HU-24 ("Tu venta"): "Aceptar pedido", "Confirmar
/// entrega" de cada parte (`Pedido-entrega`) y "Rechazar" o "Cancelar pedido"
/// con un motivo de la lista. Completado y dentro del plazo: "Calificar a
/// Diego" (HU-27, HU-45); al completarse, abre `Calificar` como la maqueta.
class OrderPaymentScreen extends ConsumerStatefulWidget {
  const new({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends ConsumerState<OrderPaymentScreen> {
  bool _paying = false;

  /// "¿Cómo quieres pagar?": `true` transferencia, `false` efectivo y `null`
  /// lo que diga el pedido (transferencia si quien vende tiene cuenta).
  bool? _transfer;

  /// El codigo de entrega que escribe quien vende (HU-55).
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool _transferSelected(Order order) =>
      order.transferAvailable &&
      (_transfer ?? (order.paysTransfer || !order.paysCash));

  /// "Ver datos para transferir" (HU-55): registra la transferencia (si aun
  /// no) y abre `Pago-transferencia`.
  Future<void> _payTransfer(Order order) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (!order.paysTransfer) {
      setState(() => _paying = true);
      try {
        await ref.read(orderRepositoryProvider).payTransfer(order.id);
        if (!mounted) return;
        ref
          ..invalidate(orderProvider(order.id))
          ..invalidate(openOrderProvider(order.conversationId));
      } on ApiFailure catch (failure) {
        if (!mounted) return;
        showMusubiSnack(
          messenger,
          failure.message,
          icon: MusubiIcons.circleAlert,
          tone: SnackTone.warn,
        );
        return;
      } finally {
        if (mounted) setState(() => _paying = false);
      }
    }
    unawaited(router.push(AppRoutes.transfer(order.id)));
  }

  /// "Todavía no me llega" (HU-55, quien vende).
  Future<void> _notReceived(Order order) async {
    await _act(
      order,
      _Action.notReceived,
      () => ref.read(orderRepositoryProvider).transferNotReceived(order.id),
      'Le avisamos a ${_first(order.buyerName)} que todavía no te llega.',
    );
  }

  /// El codigo de entrega (HU-55, efectivo): con el correcto se completa y,
  /// como al confirmar la entrega, abre `Calificar`.
  Future<void> _enterCode(Order order) async {
    final code = _code.text;
    if (code.length != 4 || _busy != null) return;
    final changed = await _act(
      order,
      _Action.code,
      () => ref.read(orderRepositoryProvider).deliveryCode(order.id, code),
      'Listo: el pedido quedó completado.',
    );
    if (!mounted) return;
    if (changed == null) {
      // Un codigo equivocado gasta un intento: se recarga para mostrarlos.
      _code.clear();
      ref.invalidate(orderProvider(order.id));
      return;
    }
    if (changed.canRate(ref.read(clockProvider)())) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      unawaited(context.push(AppRoutes.rate(changed.id)));
    }
  }

  void _chat(Order order) =>
      unawaited(context.push(AppRoutes.conversation(order.conversationId)));

  /// La accion de HU-24 en curso (gira su boton y no acepta otro toque).
  _Action? _busy;

  /// Corre una accion de HU-24; regresa el pedido como quedo, o `null` si
  /// fallo.
  Future<Order?> _act(
    Order order,
    _Action action,
    Future<Order> Function() call,
    String done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = action);
    try {
      final changed = await call();
      if (!mounted) return null;
      ref
        ..invalidate(orderProvider(order.id))
        ..invalidate(openOrderProvider(order.conversationId));
      showMusubiSnack(messenger, done, icon: MusubiIcons.circleCheck);
      return changed;
    } on ApiFailure catch (failure) {
      if (!mounted) return null;
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
      return null;
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _accept(Order order) async {
    await _act(
      order,
      _Action.accept,
      () => ref.read(orderRepositoryProvider).accept(order.id),
      'Pedido aceptado. Le avisamos a ${_first(order.buyerName)}.',
    );
  }

  Future<void> _handover(Order order) async {
    final changed = await _act(
      order,
      _Action.handover,
      () => ref.read(orderRepositoryProvider).confirmHandover(order.id),
      'Listo: confirmaste la entrega.',
    );
    // Con las dos confirmaciones se completa: como la maqueta, a `Calificar`.
    if (changed != null &&
        mounted &&
        changed.canRate(ref.read(clockProvider)())) {
      // Sin el aviso de "Listo": taparia "Ahora no" (la maqueta pasa directo).
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      unawaited(context.push(AppRoutes.rate(changed.id)));
    }
  }

  void _rate(Order order) => unawaited(context.push(AppRoutes.rate(order.id)));

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
                  '${_first(order.sellerName)} lo acepte. Puedes pagar por '
                  'transferencia a su cuenta registrada o en efectivo al '
                  'recibir; en efectivo, al entregarte el producto le das tu '
                  'código y se completa. Musubi no cobra comisión ni procesa '
                  'el dinero.'
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
          transferSelected: _transferSelected(value),
          onSelect: (transfer) => setState(() => _transfer = transfer),
          onPayTransfer: () => unawaited(_payTransfer(value)),
          onNotReceived: () => unawaited(_notReceived(value)),
          code: _code,
          onEnterCode: () => unawaited(_enterCode(value)),
          onChat: () => _chat(value),
          onAccept: () => unawaited(_accept(value)),
          onHandover: () => unawaited(_handover(value)),
          onCancel: () => unawaited(_cancel(value)),
          onRate: () => _rate(value),
          now: ref.watch(clockProvider)(),
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

/// Las acciones de HU-24 y HU-55.
enum _Action { accept, handover, cancel, notReceived, code }

class _Body extends StatelessWidget {
  const new({
    required this.order,
    required this.paying,
    required this.busy,
    required this.onBack,
    required this.onHelp,
    required this.onPayCash,
    required this.transferSelected,
    required this.onSelect,
    required this.onPayTransfer,
    required this.onNotReceived,
    required this.code,
    required this.onEnterCode,
    required this.onChat,
    required this.onAccept,
    required this.onHandover,
    required this.onCancel,
    required this.onRate,
    required this.now,
  });

  final Order order;
  final bool paying;
  final _Action? busy;
  final VoidCallback onBack;
  final VoidCallback onHelp;
  final VoidCallback onPayCash;

  /// HU-55: la forma de pago marcada mientras se elige.
  final bool transferSelected;
  final ValueChanged<bool> onSelect;
  final VoidCallback onPayTransfer;
  final VoidCallback onNotReceived;

  /// El codigo de entrega que escribe quien vende.
  final TextEditingController code;
  final VoidCallback onEnterCode;
  final VoidCallback onChat;
  final VoidCallback onAccept;
  final VoidCallback onHandover;
  final VoidCallback onCancel;
  final VoidCallback onRate;

  /// Para saber si aun se puede calificar (HU-27).
  final DateTime now;

  bool get _pending => order.status == OrderStatus.pending;

  bool get _confirmed => order.status == OrderStatus.confirmed;

  /// Quien compra todavia elige como pagar (no ha avisado "Ya transferi").
  bool get _choosing => order.isBuyer && _pending && !order.transferReported;

  /// `Pago-validando`: quien compra ya aviso la transferencia.
  bool get _validating => order.isBuyer && _pending && order.transferReported;

  /// `Pago-vendedor`: le avisaron una transferencia a quien vende.
  bool get _sellerValidates =>
      !order.isBuyer &&
      _pending &&
      order.paysTransfer &&
      order.transferReported;

  /// Quien vende escribe el codigo de entrega (efectivo, con intentos).
  bool get _sellerEntersCode =>
      !order.isBuyer &&
      _confirmed &&
      order.paysCash &&
      !order.iConfirmed &&
      (order.codeAttemptsLeft ?? 0) > 0;

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
          order.ratedByMe
              ? 'Pedido completado. Ya calificaste a $other.'
              : 'Pedido completado. ¡Gracias por usar Musubi!',
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
        if (order.paysTransfer) {
          return (
            MusubiIcons.circleCheck,
            'Pago validado. Se ven en ${order.pointName} el '
                '${shortDate(order.deliveryAt.toLocal())}.',
          );
        }
        if ((order.codeAttemptsLeft ?? 1) == 0 && !order.isBuyer) {
          return (
            MusubiIcons.circleAlert,
            'Se acabaron los intentos del código. Confirmen la entrega los '
                'dos con el botón.',
          );
        }
        return (
          MusubiIcons.banknote,
          order.isBuyer
              ? 'Pedido aceptado. Pagas en efectivo al recibir.'
              : '$buyer pagará en efectivo al recibir. Pídele su código al '
                    'entregar.',
        );
      case OrderStatus.pending:
        if (order.isBuyer) {
          return (MusubiIcons.banknote, 'Pagas en efectivo al recibir.');
        }
        if (order.paysTransfer) {
          return (
            MusubiIcons.clock,
            '$buyer pagará por transferencia a tu cuenta. Te avisamos '
                'cuando te mande la referencia.',
          );
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
    final seller = _first(order.sellerName);
    if (_choosing && transferSelected) {
      return MusubiButton(
        key: const Key('order-pay-transfer-go'),
        label: 'Ver datos para transferir',
        loadingLabel: 'Un momento…',
        loading: paying,
        onPressed: paying ? null : onPayTransfer,
      );
    }
    if (_validating) {
      return MusubiButton(
        key: const Key('order-chat'),
        label: 'Mensaje a $seller',
        kind: MusubiButtonKind.secondary,
        icon: MusubiIcons.messageCircle,
        onPressed: onChat,
      );
    }
    if (_sellerValidates) {
      return MusubiButton(
        key: const Key('order-transfer-received'),
        label: 'Sí, me llegó el pago',
        loadingLabel: 'Confirmando…',
        loading: busy == _Action.accept,
        icon: MusubiIcons.check,
        iconSize: 20,
        iconStrokeWidth: 2.4,
        onPressed: busy == null ? onAccept : null,
      );
    }
    if (_sellerEntersCode) {
      final ready = code.text.length == 4;
      return MusubiButton(
        key: const Key('order-code-confirm'),
        label: 'Confirmar entrega',
        loadingLabel: 'Revisando…',
        loading: busy == _Action.code,
        icon: MusubiIcons.circleCheck,
        iconSize: 20,
        iconStrokeWidth: 2.2,
        dimmed: !ready,
        onPressed: ready && busy == null ? onEnterCode : null,
      );
    }
    // `Pedido-efectivo`: quien compra da su codigo; si quien vende ya marco
    // la entrega (sin intentos), confirma con el boton.
    if (order.isBuyer &&
        _confirmed &&
        order.paysCash &&
        order.deliveryCode != null &&
        !order.iConfirmed &&
        !order.sellerConfirmed) {
      return MusubiButton(
        key: const Key('order-chat'),
        label: 'Mensaje a $seller',
        kind: MusubiButtonKind.secondary,
        icon: MusubiIcons.messageCircle,
        onPressed: onChat,
      );
    }
    final choosing = _choosing;
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
      // Por transferencia se acepta al confirmar el pago (`Pago-vendedor`).
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
    if (order.canRate(now)) {
      return MusubiButton(
        key: const Key('order-rate'),
        label: 'Calificar a ${_first(order.otherName)}',
        icon: MusubiIcons.star,
        iconSize: 20,
        iconStrokeWidth: 2.2,
        onPressed: onRate,
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

  /// "Así funciona" por transferencia (maqueta `Pedido-pago`).
  static List<String> _transferSteps(String seller) {
    final last =
        '$seller confirma que le llegó y tu pedido queda '
        'confirmado';
    return [
      'Te mostramos la cuenta de $seller',
      'Transfieres y capturas la referencia',
      last,
    ];
  }

  /// "Así funciona" en efectivo (HU-55: con el codigo de entrega).
  static List<String> _cashSteps(String point, String day, String total) {
    const last = 'Le das tu código de entrega y se completa tu pedido';
    return [
      'Se ven en $point el $day',
      'Revisas que todo esté bien y le pagas $total',
      last,
    ];
  }

  /// "Total $500" junto al boton: no en `Pago-validando`, `Pago-vendedor` ni
  /// `Pedido-efectivo` (ahi el monto ya esta en la pantalla).
  bool get _showTotal => !_validating && !_sellerValidates && !_confirmed;

  /// La franja verde ya dice como se paga: el aviso gris solo sale si dice
  /// algo mas (quien confirmo la entrega o que se acabaron los intentos).
  bool get _noticeRedundant =>
      _confirmed &&
      order.paymentChosen &&
      !order.buyerConfirmed &&
      !order.sellerConfirmed &&
      (order.isBuyer || (order.codeAttemptsLeft ?? 1) > 0);

  /// "Cancelar pedido": no mientras se valida una transferencia (salvo que no
  /// haya llegado).
  bool get _showCancel =>
      !(_validating || _sellerValidates) || order.transferNotReceivedAt != null;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final seller = _first(order.sellerName);
    final buyer = order.isBuyer;
    final at = order.deliveryAt.toLocal();
    final choosing = _choosing;
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
                if (_validating)
                  ValidatingView(order: order, now: now)
                else if (_sellerValidates)
                  SellerTransferView(order: order, now: now)
                else ...[
                  _Stepper(status: order.status),
                  const SizedBox(height: 12),
                  if (_confirmed && order.paymentChosen) ...[
                    PaymentBanner(order: order),
                    const SizedBox(height: 12),
                  ],
                  if (_confirmed &&
                      order.isBuyer &&
                      order.deliveryCode != null) ...[
                    DeliveryCodeCard(
                      code: order.deliveryCode!,
                      sellerName: order.sellerName,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _ItemCard(order: order, at: at),
                  // HU-62: cuando y donde, "Agregar al calendario" y
                  // "Ya llegué".
                  if (_confirmed) ...[
                    const SizedBox(height: 12),
                    DeliveryCard(order: order, now: now),
                  ],
                  if (_sellerEntersCode) ...[
                    const SizedBox(height: 12),
                    DeliveryCodeEntry(
                      order: order,
                      controller: code,
                      onCompleted: (_) => onEnterCode(),
                    ),
                  ],
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
                      chip: order.transferAvailable
                          ? '$seller tiene su cuenta registrada'
                          : '$seller aún no registra su cuenta',
                      chipBackground: order.transferAvailable
                          ? c.successSoft
                          : c.mutedChip,
                      chipColor: order.transferAvailable ? c.successText : null,
                      chipIcon: order.transferAvailable
                          ? MusubiIcons.check
                          : null,
                      selected: transferSelected,
                      enabled: order.transferAvailable,
                      onTap: () => onSelect(true),
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
                      selected: !transferSelected,
                      enabled: true,
                      onTap: () => onSelect(false),
                    ),
                    const SizedBox(height: 12),
                    _HowItWorks(
                      key: ValueKey(transferSelected),
                      steps: transferSelected
                          ? _transferSteps(seller)
                          : _cashSteps(order.pointName, shortDate(at), total),
                    ),
                  ] else ...[
                    if (!_noticeRedundant) ...[
                      const SizedBox(height: 18),
                      _Notice(icon: _notice().$1, text: _notice().$2),
                    ],
                    if (_confirmed &&
                        order.isBuyer &&
                        order.paysCash &&
                        order.deliveryCode != null) ...[
                      const SizedBox(height: 16),
                      HandoverChecklist(title: order.item.title),
                    ] else if (_confirmed &&
                        order.isBuyer &&
                        !order.iConfirmed) ...[
                      const SizedBox(height: 10),
                      const _Hint(
                        'Revisa el producto antes de confirmar la entrega.',
                      ),
                    ],
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
                    if (_showTotal)
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
                if (_sellerValidates)
                  MusubiButton(
                    key: const Key('order-transfer-not-received'),
                    label: 'Todavía no me llega',
                    loadingLabel: 'Avisando…',
                    loading: busy == _Action.notReceived,
                    kind: MusubiButtonKind.secondary,
                    onPressed: busy == null ? onNotReceived : null,
                  ),
                if (order.status.open && _showCancel)
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
    this.chipColor,
    this.chipIcon,
    this.onTap,
    super.key,
  });

  final Color? chipColor;
  final MusubiIconData? chipIcon;
  final VoidCallback? onTap;
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
    final tap = onTap;
    final option = Semantics(
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          if (chipIcon case final icon?)
                            MusubiIcon(
                              icon,
                              size: 12,
                              strokeWidth: 2.6,
                              color: chipColor,
                            ),
                          Flexible(
                            child: Text(
                              chip,
                              style: MusubiType.style(
                                11,
                                weight: FontWeight.w800,
                                color: chipColor ?? c.textTertiary,
                              ),
                            ),
                          ),
                        ],
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
    return tap == null || !enabled
        ? option
        : Pressable(onTap: tap, builder: (context, _) => option);
  }
}

/// "Así funciona": tres pasos con su numero en negro (sube 6 px al entrar).
class _HowItWorks extends StatelessWidget {
  const new({required this.steps, super.key});

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
