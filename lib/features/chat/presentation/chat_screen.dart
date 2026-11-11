import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_dialog.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_controller.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/genai/domain/agreement_models.dart';
import 'package:musubi_app/features/genai/presentation/agreement_providers.dart';
import 'package:musubi_app/features/genai/presentation/agreement_sheet.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/notifications/presentation/notifications_screen.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/orders/presentation/order_summary_sheet.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/report_sheet.dart';

/// `Chat-Valeria` (HU-20): encabezado con la otra persona, la tarjeta de la
/// publicacion, los mensajes en tiempo real y la caja para escribir.
///
/// HU-21: la tarjeta de la publicacion y "Ver" (abre su detalle, HU-11).
/// "Mas opciones" (`chatMoreSheet`): "Bloquear a …" (HU-57) y "Reportar"
/// (HU-28); con un bloqueo, un aviso en lugar de la caja de texto.
/// NOTE (HU-05): "Ver perfil" y "En linea" / "Activa hace 5 min".
/// NOTE (HU-31): "Silenciar conversación" (sin avisos push no hay que callar).
/// NOTE (HU-27): la calificacion de la otra persona.
/// "Resumir acuerdo" (HU-32/33/34): cualquiera de los dos le pide a la IA la
/// propuesta (la primera vez, con el aviso de RN-40); con un acuerdo vigente,
/// el aviso lo muestra y lo abre, y con un pedido abierto, el pedido (HU-23).
/// Si la IA no esta disponible, quien compra llena el resumen a mano (RNF-15).
class ChatScreen extends ConsumerStatefulWidget {
  const new({required this.target, super.key, this.draft});

  final ChatTarget target;

