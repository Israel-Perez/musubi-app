import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/product_screen.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/domain/order_repository.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_widgets.dart';

// "Resumen del acuerdo" sin IA (HU-23, decision de la usuaria del
// 10-Nov-2026): la hoja de `Acuerdo-esperando` con el producto y el precio de
// la conversacion. Quien compra elige cantidad, entrega y fecha, y "Crear
// pedido" lo deja Pendiente. Sus filas y paneles (SummaryField, QuantityPanel,
// PlacePanel y WhenPanel) los reutiliza el acuerdo con IA (HU-34). Si la IA no
// esta disponible, "Resumir acuerdo" abre esta hoja (RNF-15).

/// Primera y ultima hora de entrega del campus (la API valida lo mismo).
const orderFirstHour = 7;
const orderLastHour = 21;

/// Dias hacia adelante para elegir (la API acepta hasta 14).
const orderDays = 14;

/// Abre "Resumen del acuerdo" sobre el chat de [conversation].
Future<void> showOrderSummary(
  BuildContext context, {
  required Conversation conversation,
}) {
  final c = context.musubi;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: c.scrim,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 420),
      reverseDuration: Duration(milliseconds: 220),
      curve: musubiEaseOut,
    ),
    builder: (_) => OrderSummarySheet(conversation: conversation),
  );
}

/// La hoja (publica para las pruebas y las capturas).
class OrderSummarySheet extends ConsumerStatefulWidget {
  const new({required this.conversation, super.key});

  final Conversation conversation;

  @override
  ConsumerState<OrderSummarySheet> createState() => _OrderSummarySheetState();
}

class _OrderSummarySheetState extends ConsumerState<OrderSummarySheet> {
  int _quantity = 1;
  MeetingPoint? _point;
  String _detail = '';
  DateTime? _at;
  bool _creating = false;

  Conversation get _conversation => widget.conversation;

  bool get _complete => _point != null && _at != null;

  /// Piezas que se pueden pedir: lo disponible de la publicacion (RN-17), o
  /// hasta 10 en una oferta (la API valida la cantidad de la solicitud).
  int _max() {
    if (_conversation.context.isOffer) return 10;
    final stock = ref
        .watch(productDetailProvider(_conversation.context.id))
        .value
        ?.stock;
    return (stock ?? 1).clamp(1, 10);
  }

  Future<void> _editQuantity(int max) async {
    final picked = await showMusubiPanel<int>(
      context,
      builder: (context) => QuantityPanel(initial: _quantity, max: max),
    );
    if (picked != null && mounted) setState(() => _quantity = picked);
  }

  Future<void> _editPlace() async {
    final picked = await showMusubiPanel<(MeetingPoint, String)>(
      context,
      builder: (context) => PlacePanel(point: _point, detail: _detail),
    );
    if (picked == null || !mounted) return;
    final (point, detail) = picked;
    setState(() {
      _point = point;
      _detail = detail;
    });
  }

  Future<void> _editWhen() async {
    final now = ref.read(clockProvider)().toLocal();
    final picked = await showMusubiPanel<DateTime>(
      context,
      builder: (context) => WhenPanel(now: now, initial: _at),
    );
    if (picked != null && mounted) setState(() => _at = picked);
  }

