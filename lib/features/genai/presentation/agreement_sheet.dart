import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_dialog.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/genai/domain/agreement_models.dart';
import 'package:musubi_app/features/genai/presentation/agreement_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/orders/presentation/order_summary_sheet.dart';

// El acuerdo con IA (HU-32/33/34): la hoja de `Acuerdo-esperando` con la
// propuesta de la IA y de `Acuerdo-confirmado` cuando los dos la confirman.
// Mientras la IA lee el chat, la hoja muestra que esta trabajando (RNF-12).

/// Como termino "Resumir acuerdo".
enum AgreementOutcome {
  /// La hoja se cerro (con o sin cambios).
  closed,

  /// La IA no esta disponible (`genai.unavailable`, RNF-15): el chat ofrece
  /// llenar el resumen a mano.
  unavailable,
}

/// El aviso de la primera vez (RN-40). `true` si la persona sigue.
Future<bool> confirmAiNotice(
  BuildContext context, {
  required String counterpart,
}) => showMusubiDialog(
  context,
  icon: MusubiIcons.sparkle,
  title: 'Resumir con IA',
  message:
      'La IA leerá los mensajes de este chat para proponer el acuerdo. '
      'Se envían sin sus nombres ni datos de contacto, y $counterpart verá en '
      'el chat que lo pediste. No guardamos el chat: solo la propuesta, hasta '
      'que creen el pedido o por 30 días.',
  confirmLabel: 'Resumir',
  confirmKey: const Key('ai-notice-continue'),
);

/// Abre el acuerdo de [conversation]. Con [request], primero le pide a la IA
/// la propuesta; si no, muestra [agreement] (el que ya existe).
Future<AgreementOutcome> showAgreementSheet(
  BuildContext context, {
  required Conversation conversation,
  bool request = false,
  Agreement? agreement,
}) async {
  final c = context.musubi;
  final outcome = await showModalBottomSheet<AgreementOutcome>(
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
    builder: (_) => AgreementSheet(
      conversation: conversation,
      request: request,
      initial: agreement,
    ),
  );
  return outcome ?? AgreementOutcome.closed;
}

/// La hoja (publica para las pruebas y las capturas).
class AgreementSheet extends ConsumerStatefulWidget {
  const new({
    required this.conversation,
    super.key,
    this.request = false,
    this.initial,
  });

  final Conversation conversation;
  final bool request;
  final Agreement? initial;

  @override
  ConsumerState<AgreementSheet> createState() => _AgreementSheetState();
}

class _AgreementSheetState extends ConsumerState<AgreementSheet> {
  late Agreement? _agreement = widget.initial;
  bool _busy = false;
  StreamSubscription<String>? _changes;

  String get _conversationId => widget.conversation.id;

