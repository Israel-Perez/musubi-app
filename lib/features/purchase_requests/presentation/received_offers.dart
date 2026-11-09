import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
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
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_repository.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

/// "Ordenar ofertas" de la maqueta.
enum OfferSort {
  recommended('Recomendadas', MusubiIcons.sparkle),
  price('Menor precio', MusubiIcons.arrowDownUp),
  reputation('Mejor reputación', MusubiIcons.shieldCheck);

  new(this.label, this.icon);

  final String label;
  final MusubiIconData icon;
}

/// Ordena las ofertas. "Recomendadas": las aceptadas primero, luego las que
/// caben en el presupuesto, la mejor reputacion y el menor precio.
List<ReceivedOffer> sortOffers(
  List<ReceivedOffer> offers,
  OfferSort sort,
  int budgetCents,
) {
  int byPrice(ReceivedOffer a, ReceivedOffer b) =>
      a.priceCents.compareTo(b.priceCents);
  int byRating(ReceivedOffer a, ReceivedOffer b) =>
      (b.offerer.ratingAvg ?? -1).compareTo(a.offerer.ratingAvg ?? -1);
  final sorted = [...offers];
  switch (sort) {
    case OfferSort.price:
      sorted.sort(byPrice);
    case OfferSort.reputation:
      sorted.sort((a, b) {
        final r = byRating(a, b);
        return r != 0 ? r : byPrice(a, b);
      });
    case OfferSort.recommended:
      int rank(ReceivedOffer o) =>
          (o.accepted ? 0 : 2) + (o.priceCents <= budgetCents ? 0 : 1);
      sorted.sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        final rating = byRating(a, b);
        return rating != 0 ? rating : byPrice(a, b);
      });
  }
  return sorted;
}

/// "Compara las ofertas" de `Mis-solicitudes` (HU-17): cada oferta con
/// "Rechazar", "Abrir chat" y "Aceptar".
class ReceivedOffersSection extends ConsumerStatefulWidget {
  const new({required this.request, super.key});

  final WantedRequest request;

  /// Tiempo del aviso con "Deshacer" antes de rechazar de verdad.
  static const undoWindow = Duration(seconds: 4);

  @override
  ConsumerState<ReceivedOffersSection> createState() =>
      _ReceivedOffersSectionState();
}

class _ReceivedOffersSectionState extends ConsumerState<ReceivedOffersSection> {
  OfferSort _sort = OfferSort.recommended;

  /// Rechazos que esperan a que termine el aviso ("Deshacer").
  final Map<String, Timer> _rejecting = {};
  late final WantedRepository _repository = ref.read(wantedRepositoryProvider);

  @override
  void dispose() {
    // Al salir, los rechazos pendientes se envian.
    for (final MapEntry(key: id, value: timer) in _rejecting.entries) {
      timer.cancel();
      unawaited(_send(id));
    }
    super.dispose();
  }

  Future<void> _send(String offerId) async {
    try {
      await _repository.rejectOffer(widget.request.id, offerId);
    } on ApiFailure {
      // Ya estaba decidida o la solicitud cambio: la lista se vuelve a pedir.
      if (mounted) ref.invalidate(receivedOffersProvider(widget.request.id));
    }
  }