  Future<void> _create() async {
    final point = _point;
    final at = _at;
    if (point == null || at == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final repository = ref.read(orderRepositoryProvider);
    setState(() => _creating = true);
    Order order;
    try {
      order = await repository.create(
        NewOrder(
          conversationId: _conversation.id,
          quantity: _quantity,
          meetingPoint: point.slug,
          detail: _detail.trim().isEmpty ? null : _detail.trim(),
          deliveryAt: at,
        ),
      );
    } on ApiFailure catch (failure) {
      // Un doble toque (o el pedido de otro dispositivo): se abre ese.
      final open = failure.code == 'orders.already_open'
          ? await _openOrder(repository)
          : null;
      if (!mounted) return;
      if (open == null) {
        setState(() => _creating = false);
        showMusubiSnack(
          messenger,
          failure.message,
          icon: MusubiIcons.circleAlert,
          tone: SnackTone.warn,
        );
        return;
      }
      order = open;
    }
    ref.invalidate(openOrderProvider(_conversation.id));
    navigator.pop();
    unawaited(router.push(AppRoutes.order(order.id)));
  }

  Future<Order?> _openOrder(OrderRepository repository) async {
    try {
      final orders = await repository.byConversation(_conversation.id);
      for (final order in orders) {
        if (order.status.open) return order;
      }
    } on ApiFailure {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final media = MediaQuery.of(context);
    final seller = _conversation.counterpart.firstName;
    final max = _max();
    final context0 = _conversation.context;
    final at = _at;
    final point = _point;
    return Container(
      key: const Key('order-summary'),
      height: media.size.height - 104,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MusubiSizes.radiusSheet),
        ),
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 6, 10, 0),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.brandSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: MusubiIcon(
                      MusubiIcons.handshake,
                      size: 21,
                      strokeWidth: 1.9,
                      color: c.brand,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 1,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Resumen del acuerdo',
                          style: MusubiType.style(
                            19,
                            weight: FontWeight.w800,
                            line: 24,
                            em: -0.02,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Con base en tu chat con $seller',
                        style: MusubiType.style(
                          12.5,
                          weight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Pressable(
                  key: const Key('order-summary-close'),
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SummaryField(
                            label: 'Producto',
                            value: context0.title,
                            divider: true,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: c.divider),
                              ),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(color: c.divider),
                                        ),
                                      ),
                                      child: SummaryField(
                                        label: 'Precio acordado',
                                        value: formatPrice(
                                          context0.priceCents ?? 0,
                                        ),
                                        big: true,
                                        grid: true,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SummaryField(
                                      key: const Key('order-quantity'),
                                      label: 'Cantidad',
                                      value: '$_quantity',
                                      big: true,
                                      grid: true,
                                      editLabel: 'Editar cantidad',
                                      onEdit: max > 1
                                          ? () => unawaited(_editQuantity(max))
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SummaryField(
                            key: const Key('order-place'),
                            label: 'Entrega',
                            value: point == null
                                ? null
                                : 'Campus universitario · ${point.name}',
                            sub: _detail.trim().isEmpty ? null : _detail.trim(),
                            divider: true,
                            editLabel: 'Editar entrega',
                            onEdit: () => unawaited(_editPlace()),
                          ),
                          SummaryField(
                            key: const Key('order-when'),
                            label: 'Fecha',
                            value: at == null
                                ? null
                                : '${longDate(at)} · ${clockTime(at)}',
                            editLabel: 'Editar fecha',
                            onEdit: () => unawaited(_editWhen()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        if (_complete)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: MusubiIcon(
                              MusubiIcons.lock,
                              size: 14,
                              color: c.textSecondary,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _complete
                                ? 'Al crearlo queda Pendiente hasta que '
                                      '$seller lo acepte.'
                                : 'Elige dónde y cuándo se ven. Si no lo '
                                      'saben, pregúntale a $seller en el chat.',
                            style: MusubiType.style(
                              12.5,
                              line: 18,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                30 > media.viewPadding.bottom ? 30 : media.viewPadding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  MusubiButton(
                    key: const Key('order-create'),
                    label: 'Crear pedido',
                    loadingLabel: 'Creando…',
                    icon: MusubiIcons.package,
                    loading: _creating,
                    onPressed: _complete && !_creating
                        ? () => unawaited(_create())
                        : null,
                  ),
                  Text(
                    '$seller debe aceptarlo para confirmar el pedido.',
                    textAlign: TextAlign.center,
                    style: MusubiType.style(
                      12.5,
                      weight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila del resumen (tambien la del acuerdo con IA): etiqueta y valor,
/// con el lapiz para editarlo. Sin valor es "No identificado" en ambar con
/// "Agregar" (`Acuerdo-esperando`).
class SummaryField extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    super.key,
    this.sub,
    this.big = false,
    this.grid = false,
    this.divider = false,
    this.editLabel,
    this.onEdit,
    this.badge,
  });

  final String label;

  /// `null`: "No identificado".
  final String? value;
  final String? sub;

  /// Precio y cantidad (17, peso 800).
  final bool big;

  /// Celda de la cuadricula de precio y cantidad (sin relleno a la derecha).
  final bool grid;
  final bool divider;
  final String? editLabel;
  final VoidCallback? onEdit;

  /// Etiqueta verde junto al valor ("Agregada", `Acuerdo-confirmado`).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final missing = value == null;
    final edit = onEdit;
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: EdgeInsets.fromLTRB(14, 9, grid ? 0 : 4, 9),
      decoration: BoxDecoration(
        color: missing ? c.warningSoft : null,
        border: divider ? Border(bottom: BorderSide(color: c.divider)) : null,
      ),
      child: Row(
        spacing: grid ? 4 : 6,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 2,
              children: [
                Text(
                  label,
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w700,
                    color: missing ? c.warningText : c.textSecondary,
                  ),
                ),
                if (missing)
                  Row(
                    spacing: 6,
                    children: [
                      MusubiIcon(
                        MusubiIcons.triangleAlert,
                        size: 16,
                        strokeWidth: 2.2,
                        color: c.warningText,
                      ),
                      Flexible(
                        child: Text(
                          'No identificado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MusubiType.style(
                            15.5,
                            weight: FontWeight.w800,
                            color: c.warningText,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        value!,
                        style: MusubiType.style(
                          big ? 17 : 15.5,
                          weight: big ? FontWeight.w800 : FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      if (badge case final badge?)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.successSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: MusubiType.style(
                              11,
                              weight: FontWeight.w800,
                              color: c.successText,
                            ),
                          ),
                        ),
                    ],
                  ),
                if (sub case final sub?)
                  Text(
                    sub,
                    style: MusubiType.style(
                      12.5,
                      weight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (edit != null && missing)
            Pressable(
              onTap: edit,
              semanticLabel: 'Agregar ${label.toLowerCase()}',
              builder: (context, _) => SizedBox(
                height: MusubiSizes.minTouch,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      MusubiIcon(
                        MusubiIcons.plus,
                        size: 16,
                        strokeWidth: 2.4,
                        color: c.warningText,
                      ),
                      Text(
                        'Agregar',
                        style: MusubiType.style(
                          14,
                          weight: FontWeight.w800,
                          color: c.warningText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (edit != null)
            Pressable(
              onTap: edit,
              semanticLabel: editLabel,
              builder: (context, _) => SizedBox.square(
                dimension: MusubiSizes.minTouch,
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.pencil,
                    size: 18,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Cantidad": quitar y agregar uno, de 1 a lo disponible.
class QuantityPanel extends StatefulWidget {
  const new({required this.initial, required this.max, super.key});

  final int initial;
  final int max;

  @override
  State<QuantityPanel> createState() => _QuantityPanelState();
}

class _QuantityPanelState extends State<QuantityPanel> {
  late int _quantity = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return MusubiPanel(
      key: const Key('order-quantity-panel'),
      title: 'Cantidad',
      actions: [
        MusubiButton(
          key: const Key('order-quantity-done'),
          label: 'Listo',
          onPressed: () => Navigator.of(context).pop(_quantity),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          NeedQuantityRow(
            quantity: _quantity,
            max: widget.max,
            onStep: (delta) => setState(
              () => _quantity = (_quantity + delta).clamp(1, widget.max),
            ),
          ),
          Text(
            widget.max == 1
                ? 'Solo hay 1 disponible.'
                : 'Puedes pedir hasta ${widget.max}.',
            style: MusubiType.style(
              12.5,
              weight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Entrega": un edificio del campus (el de tu carrera primero) y un detalle
/// libre ("Planta baja, junto a la entrada").
class PlacePanel extends ConsumerStatefulWidget {
  const new({required this.point, required this.detail, super.key});

  final MeetingPoint? point;
  final String detail;

  @override
  ConsumerState<PlacePanel> createState() => _PlacePanelState();
}

class _PlacePanelState extends ConsumerState<PlacePanel> {
  late MeetingPoint? _point = widget.point;
  late final _detail = TextEditingController(text: widget.detail);

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final points = ref.watch(meetingPointsProvider);
    final point = _point;
    return MusubiPanel(
      key: const Key('order-place-panel'),
      title: 'Entrega',
      tall: true,
      actions: [
        MusubiButton(
          key: const Key('order-place-done'),
          label: 'Listo',
          onPressed: point == null
              ? null
              : () => Navigator.of(context).pop((point, _detail.text)),
        ),
      ],
      child: switch (points) {
        AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NeedLabel('¿Dónde se ven?'),
            if (value.any((p) => p.suggested))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Primero está el edificio de tu carrera.',
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in [
                  ...value.where((p) => p.suggested),
                  ...value.where((p) => !p.suggested),
                ])
                  NeedChip(
                    key: Key('order-point-${p.slug}'),
                    label: p.name,
                    icon: p.suggested ? MusubiIcons.graduationCap : null,
                    selected: point == p,
                    onTap: () => setState(() => _point = p),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            MusubiTextField(
              fieldKey: const Key('order-detail'),
              label: 'Detalle del lugar (opcional)',
              hint: 'Planta baja, junto a la entrada',
              controller: _detail,
              sheet: true,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
            ),
          ],
        ),
        AsyncError(:final error) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            error is ApiFailure
                ? error.message
                : 'No pudimos cargar los puntos de entrega.',
            style: MusubiType.style(
              14,
              weight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ),
        _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: MusubiSpinner()),
        ),
      },
    );
  }
}

/// "Fecha": el dia (hoy y los 13 siguientes) y la hora, de las 7:00 a las
/// 21:00 del campus y con al menos 30 minutos de anticipacion.
class WhenPanel extends StatefulWidget {
  const new({required this.now, required this.initial, super.key});

  final DateTime now;
  final DateTime? initial;

  @override
  State<WhenPanel> createState() => _WhenPanelState();
}

class _WhenPanelState extends State<WhenPanel> {
  late DateTime? _day = widget.initial == null
      ? null
      : DateUtils.dateOnly(widget.initial!);
  late int? _hour = widget.initial?.hour;

  List<DateTime> get _days {
    final today = DateUtils.dateOnly(widget.now);
    return [
      for (var i = 0; i < orderDays; i++)
        if (_hours(today.add(Duration(days: i))).isNotEmpty)
          today.add(Duration(days: i)),
    ];
  }

  List<int> _hours(DateTime day) => [
    for (var h = orderFirstHour; h <= orderLastHour; h++)
      if (DateTime(
        day.year,
        day.month,
        day.day,
        h,
      ).isAfter(widget.now.add(const Duration(minutes: 30))))
        h,
  ];

  String _dayLabel(DateTime day) {
    final today = DateUtils.dateOnly(widget.now);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    final short = shortDate(day);
    return '${short[0].toUpperCase()}${short.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final hour = _hour;
    final hours = day == null ? const <int>[] : _hours(day);
    return MusubiPanel(
      key: const Key('order-when-panel'),
      title: 'Fecha y hora',
      tall: true,
      actions: [
        MusubiButton(
          key: const Key('order-when-done'),
          label: 'Listo',
          onPressed: day == null || hour == null || !hours.contains(hour)
              ? null
              : () =>
                    Navigator.of(context)
                        .pop(DateTime(day.year, day.month, day.day, hour)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NeedLabel('Día'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final d in _days)
                NeedChip(
                  key: Key('order-day-${d.month}-${d.day}'),
                  label: _dayLabel(d),
                  selected: day == d,
                  onTap: () => setState(() => _day = d),
                ),
            ],
          ),
          if (day != null) ...[
            const SizedBox(height: 14),
            const NeedLabel('Hora'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final h in hours)
                  NeedChip(
                    key: Key('order-hour-$h'),
                    label: clockTime(DateTime(2026, 1, 1, h)),
                    selected: hour == h,
                    onTap: () => setState(() => _hour = h),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
