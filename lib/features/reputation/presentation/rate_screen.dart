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
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';

/// Caracteres del comentario (la API acepta hasta 280).
const ratingCommentMax = 280;

/// `Calificar` (HU-27 y HU-45): "¿Como te fue con Diego?", estrellas, "¿Que
/// destacas?" (los chips de la otra parte) y "Cuentale a la comunidad". Quien
/// compra califica a quien vende y al reves; una vez por pedido y hasta 7 dias
/// despues de completado.
class RateScreen extends ConsumerStatefulWidget {
  const new({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends ConsumerState<RateScreen> {
  // Como la maqueta: empieza en 5 ("¡Excelente!").
  int _stars = 5;
  final Set<RatingTag> _tags = {};
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _close() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  Future<void> _send(Order order) async {
    final messenger = ScaffoldMessenger.of(context);
    final other = order.otherName.trim().split(RegExp(r'\s+')).first;
    final allowed = order.isBuyer ? RatingTag.forSeller : RatingTag.forBuyer;
    setState(() => _sending = true);
    try {
      await ref
          .read(reputationRepositoryProvider)
          .rate(
            order.id,
            NewRating(
              stars: _stars,
              tags: [
                for (final tag in allowed)
                  if (_tags.contains(tag)) tag,
              ],
              comment: _comment.text.trim().isEmpty
                  ? null
                  : _comment.text.trim(),
            ),
          );
      if (!mounted) return;
      ref.invalidate(orderProvider(order.id));
      // Como la maqueta: regresa a Inicio con el aviso.
      context.go(AppRoutes.home);
      showMusubiSnack(
        messenger,
        '¡Gracias! Tu calificación ya está en el perfil de $other.',
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _sending = false);
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
      // Ya calificado o fuera de plazo: "Tu pedido" se pone al dia.
      if (failure.code == 'ratings.already_rated' ||
          failure.code == 'ratings.expired') {
        ref.invalidate(orderProvider(order.id));
        _close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final order = ref.watch(orderProvider(widget.orderId));
    return Scaffold(
      backgroundColor: c.background,
      body: switch (order) {
        AsyncData(:final value) => _Body(
          order: value,
          stars: _stars,
          tags: _tags,
          comment: _comment,
          sending: _sending,
          onStars: (n) => setState(() => _stars = n),
          onTag: (tag) => setState(
            () => _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag),
          ),
          onSend: () => unawaited(_send(value)),
          onClose: _close,
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

class _Body extends StatelessWidget {
  const new({
    required this.order,
    required this.stars,
    required this.tags,
    required this.comment,
    required this.sending,
    required this.onStars,
    required this.onTag,
    required this.onSend,
    required this.onClose,
  });

  final Order order;
  final int stars;
  final Set<RatingTag> tags;
  final TextEditingController comment;
  final bool sending;
  final ValueChanged<int> onStars;
  final ValueChanged<RatingTag> onTag;
  final VoidCallback onSend;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final other = order.otherName.trim().split(RegExp(r'\s+')).first;
    final options = order.isBuyer ? RatingTag.forSeller : RatingTag.forBuyer;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(onClose: onClose),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Who(order: order, other: other),
                  _Stars(stars: stars, onStars: onStars),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      ratingWords(stars),
                      key: const Key('rate-words'),
                      textAlign: TextAlign.center,
                      style: MusubiType.style(
                        15,
                        weight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  _Tags(options: options, selected: tags, onTag: onTag),
                  _Comment(
                    controller: comment,
                    other: other,
                    enabled: !sending,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottom),
            child: Column(
              spacing: 4,
              children: [
                MusubiButton(
                  key: const Key('rate-send'),
                  label: 'Enviar calificación',
                  loadingLabel: 'Enviando…',
                  loading: sending,
                  onPressed: sending ? null : onSend,
                ),
                MusubiButton(
                  key: const Key('rate-later'),
                  label: 'Ahora no',
                  kind: MusubiButtonKind.quiet,
                  height: MusubiSizes.minTouch,
                  onPressed: sending ? null : onClose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Cerrar" y la pildora verde "Pedido completado".
class _Header extends StatelessWidget {
  const new({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: MusubiSizes.minTouch,
        child: Row(
          children: [
            Pressable(
              key: const Key('rate-close'),
              onTap: onClose,
              semanticLabel: 'Cerrar',
              builder: (context, _) => SizedBox.square(
                dimension: MusubiSizes.minTouch,
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.x,
                    size: 22,
                    strokeWidth: 1.9,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.successSoft,
                    borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      MusubiIcon(
                        MusubiIcons.circleCheck,
                        size: 14,
                        strokeWidth: 2.4,
                        color: c.successText,
                      ),
                      Flexible(
                        child: Text(
                          'Pedido completado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MusubiType.style(
                            12.5,
                            weight: FontWeight.w800,
                            color: c.successText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: MusubiSizes.minTouch),
          ],
        ),
      ),
    );
  }
}

/// Las iniciales de la otra parte con la foto del producto, "¿Como te fue
/// con Diego?" y "Calculadora Casio fx-991ES Plus · $500".
class _Who extends StatelessWidget {
  const new({required this.order, required this.other});

  final Order order;
  final String other;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Column(
        spacing: 10,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              InitialsAvatar(
                initials: initialsOf(order.otherName),
                size: 76,
                fontSize: 24,
                palette: 1,
              ),
              Positioned(
                right: -14,
                bottom: -4,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.background, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: ProductPhoto(url: order.item.photoUrl),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '¿Cómo te fue con $other?',
              key: const Key('rate-title'),
              textAlign: TextAlign.center,
              style: MusubiType.style(
                24,
                weight: FontWeight.w800,
                line: 30,
                em: -0.025,
                color: c.textPrimary,
              ),
            ),
          ),
          Text(
            '${order.item.title} · ${formatPrice(order.item.totalCents)}',
            textAlign: TextAlign.center,
            style: MusubiType.style(
              14,
              weight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cinco estrellas de 38 en botones de 50 (`role="radio"`).
class _Stars extends StatelessWidget {
  const new({required this.stars, required this.onStars});

  final int stars;
  final ValueChanged<int> onStars;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 2,
        children: [
          for (var n = 1; n <= 5; n++)
            Pressable(
              key: Key('rate-star-$n'),
              onTap: () => onStars(n),
              selected: n == stars,
              semanticLabel: n == 1 ? '1 estrella' : '$n estrellas',
              builder: (context, _) => SizedBox.square(
                dimension: 50,
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.star,
                    size: 38,
                    filled: true,
                    fillColor: n <= stars ? c.warning : c.border,
                    color: n <= stars ? c.warning : c.border,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "¿Que destacas?": chips que se encienden en rojo suave con palomita.
class _Tags extends StatelessWidget {
  const new({
    required this.options,
    required this.selected,
    required this.onTag,
  });

  final List<RatingTag> options;
  final Set<RatingTag> selected;
  final ValueChanged<RatingTag> onTag;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '¿Qué destacas?',
              style: MusubiType.style(
                14,
                weight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final tag in options)
                Pressable(
                  key: Key('rate-tag-${tag.code}'),
                  onTap: () => onTag(tag),
                  selected: selected.contains(tag),
                  semanticLabel: tag.label,
                  builder: (context, _) {
                    final on = selected.contains(tag);
                    // 44 de alto para el toque; el chip de 38 al ancho de su
                    // texto (un Center se estiraria a todo el renglon).
                    return SizedBox(
                      height: MusubiSizes.minTouch,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 38,
                            padding: EdgeInsets.only(
                              left: on ? 12 : 14,
                              right: 14,
                            ),
                            decoration: BoxDecoration(
                              color: on ? c.brandSoft : null,
                              borderRadius: BorderRadius.circular(
                                MusubiSizes.radiusChip,
                              ),
                              border: Border.all(
                                color: on ? c.brandSoftBorder : c.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 6,
                              children: [
                                if (on)
                                  MusubiIcon(
                                    MusubiIcons.check,
                                    size: 15,
                                    strokeWidth: 2.6,
                                    color: c.brandStrongText,
                                  ),
                                Text(
                                  tag.label,
                                  style: MusubiType.style(
                                    14,
                                    weight: on
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: on
                                        ? c.brandStrongText
                                        : c.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Cuentale a la comunidad" (opcional) y "Tu calificacion aparecera en el
/// perfil de Diego.".
class _Comment extends StatelessWidget {
  const new({
    required this.controller,
    required this.other,
    required this.enabled,
  });

  final TextEditingController controller;
  final String other;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final text = MusubiType.style(15, line: 22, color: c.textPrimary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          // Una sola linea con la base comun (como `align-items: baseline`).
          Text.rich(
            TextSpan(
              text: 'Cuéntale a la comunidad',
              style: MusubiType.style(
                14,
                weight: FontWeight.w800,
                color: c.textPrimary,
              ),
              children: [
                TextSpan(
                  text: '  Opcional',
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
              border: Border.all(color: c.border, width: 1.5),
            ),
            child: TextField(
              key: const Key('rate-comment'),
              controller: controller,
              enabled: enabled,
              minLines: 2,
              maxLines: 4,
              style: text,
              cursorColor: c.brand,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [
                LengthLimitingTextInputFormatter(ratingCommentMax),
              ],
              decoration: InputDecoration.collapsed(
                hintText: 'Cuenta cómo te fue',
                hintStyle: text.copyWith(color: c.textSecondary),
              ),
            ),
          ),
          Row(
            spacing: 6,
            children: [
              MusubiIcon(MusubiIcons.eye, size: 14, color: c.textSecondary),
              Expanded(
                child: Text(
                  'Tu calificación aparecerá en el perfil de $other.',
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