  /// Mensaje ya escrito en la caja ("¡Hola, Valeria! Acepto tu oferta…",
  /// HU-17); la persona lo envia o lo cambia.
  final String? draft;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _input.text = widget.draft ?? '';
    _scroll.addListener(() {
      // La lista va invertida: el final del scroll son los mas viejos.
      if (_scroll.position.extentAfter < 240) {
        unawaited(
          ref.read(chatControllerProvider(widget.target).notifier).loadOlder(),
        );
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _soon(String what) => showMusubiSnack(
    ScaffoldMessenger.of(context),
    '$what llega muy pronto.',
    icon: MusubiIcons.clock,
    tone: SnackTone.info,
  );

  /// "Resumir acuerdo": abre el acuerdo vigente o le pide uno a la IA.
  Future<void> _summarize(Conversation? conversation) async {
    if (conversation == null) return;
    final existing = ref.read(agreementProvider(conversation.id)).value;
    if (existing != null) {
      await showAgreementSheet(
        context,
        conversation: conversation,
        agreement: existing,
      );
      return;
    }
    // RN-40: la primera vez se explica que la IA leera el chat.
    final notices = ref.read(aiNoticeStoreProvider);
    if (!await notices.seen()) {
      if (!mounted) return;
      final go = await confirmAiNotice(
        context,
        counterpart: conversation.counterpart.firstName,
      );
      if (!go) return;
      await notices.markSeen();
    }
    if (!mounted) return;
    final outcome = await showAgreementSheet(
      context,
      conversation: conversation,
      request: true,
    );
    if (outcome != AgreementOutcome.unavailable || !mounted) return;
    final buyer = conversation.role == ChatRole.buyer;
    showMusubiSnack(
      ScaffoldMessenger.of(context),
      buyer
          ? 'La IA no está disponible ahora. Llena el resumen a mano.'
          : 'La IA no está disponible ahora. Inténtalo más tarde.',
      icon: MusubiIcons.info,
      tone: SnackTone.info,
    );
    // RNF-15: el pedido se puede crear igual, sin IA (HU-23).
    if (buyer) await showOrderSummary(context, conversation: conversation);
  }

  Future<void> _send() async {
    final controller = ref.read(chatControllerProvider(widget.target).notifier);
    final sent = await controller.send(_input.text);
    if (!mounted) return;
    if (sent) {
      _input.clear();
      // HU-31 (L-16f): la primera vez que escribe, se le ofrece avisarle.
      await askForPushInContext(context, ref);
      return;
    }
    final failure = ref.read(chatControllerProvider(widget.target)).sendFailure;
    if (failure != null) {
      showMusubiSnack(
        ScaffoldMessenger.of(context),
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  /// `chatMoreSheet`: "Ver perfil", "Silenciar conversación", "Bloquear a …"
  /// y "Reportar".
  Future<void> _more(Conversation conversation) async {
    final person = conversation.counterpart;
    final picked = await showMusubiPanel<String>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('chat-more'),
        title: person.name,
        bodyInset: 12,
        child: MusubiOptions<String>(
          plain: true,
          options: [
            const MusubiOption(
              value: 'profile',
              label: 'Ver perfil',
              icon: MusubiIcons.user,
            ),
            const MusubiOption(
              value: 'mute',
              label: 'Silenciar conversación',
              icon: MusubiIcons.bellOff,
            ),
            MusubiOption(
              value: 'block',
              label: 'Bloquear a ${person.firstName}',
              icon: MusubiIcons.ban,
            ),
            const MusubiOption(
              value: 'report',
              label: 'Reportar',
              icon: MusubiIcons.flag,
            ),
          ],
          onPick: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    switch (picked) {
      case 'profile':
        _soon('El perfil de ${person.firstName}');
      case 'mute':
        _soon('Silenciar conversaciones');
      case 'block':
        // La maqueta abre el dialogo 240 ms despues (`later(240, ...)`).
        await Future<void>.delayed(const Duration(milliseconds: 240));
        if (mounted) await _block(person);
      case 'report':
        await Future<void>.delayed(const Duration(milliseconds: 240));
        if (!mounted) return;
        await showReportSheet(
          context,
          target: UserReport(
            userId: person.id,
            conversationId: conversation.id,
          ),
        );
    }
  }

  Future<void> _block(ChatCounterpart person) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showMusubiDialog(
      context,
      icon: MusubiIcons.ban,
      title: '¿Bloquear a ${person.firstName}?',
      message:
          'No podrá escribirte ni ver tus publicaciones. Puedes desbloquearlo '
          'en Ajustes.',
      confirmLabel: 'Bloquear',
      danger: true,
      confirmKey: const Key('block-confirm'),
    );
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(chatControllerProvider(widget.target).notifier)
          .blockCounterpart();
      _input.clear();
      showMusubiSnack(
        messenger,
        'Bloqueaste a ${person.firstName}',
        icon: MusubiIcons.ban,
        tone: SnackTone.warn,
      );
    } on ApiFailure catch (failure) {
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    ref.watch(chatConnectionProvider);
    final state = ref.watch(chatControllerProvider(widget.target));
    final controller = ref.read(chatControllerProvider(widget.target).notifier);
    final conversation = state.conversation;
    final preview = widget.target.product;
    final openOrder = conversation == null
        ? null
        : ref.watch(openOrderProvider(conversation.id)).value;
    final agreement = conversation == null
        ? null
        : ref.watch(agreementProvider(conversation.id)).value;
    // Un pedido que salio del acuerdo en otro dispositivo (HU-34).
    ref.listen(chatAgreementChangesProvider, (_, next) {
      final id = conversation?.id;
      if (id != null && next.value == id) {
        ref.invalidate(openOrderProvider(id));
      }
    });

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              counterpart: conversation?.counterpart,
              fallbackName: preview?.sellerName,
              onMore: conversation == null
                  ? null
                  : () => unawaited(_more(conversation)),
            ),
            if (state.ownProduct)
              Expanded(
                child: _Notice(
                  message: state.failure!.message,
                  onBack: () => context.pop(),
                ),
              )
            else if (state.failure != null && conversation == null)
              Expanded(
                child: _Notice(
                  message: state.failure!.message,
                  onRetry: controller.load,
                ),
              )
            else ...[
              _ContextCard(
                conversation: conversation,
                preview: preview,
                // HU-21: desde el contexto se abre el detalle del elemento.
                // HU-17: una oferta no tiene detalle que abrir.
                onSee: conversation?.context.isOffer ?? false
                    ? null
                    : () {
                        final id = conversation?.context.id ?? preview?.id;
                        if (id != null) {
                          unawaited(context.push(AppRoutes.product(id)));
                        }
                      },
                order: openOrder,
                agreement: agreement,
                onSummarize: () => unawaited(_summarize(conversation)),
                onOpenOrder: (id) =>
                    unawaited(context.push(AppRoutes.order(id))),
              ),
              Expanded(
                child: state.loading && state.messages.isEmpty
                    ? const _LogSkeleton()
                    : _Log(
                        state: state,
                        myId: controller.myId,
                        scroll: _scroll,
                        now: ref.watch(clockProvider)().toLocal(),
                      ),
              ),
              if (conversation != null && !conversation.canReply)
                const _BlockedNotice()
              else
                _Composer(
                  input: _input,
                  enabled: conversation != null,
                  sending: state.sending,
                  onSend: _send,
                  onAttach: () => _soon('Enviar fotos'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Regresar, avatar, nombre verificado y "Mas opciones" (borde inferior).
class _Header extends StatelessWidget {
  const new({
    required this.counterpart,
    required this.fallbackName,
    required this.onMore,
  });

  final ChatCounterpart? counterpart;
  final String? fallbackName;

  /// `null` mientras carga la conversacion.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final person =
        counterpart ??
        (fallbackName == null
            ? null
            : ChatCounterpart(id: fallbackName!, name: fallbackName!));
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
        child: Row(
          spacing: 4,
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
            if (person == null)
              const SkeletonBox(width: 40, height: 40, radius: 20)
            else
              // Su foto de perfil o, sin foto, sus iniciales.
              ProfileAvatar(
                initials: person.initials,
                photoUrl: person.photoUrl,
                size: 40,
                fontSize: 14,
                palette: person.palette,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        Flexible(
                          child: Text(
                            person?.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MusubiType.style(
                              15.5,
                              weight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        // Cada miembro verifico su correo del campus
                        // (HU-03).
                        if (person != null) const VerifiedBadge(size: 15),
                      ],
                    ),
                    Text(
                      'Estudiante verificado de tu campus',
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
            ),
            Pressable(
              onTap: onMore,
              semanticLabel: 'Más opciones',
              builder: (context, _) => SizedBox.square(
                dimension: MusubiSizes.minTouch,
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.ellipsis,
                    size: 22,
                    strokeWidth: 2.4,
                    color: c.textPrimary,
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

/// Tarjeta de la publicacion ("PUBLICACION DE VALERIA") y "Resumir acuerdo".
class _ContextCard extends StatelessWidget {
  const new({
    required this.conversation,
    required this.preview,
    required this.onSee,
    required this.onSummarize,
    required this.onOpenOrder,
    this.order,
    this.agreement,
  });

  final Conversation? conversation;
  final ProductSummary? preview;

  /// "Ver"; `null` sin detalle que abrir (una oferta, HU-17).
  final VoidCallback? onSee;
  final VoidCallback onSummarize;

  /// El pedido abierto de la conversacion (HU-23): el aviso lo muestra.
  final Order? order;
  final ValueChanged<String> onOpenOrder;

  /// El acuerdo con IA vigente (HU-34): el aviso lo muestra y "Ver acuerdo"
  /// lo abre.
  final Agreement? agreement;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final context0 = conversation?.context;
    final title = context0?.title ?? preview?.title ?? '';
    final price = context0 != null ? context0.priceCents : preview?.priceCents;
    final condition = context0?.conditionLabel ?? preview?.condition;
    final photo = context0?.photoUrl ?? preview?.photoUrl;
    final available = context0?.available ?? true;
    final offer = context0?.isOffer ?? false;
    final eyebrow = switch (conversation) {
      // HU-17: la conversacion nacio de una oferta a una solicitud.
      Conversation(role: ChatRole.seller) when offer => 'TU OFERTA · SE BUSCA',
      Conversation(:final counterpart) when offer =>
        'OFERTA DE ${counterpart.firstName.toUpperCase()} · SE BUSCA',
      Conversation(role: ChatRole.seller) => 'TU PUBLICACIÓN',
      Conversation(:final counterpart) =>
        'PUBLICACIÓN DE ${counterpart.firstName.toUpperCase()}',
      null => 'PUBLICACIÓN',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(bottom: BorderSide(color: c.divider)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1C1C1E),
            offset: Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
              decoration: BoxDecoration(
                color: c.brandSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                spacing: 10,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: SizedBox.square(
                      dimension: 46,
                      child: ProductPhoto(url: photo, soldOut: !available),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 1,
                      children: [
                        Row(
                          spacing: 4,
                          children: [
                            MusubiIcon(
                              MusubiIcons.megaphone,
                              size: 11,
                              strokeWidth: 2.6,
                              color: c.brandStrongText,
                            ),
                            Flexible(
                              child: Text(
                                eyebrow,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MusubiType.style(
                                  10.5,
                                  weight: FontWeight.w800,
                                  em: 0.06,
                                  color: c.brandStrongText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MusubiType.style(
                            14,
                            weight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                        Text.rich(
                          available && price != null
                              ? TextSpan(
                                  children: [
                                    const TextSpan(text: 'Precio '),
                                    TextSpan(
                                      text: formatPrice(price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (condition != null)
                                      TextSpan(text: ' · $condition'),
                                  ],
                                )
                              : TextSpan(
                                  text: switch ((offer, conversation?.role)) {
                                    (true, ChatRole.seller) =>
                                      'Respondiste a su solicitud',
                                    (true, _) => 'Respondió a tu solicitud',
                                    _ =>
                                      'Esta publicación ya no está disponible',
                                  },
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MusubiType.style(
                            12,
                            weight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onSee != null)
                    Pressable(
                      onTap: available ? onSee : null,
                      semanticLabel: 'Ver la publicación',
                      builder: (context, _) => SizedBox(
                        height: MusubiSizes.minTouch,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(
                            child: Text(
                              'Ver',
                              style: MusubiType.style(
                                13.5,
                                weight: FontWeight.w800,
                                color: c.brandStrongText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Flexible(
                    child: Text(
                      switch ((order, agreement)) {
                        (Order(:final number, :final status), _) =>
                          'Pedido #$number · ${status.label}',
                        (null, final Agreement a) when a.confirmed =>
                          'Acuerdo confirmado · Falta crear el pedido',
                        (null, final Agreement a) =>
                          'Acuerdo · Esperando confirmación '
                              '(${a.confirmations} de 2)',
                        _ => '¿Ya se pusieron de acuerdo?',
                      },
                      key: const Key('chat-order-status'),
                      style: MusubiType.style(
                        12.5,
                        weight: order == null && agreement == null
                            ? FontWeight.w600
                            : FontWeight.w700,
                        color: order == null && agreement == null
                            ? c.textSecondary
                            : c.textPrimary,
                      ),
                    ),
                  ),
                  if (order case final order?)
                    Pressable(
                      key: const Key('chat-open-order'),
                      onTap: () => onOpenOrder(order.id),
                      semanticLabel: 'Ver pedido',
                      builder: (context, _) => SizedBox(
                        height: MusubiSizes.minTouch,
                        child: Center(
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.only(left: 12, right: 14),
                            decoration: BoxDecoration(
                              color: c.inverse,
                              borderRadius: BorderRadius.circular(
                                MusubiSizes.radiusChip,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 7,
                              children: [
                                MusubiIcon(
                                  MusubiIcons.package,
                                  size: 16,
                                  color: c.onBrand,
                                ),
                                Text(
                                  'Ver pedido',
                                  style: MusubiType.style(
                                    13.5,
                                    weight: FontWeight.w700,
                                    color: c.onBrand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (agreement != null)
                    Pressable(
                      key: const Key('chat-open-agreement'),
                      onTap: onSummarize,
                      semanticLabel: 'Ver acuerdo',
                      builder: (context, _) => SizedBox(
                        height: MusubiSizes.minTouch,
                        child: Center(
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.only(left: 12, right: 14),
                            decoration: BoxDecoration(
                              color: c.inverse,
                              borderRadius: BorderRadius.circular(
                                MusubiSizes.radiusChip,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 7,
                              children: [
                                MusubiIcon(
                                  MusubiIcons.handshake,
                                  size: 16,
                                  color: c.onBrand,
                                ),
                                Text(
                                  'Ver acuerdo',
                                  style: MusubiType.style(
                                    13.5,
                                    weight: FontWeight.w700,
                                    color: c.onBrand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Pressable(
                      key: const Key('chat-summarize'),
                      onTap: onSummarize,
                      semanticLabel: 'Resumir acuerdo',
                      builder: (context, _) => SizedBox(
                        height: MusubiSizes.minTouch,
                        child: Center(
                          child: _Glow(
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 14,
                              ),
                              decoration: BoxDecoration(
                                color: c.inverse,
                                borderRadius: BorderRadius.circular(
                                  MusubiSizes.radiusChip,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 7,
                                children: [
                                  MusubiIcon(
                                    MusubiIcons.sparkle,
                                    size: 16,
                                    color: c.onBrand,
                                  ),
                                  Text(
                                    'Resumir acuerdo',
                                    style: MusubiType.style(
                                      13.5,
                                      weight: FontWeight.w700,
                                      color: c.onBrand,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Historial: aviso de inicio, burbujas (las mias a la derecha en rojo) y la
/// hora debajo de cada grupo. Lista invertida: abre en lo mas nuevo.
class _Log extends StatelessWidget {
  const new({
    required this.state,
    required this.myId,
    required this.scroll,
    required this.now,
  });

  final ChatState state;
  final String? myId;
  final ScrollController scroll;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final messages = state.messages;
    final role = state.conversation?.role;
    final first = messages.isEmpty ? now : messages.first.sentAt.toLocal();
    final opener = role == ChatRole.seller
        ? 'Conversación sobre tu publicación'
        : 'Conversación sobre su publicación';

    // Del mas nuevo al mas viejo (lista invertida).
    final items = <Widget>[];
    for (var i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      final mine = message.senderId == myId;
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      // Como la maqueta: una hora al final de cada intercambio (5 min sin
      // mensajes), del lado de quien escribio el ultimo.
      final lastOfGroup =
          next == null || next.sentAt.difference(message.sentAt).inMinutes >= 5;
      if (lastOfGroup) {
        items.add(
          _Stamp(text: messageStamp(message.sentAt.toLocal(), now), mine: mine),
        );
      }
      items.add(
        message.notice
            ? _NoticeLine(text: message.text)
            : _Bubble(message: message, mine: mine),
      );
    }
    items.add(
      _Opener(
        text: messages.isEmpty
            ? '$opener · Escribe tu primera pregunta'
            : '$opener · ${dayLabel(first, now)}',
      ),
    );

    return ListView.separated(
      key: const Key('chat-log'),
      controller: scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _Opener extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.92 - 32,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              MusubiIcon(MusubiIcons.tag, size: 14, color: c.textPrimary),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w700,
                    color: c.textPrimary,
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

/// Un aviso de la app dentro del chat ("Ana pidió un resumen con IA", RN-40).
class _NoticeLine extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          key: const Key('chat-notice'),
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            MusubiIcon(MusubiIcons.sparkle, size: 13, color: c.textSecondary),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
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
    );
  }
}

class _Bubble extends StatelessWidget {
  const new({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    const big = Radius.circular(18);
    const small = Radius.circular(6);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width - 32) * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: mine ? c.brand : c.surface,
            borderRadius: BorderRadius.only(
              topLeft: big,
              topRight: big,
              bottomLeft: mine ? big : small,
              bottomRight: mine ? small : big,
            ),
          ),
          child: Text(
            message.text,
            style: MusubiType.style(
              15,
              line: 21,
              color: mine ? c.onBrand : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const new({required this.text, required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.only(left: mine ? 0 : 4, right: mine ? 4 : 0),
      child: Text(
        text,
        style: MusubiType.style(
          11.5,
          weight: FontWeight.w600,
          color: context.musubi.textSecondary,
        ),
      ),
    ),
  );
}

class _LogSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const SkeletonShimmer(
    child: Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 8,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 220, height: 42, radius: 18),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SkeletonBox(width: 250, height: 42, radius: 18),
          ),
        ],
      ),
    ),
  );
}

/// Adjuntar, caja "Escribe un mensaje…" y "Enviar".
class _Composer extends StatelessWidget {
  const new({
    required this.input,
    required this.enabled,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController input;
  final bool enabled;
  final bool sending;
  final Future<void> Function() onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + (bottom > 0 ? bottom : 22)),
        child: Row(
          spacing: 8,
          children: [
            Pressable(
              onTap: onAttach,
              semanticLabel: 'Adjuntar foto o archivo',
              builder: (context, _) => Container(
                width: MusubiSizes.minTouch,
                height: MusubiSizes.minTouch,
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: MusubiIcon(
                  MusubiIcons.plus,
                  size: 21,
                  strokeWidth: 2.2,
                  color: c.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: MusubiSizes.minTouch,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.centerLeft,
                child: TextField(
                  key: const Key('chat-input'),
                  controller: input,
                  enabled: enabled,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => unawaited(onSend()),
                  style: MusubiType.style(15.5, color: c.textPrimary),
                  cursorColor: c.brand,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    counterText: '',
                    hintText: 'Escribe un mensaje…',
                    hintStyle: MusubiType.style(15.5, color: c.placeholder),
                    semanticCounterText: '',
                  ),
                ),
              ),
            ),
            Pressable(
              onTap: enabled && !sending ? () => unawaited(onSend()) : null,
              semanticLabel: 'Enviar',
              builder: (context, pressed) => Container(
                width: MusubiSizes.minTouch,
                height: MusubiSizes.minTouch,
                decoration: BoxDecoration(
                  color: pressed ? c.brandPressed : c.brand,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: sending
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.onBrand,
                        ),
                      )
                    : MusubiIcon(MusubiIcons.send, size: 20, color: c.onBrand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// En lugar de la caja de texto cuando hay un bloqueo entre los dos (HU-57):
/// mismo borde y alto que el compositor. No dice quien bloqueo.
class _BlockedNotice extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      key: const Key('chat-blocked'),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 8 + (bottom > 0 ? bottom : 22)),
        child: SizedBox(
          height: MusubiSizes.minTouch,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              MusubiIcon(MusubiIcons.ban, size: 18, color: c.textSecondary),
              Flexible(
                child: Text(
                  'No puedes responder a esta conversación.',
                  textAlign: TextAlign.center,
                  style: MusubiType.style(
                    14,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
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

/// "Es tu publicación" o un error al abrir, con regresar o reintentar.
class _Notice extends StatelessWidget {
  const new({required this.message, this.onBack, this.onRetry});

  final String message;
  final VoidCallback? onBack;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final action = onRetry != null ? 'Reintentar' : 'Regresar';
    return Padding(
      padding: const EdgeInsets.all(MusubiSizes.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: MusubiSizes.space4,
        children: [
          InlineMessage(
            message: message,
            kind: onRetry != null
                ? InlineMessageKind.error
                : InlineMessageKind.warning,
          ),
          Pressable(
            onTap: onRetry != null ? () => unawaited(onRetry!()) : onBack,
            semanticLabel: action,
            builder: (context, _) => SizedBox(
              height: MusubiSizes.minTouch,
              child: Center(
                child: Text(
                  action,
                  style: MusubiType.style(
                    14.5,
                    weight: FontWeight.w800,
                    color: c.brandStrongText,
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

/// `Chat-Valeria__glow`: un halo rojo tenue que late detras de "Resumir
/// acuerdo" (2.4 s, empieza al segundo). Tres ciclos, no sin fin.
class _Glow extends StatefulWidget {
  const new({required this.child});

  final Widget child;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  static const _delay = 1000;
  static const _cycle = 2400;
  static const _cycles = 3;

  // Un solo controlador con la espera inicial adentro: sin timers sueltos.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _delay + _cycle * _cycles),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 0 sin halo, 1 en la mitad de cada ciclo.
  double _intensity(double value) {
    final ms = value * (_delay + _cycle * _cycles) - _delay;
    if (ms <= 0) return 0;
    final phase = (ms % _cycle) / _cycle;
    return Curves.easeInOut.transform(1 - (2 * phase - 1).abs());
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      // 0 % y 100 %: sin halo; 50 %: 5 px de rgba(215,25,31,.14).
      final t = _intensity(_controller.value);
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(215, 25, 31, 0.14 * t),
              spreadRadius: 5 * t,
            ),
          ],
        ),
        child: child,
      );
    },
  );
}