  Future<void> _reject(ReceivedOffer offer) async {
    final who = offer.offerer.firstName;
    final confirmed = await showMusubiDialog(
      context,
      icon: MusubiIcons.x,
      title: '¿Rechazar la oferta de $who?',
      // NOTE (HU-30): el aviso amable a quien ofrecio llega con las
      // notificaciones.
      message:
          'Le avisaremos con un mensaje amable. No podrás deshacerlo después '
          'de un rato.',
      confirmLabel: 'Rechazar',
      danger: true,
      confirmKey: const Key('offer-reject-confirm'),
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _rejecting[offer.id] = Timer(ReceivedOffersSection.undoWindow, () {
        _rejecting.remove(offer.id);
        unawaited(_send(offer.id));
      });
    });
    showMusubiSnack(
      ScaffoldMessenger.of(context),
      'Rechazaste la oferta de $who',
      icon: MusubiIcons.x,
      tone: SnackTone.info,
      actionLabel: 'Deshacer',
      duration: ReceivedOffersSection.undoWindow,
      onAction: () {
        if (!mounted) return;
        setState(() => _rejecting.remove(offer.id)?.cancel());
      },
    );
  }

  Future<void> _accept(ReceivedOffer offer) async {
    final who = offer.offerer.firstName;
    final confirmed = await showMusubiDialog(
      context,
      icon: MusubiIcons.check,
      title: '¿Aceptar la oferta de $who?',
      message:
          'Abriremos el chat para que acuerden la entrega. Después resumimos '
          'el acuerdo con IA.',
      confirmLabel: 'Aceptar oferta',
      confirmKey: const Key('offer-accept-confirm'),
    );
    if (!confirmed || !mounted) return;
    await _openChat(
      offer,
      accept: true,
      draft:
          '¡Hola, $who! Acepto tu oferta de ${formatPrice(offer.priceCents)}. '
          '¿Cuándo nos vemos?',
    );
  }

  Future<void> _openChat(
    ReceivedOffer offer, {
    bool accept = false,
    String? draft,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final conversationId = accept
          ? await _repository.acceptOffer(widget.request.id, offer.id)
          : await _repository.offerChat(widget.request.id, offer.id);
      if (accept) ref.invalidate(receivedOffersProvider(widget.request.id));
      unawaited(
        router.push(AppRoutes.conversation(conversationId), extra: draft),
      );
    } on ApiFailure catch (failure) {
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
      ref.invalidate(receivedOffersProvider(widget.request.id));
    }
  }

  Future<void> _pickSort() async {
    final picked = await showMusubiPanel<OfferSort>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('offer-sort'),
        title: 'Ordenar ofertas',
        bodyInset: 12,
        child: MusubiOptions<OfferSort>(
          selected: _sort,
          options: [
            for (final s in OfferSort.values)
              MusubiOption(value: s, label: s.label, icon: s.icon),
          ],
          onPick: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final request = widget.request;
    final received = ref.watch(receivedOffersProvider(request.id));
    final all = received.value ?? const <ReceivedOffer>[];
    final visible = sortOffers(
      [
        for (final o in all)
          if (!_rejecting.containsKey(o.id)) o,
      ],
      _sort,
      request.budgetCents,
    );

    final Widget body;
    if (received.isLoading && received.value == null) {
      body = const SkeletonShimmer(child: SkeletonBox(height: 220, radius: 20));
    } else if (received.hasError && received.value == null) {
      body = InlineMessage(
        message: switch (received.error) {
          final ApiFailure f => f.message,
          _ => 'No pudimos cargar las ofertas.',
        },
      );
    } else if (all.isEmpty) {
      body = _NoOffers(active: request.isActive);
    } else if (visible.isEmpty) {
      body = const _AllRejected();
    } else {
      final best = _bestRated(visible);
      final cheapest = visible.length > 1
          ? visible.reduce((a, b) => b.priceCents < a.priceCents ? b : a)
          : null;
      body = Column(
        spacing: 10,
        children: [
          for (final (i, offer) in visible.indexed)
            RiseIn(
              key: ValueKey('received-${offer.id}'),
              delay: Duration(milliseconds: math.min(i, 5) * 80),
              child: OfferCompareCard(
                offer: offer,
                budgetCents: request.budgetCents,
                badge: switch (offer) {
                  _ when offer.accepted => OfferBadge.accepted,
                  _ when identical(offer, best) => OfferBadge.bestRated,
                  _ when identical(offer, cheapest) => OfferBadge.cheapest,
                  _ => null,
                },
                onReject: () => unawaited(_reject(offer)),
                onChat: () => unawaited(_openChat(offer)),
                onAccept: () => unawaited(_accept(offer)),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 14, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Compara las ofertas',
                  style: MusubiType.style(
                    16,
                    weight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (visible.length > 1)
                Pressable(
                  key: const Key('offer-sort-button'),
                  semanticLabel: 'Ordenar: ${_sort.label}',
                  onTap: () => unawaited(_pickSort()),
                  builder: (context, _) => SizedBox(
                    height: MusubiSizes.minTouch - 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Text(
                          _sort.label,
                          style: MusubiType.style(
                            13,
                            weight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        MusubiIcon(
                          MusubiIcons.chevronDown,
                          size: 15,
                          strokeWidth: 2.2,
                          color: c.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: body),
      ],
    );
  }

  /// "Mejor reputación": la de mejor promedio con calificaciones, si hay
  /// con que comparar.
  static ReceivedOffer? _bestRated(List<ReceivedOffer> offers) {
    final rated = [
      for (final o in offers)
        if (o.offerer.ratingAvg != null && o.offerer.ratingCount > 0) o,
    ];
    if (offers.length < 2 || rated.isEmpty) return null;
    return rated.reduce(
      (a, b) => b.offerer.ratingAvg! > a.offerer.ratingAvg! ? b : a,
    );
  }
}

/// Etiqueta de la tarjeta.
enum OfferBadge {
  bestRated('Mejor reputación'),
  cheapest('Menor precio'),
  accepted('Aceptada');

  new(this.label);

  final String label;
}

/// Una oferta en "Compara las ofertas": quien ofrece con su reputacion, la
/// foto, el precio frente al presupuesto, su mensaje y las tres acciones.
class OfferCompareCard extends StatelessWidget {
  const new({
    required this.offer,
    required this.budgetCents,
    required this.onReject,
    required this.onChat,
    required this.onAccept,
    super.key,
    this.badge,
  });

  final ReceivedOffer offer;
  final int budgetCents;
  final OfferBadge? badge;
  final VoidCallback onReject;
  final VoidCallback onChat;
  final VoidCallback onAccept;

  static String _condition(ReceivedOffer o) => [
    if (o.condition == 'new') 'Nuevo' else 'Usado',
    ?switch (o.conditionDetail) {
      'likeNew' => 'como nuevo',
      'good' => 'buen estado',
      'fair' => 'con detalles',
      _ => null,
    },
    if (o.kind == OfferKind.listing) 'Su publicación' else 'Oferta directa',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final o = offer;
    final diff = budgetCents - o.priceCents;
    final (budgetText, budgetColor) = diff >= 0
        ? (
            diff == 0
                ? 'Igual a tu presupuesto'
                : '${formatPrice(diff)} bajo tu presupuesto',
            c.successText,
          )
        : ('${formatPrice(-diff)} arriba de tu presupuesto', c.error);
    final (badgeFill, badgeInk) = switch (badge) {
      OfferBadge.bestRated => (c.warningSoft, c.warningText),
      _ => (c.successSoft, c.successText),
    };
    final rating = o.offerer.ratingAvg;
    final meta = MusubiType.style(
      12,
      weight: FontWeight.w600,
      color: c.textSecondary,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1C1C1E),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color(0x0D1C1C1E),
            offset: Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 10,
            children: [
              ProfileAvatar(
                initials: initialsOf(o.offerer.name),
                size: 40,
                fontSize: 14,
                photoUrl: o.offerer.photoUrl,
                palette: o.offerer.id.codeUnits.fold(0, (a, b) => a + b) % 5,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: [
                    Row(
                      spacing: 5,
                      children: [
                        Flexible(
                          child: Text(
                            o.offerer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MusubiType.style(
                              14.5,
                              weight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const VerifiedBadge(size: 15),
                      ],
                    ),
                    Row(
                      spacing: 4,
                      children: [
                        if (rating != null) ...[
                          MusubiIcon(
                            MusubiIcons.star,
                            size: 12,
                            fillColor: c.warning,
                          ),
                          Text(
                            rating.toStringAsFixed(1),
                            style: meta.copyWith(
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            [
                              if (rating != null)
                                '(${o.offerer.ratingCount})'
                              else
                                'Sin calificaciones',
                              ?o.offerer.career,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: meta,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeFill,
                    borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                  ),
                  child: Text(
                    badge!.label,
                    style: MusubiType.style(
                      11,
                      weight: FontWeight.w800,
                      color: badgeInk,
                    ),
                  ),
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.square(
                  dimension: 72,
                  child: ProductPhoto(url: o.photoUrl ?? categoryPhoto('otro')),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      children: [
                        Text(
                          formatPrice(o.priceCents),
                          style: MusubiType.style(
                            22,
                            weight: FontWeight.w800,
                            line: 26,
                            em: -0.02,
                            color: c.textPrimary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            budgetText,
                            style: MusubiType.style(
                              12,
                              weight: FontWeight.w700,
                              color: budgetColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      o.message != null ? '“${o.message}”' : o.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        13,
                        line: 18,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      _condition(o),
                      style: MusubiType.style(
                        11.5,
                        weight: FontWeight.w700,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              if (!o.accepted)
                Pressable(
                  key: ValueKey('offer-reject-${o.id}'),
                  semanticLabel: 'Rechazar',
                  onTap: onReject,
                  builder: (context, pressed) => Container(
                    height: MusubiSizes.minTouch,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: pressed ? c.surface : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Rechazar',
                      style: MusubiType.style(
                        14,
                        weight: FontWeight.w700,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _ActionButton(
                  key: ValueKey('offer-chat-${o.id}'),
                  label: 'Abrir chat',
                  icon: MusubiIcons.messageCircle,
                  onTap: onChat,
                ),
              ),
              if (!o.accepted)
                Expanded(
                  child: _ActionButton(
                    key: ValueKey('offer-accept-${o.id}'),
                    label: 'Aceptar',
                    icon: MusubiIcons.check,
                    iconStroke: 2.4,
                    primary: true,
                    onTap: onAccept,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Abrir chat" (borde) y "Aceptar" (rojo): 44 de alto y radio 12.
class _ActionButton extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
    this.primary = false,
    this.iconStroke = 2,
  });

  final String label;
  final MusubiIconData icon;
  final VoidCallback onTap;
  final bool primary;
  final double iconStroke;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final ink = primary ? c.onBrand : c.textPrimary;
    return Pressable(
      semanticLabel: label,
      onTap: onTap,
      builder: (context, pressed) => Container(
        height: MusubiSizes.minTouch,
        decoration: BoxDecoration(
          color: primary
              ? (pressed ? c.brandPressed : c.brand)
              : (pressed ? c.surface : null),
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: c.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 6,
          children: [
            MusubiIcon(icon, size: 17, strokeWidth: iconStroke, color: ink),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MusubiType.style(
                  14,
                  weight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aun no hay ofertas (o la solicitud ya no recibe).
class _NoOffers extends StatelessWidget {
  const new({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      key: const Key('offers-empty'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        spacing: 6,
        children: [
          MusubiIcon(MusubiIcons.hand, size: 26, color: c.brand),
          Text(
            active ? 'Aún no hay ofertas' : 'Sin ofertas',
            textAlign: TextAlign.center,
            style: MusubiType.style(
              15,
              weight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          Text(
            active
                ? 'Te avisaremos cuando alguien responda “Yo tengo este '
                      'producto”.'
                : 'Esta solicitud ya no recibe ofertas.',
            textAlign: TextAlign.center,
            style: MusubiType.style(13.5, line: 19, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// "Rechazaste todas las ofertas…" (`data-noffers` de la maqueta).
class _AllRejected extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      key: const Key('offers-all-rejected'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Rechazaste todas las ofertas. Te avisamos cuando llegue una nueva.',
        textAlign: TextAlign.center,
        style: MusubiType.style(
          14.5,
          weight: FontWeight.w600,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