  @override
  void initState() {
    super.initState();
    // Si la otra persona corrige, confirma o descarta mientras la hoja esta
    // abierta, se vuelve a leer (evento `agreementChanged`).
    _changes = ref
        .read(chatRealtimeProvider)
        .agreementChanges
        .where((id) => id == _conversationId)
        .listen((_) => unawaited(_reload()));
    if (widget.request) unawaited(_request());
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  Future<void> _request() async {
    try {
      final agreement = await ref
          .read(agreementRepositoryProvider)
          .request(_conversationId);
      if (!mounted) return;
      ref.invalidate(agreementProvider(_conversationId));
      setState(() => _agreement = agreement);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      if (failure.code == 'genai.unavailable') {
        navigator.pop(AgreementOutcome.unavailable);
        return;
      }
      navigator.pop(AgreementOutcome.closed);
      _warn(messenger, failure.message);
    }
  }

  Future<void> _reload() async {
    try {
      final fresh = await ref
          .read(agreementRepositoryProvider)
          .byConversation(_conversationId);
      if (!mounted) return;
      if (fresh == null) {
        // Se descarto o ya es pedido.
        Navigator.of(context).pop(AgreementOutcome.closed);
        return;
      }
      setState(() => _agreement = fresh);
    } on ApiFailure {
      return;
    }
  }

  void _warn(ScaffoldMessengerState messenger, String message) =>
      showMusubiSnack(
        messenger,
        message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );

  Future<void> _apply(AgreementEdit edit) async {
    final agreement = _agreement;
    if (agreement == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final changed = await ref
          .read(agreementRepositoryProvider)
          .update(agreement, edit);
      if (!mounted) return;
      setState(() => _agreement = changed);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _warn(messenger, failure.message);
      if (failure.code == 'agreements.changed') await _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editTitle(Agreement a) async {
    final text = await showMusubiPanel<String>(
      context,
      builder: (context) => _TextPanel(
        title: 'Producto',
        label: 'Qué se compra',
        initial: a.proposal.title,
        max: 80,
        fieldKey: const Key('agreement-title-field'),
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      await _apply(AgreementEdit(title: text.trim()));
    }
  }

  Future<void> _editPrice(Agreement a) async {
    final text = await showMusubiPanel<String>(
      context,
      builder: (context) => _TextPanel(
        title: 'Precio acordado',
        label: 'Precio por pieza',
        initial: a.proposal.priceCents == null
            ? ''
            : (a.proposal.priceCents! ~/ 100).toString(),
        max: 6,
        prefix: r'$ ',
        number: true,
        fieldKey: const Key('agreement-price-field'),
      ),
    );
    final pesos = int.tryParse(text ?? '');
    if (pesos != null && pesos > 0) {
      await _apply(AgreementEdit(priceCents: pesos * 100));
    }
  }

  Future<void> _editQuantity(Agreement a) async {
    final picked = await showMusubiPanel<int>(
      context,
      builder: (context) =>
          QuantityPanel(initial: a.proposal.quantity ?? 1, max: a.maxQuantity),
    );
    if (picked != null) await _apply(AgreementEdit(quantity: picked));
  }

  Future<void> _editPlace(Agreement a) async {
    final points = ref.read(meetingPointsProvider).value ?? const [];
    MeetingPoint? current;
    for (final p in points) {
      if (p.slug == a.proposal.meetingPoint) current = p;
    }
    final picked = await showMusubiPanel<(MeetingPoint, String)>(
      context,
      builder: (context) =>
          PlacePanel(point: current, detail: a.proposal.detail ?? ''),
    );
    if (picked == null) return;
    final (point, detail) = picked;
    await _apply(AgreementEdit(meetingPoint: point.slug, detail: detail));
  }

  Future<void> _editWhen(Agreement a) async {
    final now = ref.read(clockProvider)().toLocal();
    final picked = await showMusubiPanel<DateTime>(
      context,
      builder: (context) =>
          WhenPanel(now: now, initial: a.proposal.deliveryAt?.toLocal()),
    );
    if (picked != null) await _apply(AgreementEdit(deliveryAt: picked));
  }

  Future<void> _editConditions(Agreement a) async {
    final text = await showMusubiPanel<String>(
      context,
      builder: (context) => _TextPanel(
        title: 'Condiciones',
        label: 'Otras condiciones (opcional)',
        hint: 'Incluye la funda',
        initial: a.proposal.conditions ?? '',
        max: 200,
        fieldKey: const Key('agreement-conditions-field'),
      ),
    );
    if (text != null) await _apply(AgreementEdit(conditions: text.trim()));
  }

  Future<void> _confirm() async {
    final agreement = _agreement;
    if (agreement == null) return;
    final messenger = ScaffoldMessenger.of(context);
    // Como la maqueta, el boton se ve activo: si falta algo, se dice que.
    if (!agreement.complete) {
      _warn(messenger, 'Completa los datos que faltan antes de confirmar.');
      return;
    }
    setState(() => _busy = true);
    try {
      final confirmed = await ref
          .read(agreementRepositoryProvider)
          .confirm(agreement);
      if (!mounted) return;
      ref.invalidate(agreementProvider(_conversationId));
      setState(() => _agreement = confirmed);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _warn(messenger, failure.message);
      if (failure.code == 'agreements.changed') await _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createOrder() async {
    final agreement = _agreement;
    if (agreement == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .createFromAgreement(agreement.id);
      ref
        ..invalidate(openOrderProvider(_conversationId))
        ..invalidate(agreementProvider(_conversationId));
      navigator.pop(AgreementOutcome.closed);
      unawaited(router.push(AppRoutes.order(order.id)));
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      _warn(messenger, failure.message);
    }
  }

  Future<void> _discard() async {
    final agreement = _agreement;
    if (agreement == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final sure = await showMusubiDialog(
      context,
      icon: MusubiIcons.trash,
      title: '¿Descartar la propuesta?',
      message:
          'Se borra para los dos y la conversación sigue. Pueden pedir otro '
          'resumen cuando quieran.',
      confirmLabel: 'Descartar',
      danger: true,
      confirmKey: const Key('agreement-discard-confirm'),
    );
    if (!sure || !mounted) return;
    try {
      await ref.read(agreementRepositoryProvider).discard(agreement.id);
      ref.invalidate(agreementProvider(_conversationId));
      navigator.pop(AgreementOutcome.closed);
    } on ApiFailure catch (failure) {
      _warn(messenger, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final media = MediaQuery.of(context);
    final agreement = _agreement;
    final counterpart = widget.conversation.counterpart.firstName;
    final confirmed = agreement?.confirmed ?? false;
    return Container(
      key: const Key('agreement-sheet'),
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
          _SheetHeader(
            confirmed: confirmed,
            subtitle: confirmed
                ? '${_first(agreement!.buyerName)} y '
                      '${_first(agreement.sellerName)} · '
                      '${widget.conversation.context.title}'
                : 'Con base en tu chat con $counterpart',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: switch (agreement) {
                null => const _Reading(),
                final a when a.confirmed => _ConfirmedBody(
                  agreement: a,
                  at: a.updatedAt?.toLocal(),
                ),
                final a => _ProposedBody(
                  agreement: a,
                  busy: _busy,
                  onTitle: () => unawaited(_editTitle(a)),
                  onPrice: () => unawaited(_editPrice(a)),
                  onQuantity: () => unawaited(_editQuantity(a)),
                  onPlace: () => unawaited(_editPlace(a)),
                  onWhen: () => unawaited(_editWhen(a)),
                  onConditions: () => unawaited(_editConditions(a)),
                ),
              },
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
              child: _Footer(
                agreement: agreement,
                counterpart: counterpart,
                busy: _busy,
                onConfirm: () => unawaited(_confirm()),
                onCreate: () => unawaited(_createOrder()),
                onDiscard: () => unawaited(_discard()),
                onBack: () =>
                    Navigator.of(context).pop(AgreementOutcome.closed),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _first(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? name : parts.first;
}

/// Icono, "Resumen del acuerdo", subtitulo y cerrar.
class _SheetHeader extends StatelessWidget {
  const new({required this.confirmed, required this.subtitle});

  final bool confirmed;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 10, 0),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: confirmed ? c.successSoft : c.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: MusubiIcon(
                confirmed ? MusubiIcons.handshake : MusubiIcons.sparkle,
                size: 21,
                strokeWidth: 1.9,
                color: confirmed ? c.successText : c.brand,
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
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            key: const Key('agreement-close'),
            onTap: () => Navigator.of(context).pop(AgreementOutcome.closed),
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
    );
  }
}

/// RNF-12: mientras la IA lee el chat.
class _Reading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Semantics(
      liveRegion: true,
      label: 'La IA está leyendo el chat',
      child: Column(
        key: const Key('agreement-reading'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _AiBanner(
            leading: MusubiSpinner(size: 16, color: c.brand),
            text: 'La IA está leyendo el chat…',
          ),
          SkeletonShimmer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 18,
                  children: [
                    for (final width in const [220.0, 140.0, 250.0, 180.0])
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          const SkeletonBox(width: 70, height: 10),
                          SkeletonBox(width: width, height: 16),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La caja punteada de la IA (`Acuerdo-esperando`).
class _AiBanner extends StatelessWidget {
  const new({required this.leading, required this.text});

  final Widget leading;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return CustomPaint(
      foregroundPainter: _DashedBorder(color: c.neutralStrong, radius: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          spacing: 8,
          children: [
            leading,
            Expanded(
              child: Text(
                text,
                style: MusubiType.style(
                  13,
                  line: 18,
                  weight: FontWeight.w700,
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

class _DashedBorder extends CustomPainter {
  const new({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.75),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Las iniciales de los dos, encimadas.
class _Pair extends StatelessWidget {
  const new({required this.agreement, required this.size, required this.ring});

  final Agreement agreement;
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      InitialsAvatar(
        initials: initialsOf(agreement.buyerName),
        size: size,
        fontSize: size * 0.36,
        borderColor: ring,
        borderWidth: 2,
      ),
      Transform.translate(
        offset: const Offset(-8, 0),
        child: InitialsAvatar(
          initials: initialsOf(agreement.sellerName),
          size: size,
          palette: 2,
          fontSize: size * 0.36,
          borderColor: ring,
          borderWidth: 2,
        ),
      ),
    ],
  );
}

/// Los datos del acuerdo en su tarjeta (con lapices mientras se propone).
class _Fields extends StatelessWidget {
  const new({
    required this.agreement,
    this.onTitle,
    this.onPrice,
    this.onQuantity,
    this.onPlace,
    this.onWhen,
    this.onConditions,
  });

  final Agreement agreement;
  final VoidCallback? onTitle;
  final VoidCallback? onPrice;
  final VoidCallback? onQuantity;
  final VoidCallback? onPlace;
  final VoidCallback? onWhen;
  final VoidCallback? onConditions;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final p = agreement.proposal;
    final at = p.deliveryAt?.toLocal();
    final confirmed = agreement.confirmed;
    String? added(String field) =>
        confirmed && agreement.added(field) ? 'Agregada' : null;
    return DecoratedBox(
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
              key: const Key('agreement-product'),
              label: 'Producto',
              value: p.title,
              divider: true,
              editLabel: 'Editar producto',
              onEdit: onTitle,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.divider)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: c.divider)),
                        ),
                        child: SummaryField(
                          key: const Key('agreement-price'),
                          label: 'Precio acordado',
                          value: p.priceCents == null
                              ? null
                              : formatPrice(p.priceCents!),
                          big: true,
                          grid: true,
                          editLabel: 'Editar precio',
                          onEdit: onPrice,
                          badge: added(AgreementField.price),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SummaryField(
                        key: const Key('agreement-quantity'),
                        label: 'Cantidad',
                        value: p.quantity?.toString(),
                        big: true,
                        grid: true,
                        editLabel: 'Editar cantidad',
                        onEdit: onQuantity,
                        badge: added(AgreementField.quantity),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SummaryField(
              key: const Key('agreement-place'),
              label: 'Entrega',
              value: p.pointName == null
                  ? null
                  : 'Campus universitario · ${p.pointName}',
              sub: p.detail,
              divider: true,
              editLabel: 'Editar entrega',
              onEdit: onPlace,
              badge: added(AgreementField.meetingPoint),
            ),
            SummaryField(
              key: const Key('agreement-when'),
              label: 'Fecha',
              value: at == null ? null : '${longDate(at)} · ${clockTime(at)}',
              divider: p.conditions != null,
              editLabel: 'Editar fecha',
              onEdit: onWhen,
              badge: added(AgreementField.deliveryAt),
            ),
            if (p.conditions case final conditions?)
              SummaryField(
                key: const Key('agreement-conditions'),
                label: 'Condiciones',
                value: conditions,
                editLabel: 'Editar condiciones',
                onEdit: onConditions,
              ),
          ],
        ),
      ),
    );
  }
}

/// `Acuerdo-esperando`: la propuesta con sus lapices y "0 de 2".
class _ProposedBody extends StatelessWidget {
  const new({
    required this.agreement,
    required this.busy,
    required this.onTitle,
    required this.onPrice,
    required this.onQuantity,
    required this.onPlace,
    required this.onWhen,
    required this.onConditions,
  });

  final Agreement agreement;
  final bool busy;
  final VoidCallback onTitle;
  final VoidCallback onPrice;
  final VoidCallback? onQuantity;
  final VoidCallback onPlace;
  final VoidCallback onWhen;
  final VoidCallback onConditions;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final missing = agreement.missing;
    final counterpart = _first(agreement.counterpartName);
    final what = [
      if (missing.contains(AgreementField.price)) 'un precio',
      if (missing.contains(AgreementField.quantity)) 'una cantidad',
      if (missing.contains(AgreementField.meetingPoint)) 'un lugar',
      if (missing.contains(AgreementField.deliveryAt)) 'una fecha',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AiBanner(
          leading: MusubiIcon(MusubiIcons.sparkle, size: 17, color: c.brand),
          text: 'Propuesta generada con IA, revísala antes de confirmar',
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 8,
          children: [
            Flexible(
              child: Container(
                key: const Key('agreement-status'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: c.warningSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    MusubiIcon(
                      MusubiIcons.clock,
                      size: 14,
                      strokeWidth: 2.4,
                      color: c.warningText,
                    ),
                    Flexible(
                      child: Text(
                        'Esperando confirmación',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          12.5,
                          weight: FontWeight.w800,
                          color: c.warningText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Pair(agreement: agreement, size: 26, ring: c.background),
                Text(
                  '${agreement.confirmations} de 2',
                  key: const Key('agreement-count'),
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        AbsorbPointer(
          absorbing: busy,
          child: _Fields(
            agreement: agreement,
            onTitle: onTitle,
            onPrice: onPrice,
            onQuantity: onQuantity,
            onPlace: onPlace,
            onWhen: onWhen,
            onConditions: onConditions,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            what.isEmpty
                ? 'Si algo no coincide con lo que platicaron, corrígelo antes '
                      'de confirmar.'
                : 'No encontramos ${_list(what)} en la conversación. '
                      '${_add(what)} o pregúntale a $counterpart en el chat.',
            key: const Key('agreement-hint'),
            style: MusubiType.style(12.5, line: 18, color: c.textSecondary),
          ),
        ),
      ],
    );
  }

  static String _add(List<String> items) => items.length > 1
      ? 'Agrégalos'
      : items.single.startsWith('una ')
      ? 'Agrégala'
      : 'Agrégalo';

  static String _list(List<String> items) => items.length == 1
      ? items.single
      : '${items.sublist(0, items.length - 1).join(', ')} ni ${items.last}';
}

/// `Acuerdo-confirmado`: los dos lo confirmaron.
class _ConfirmedBody extends StatelessWidget {
  const new({required this.agreement, required this.at});

  final Agreement agreement;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final names =
        '${_first(agreement.buyerName)} y ${_first(agreement.sellerName)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.successSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.success,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.check,
                    size: 18,
                    strokeWidth: 3,
                    color: c.onBrand,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'Acuerdo confirmado',
                        style: MusubiType.style(
                          15,
                          weight: FontWeight.w800,
                          color: c.successText,
                        ),
                      ),
                    ),
                    Text(
                      at == null
                          ? '$names lo confirmaron'
                          : '$names lo confirmaron · ${clockTime(at!)}',
                      style: MusubiType.style(
                        12.5,
                        weight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _Pair(agreement: agreement, size: 30, ring: c.successSoft),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Row(
            spacing: 6,
            children: [
              MusubiIcon(MusubiIcons.sparkle, size: 14, color: c.textSecondary),
              Flexible(
                child: Text(
                  'Generado con IA · revisado y confirmado por ambos',
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        _Fields(agreement: agreement),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            spacing: 6,
            children: [
              MusubiIcon(MusubiIcons.lock, size: 14, color: c.textSecondary),
              Expanded(
                child: Text(
                  'Si algo cambia, ambos deben confirmar de nuevo.',
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
    );
  }
}

/// Las acciones de abajo: confirmar, crear el pedido o volver al chat.
class _Footer extends StatelessWidget {
  const new({
    required this.agreement,
    required this.counterpart,
    required this.busy,
    required this.onConfirm,
    required this.onCreate,
    required this.onDiscard,
    required this.onBack,
  });

  final Agreement? agreement;
  final String counterpart;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onCreate;
  final VoidCallback onDiscard;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final a = agreement;
    final note = MusubiType.style(
      12.5,
      weight: FontWeight.w600,
      color: c.textSecondary,
    );
    if (a == null) {
      return const MusubiButton(
        key: Key('agreement-confirm'),
        label: 'Confirmar acuerdo',
        icon: MusubiIcons.check,
        onPressed: null,
      );
    }
    if (a.confirmed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          if (a.isBuyer)
            MusubiButton(
              key: const Key('agreement-create-order'),
              label: 'Crear pedido',
              loadingLabel: 'Creando…',
              icon: MusubiIcons.package,
              loading: busy,
              onPressed: busy ? null : onCreate,
            )
          else
            Text(
              '$counterpart crea el pedido con estos datos.',
              textAlign: TextAlign.center,
              style: note,
            ),
          Pressable(
            key: const Key('agreement-back'),
            onTap: onBack,
            semanticLabel: 'Volver al chat',
            builder: (context, _) => SizedBox(
              height: MusubiSizes.minTouch,
              child: Center(
                child: Text(
                  'Volver al chat',
                  style: MusubiType.style(
                    14,
                    weight: FontWeight.w700,
                    color: c.brandText,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    final mine = a.confirmedByMe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        MusubiButton(
          key: const Key('agreement-confirm'),
          label: mine ? 'Esperando a $counterpart' : 'Confirmar acuerdo',
          loadingLabel: 'Confirmando…',
          icon: mine ? MusubiIcons.clock : MusubiIcons.check,
          loading: busy && !mine,
          onPressed: mine || busy ? null : onConfirm,
        ),
        Text(
          mine
              ? 'Te avisaremos en el chat cuando $counterpart lo confirme.'
              : '$counterpart también debe confirmarlo para crear el pedido.',
          textAlign: TextAlign.center,
          style: note,
        ),
        Center(
          child: Pressable(
            key: const Key('agreement-discard'),
            onTap: busy ? null : onDiscard,
            semanticLabel: 'Descartar propuesta',
            builder: (context, _) => SizedBox(
              height: MusubiSizes.minTouch,
              child: Center(
                child: Text(
                  'Descartar propuesta',
                  style: MusubiType.style(
                    13.5,
                    weight: FontWeight.w700,
                    color: c.dangerText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Un texto corto del acuerdo (producto, precio o condiciones).
class _TextPanel extends StatefulWidget {
  const new({
    required this.title,
    required this.label,
    required this.initial,
    required this.max,
    required this.fieldKey,
    this.hint,
    this.prefix,
    this.number = false,
  });

  final String title;
  final String label;
  final String initial;
  final int max;
  final Key fieldKey;
  final String? hint;
  final String? prefix;
  final bool number;

  @override
  State<_TextPanel> createState() => _TextPanelState();
}

class _TextPanelState extends State<_TextPanel> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MusubiPanel(
    title: widget.title,
    actions: [
      MusubiButton(
        key: const Key('agreement-text-done'),
        label: 'Listo',
        onPressed: () => Navigator.of(context).pop(_text.text),
      ),
    ],
    child: MusubiTextField(
      fieldKey: widget.fieldKey,
      label: widget.label,
      hint: widget.hint,
      controller: _text,
      sheet: true,
      prefixText: widget.prefix,
      keyboardType: widget.number ? TextInputType.number : null,
      inputFormatters: [
        if (widget.number) FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(widget.max),
      ],
    ),
  );
}
