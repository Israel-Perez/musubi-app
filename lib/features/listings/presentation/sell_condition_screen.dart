import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/css_line_box.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/sell_done_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';
import 'package:musubi_app/features/listings/presentation/sell_layout.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

/// `Vender-4`: "Estado y cantidad", la vista previa y "Publicar producto".
class SellConditionScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SellConditionScreen> createState() =>
      _SellConditionScreenState();
}

class _SellConditionScreenState extends ConsumerState<SellConditionScreen> {
  bool _publishing = false;

  Future<void> _publish() async {
    final cover = ref.read(sellDraftProvider).photos.firstOrNull?.path;
    setState(() => _publishing = true);
    try {
      final product = await ref.read(sellDraftProvider.notifier).publish();
      ref.invalidate(homeFeedProvider);
      if (!mounted) return;
      context.go(
        AppRoutes.sellDone,
        extra: PublishedListing(product: product, localCover: cover),
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _publishing = false);
      showSellSnack(
        context,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final draft = ref.watch(sellDraftProvider);
    final notifier = ref.read(sellDraftProvider.notifier);
    final used = draft.condition == ProductCondition.used;
    return SellStepLayout(
      step: 4,
      label: 'Último paso',
      title: 'Estado y cantidad',
      actions: [
        SizedBox(
          width: 112,
          child: MusubiButton(
            label: 'Atrás',
            kind: MusubiButtonKind.secondary,
            onPressed: _publishing ? null : () => context.pop(),
          ),
        ),
        Expanded(
          child: MusubiButton(
            key: const Key('sell-publish'),
            label: 'Publicar producto',
            loading: _publishing,
            loadingLabel: 'Publicando…',
            onPressed: _publish,
          ),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              CssLineBox(
                fontSize: 13,
                child: Text(
                  'Estado',
                  style: MusubiType.label.copyWith(color: c.textPrimary),
                ),
              ),
              // Como la cuadricula de la maqueta: las dos del mismo alto.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    for (final condition in ProductCondition.values)
                      Expanded(
                        child: _ConditionCard(
                          condition: condition,
                          selected: draft.condition == condition,
                          onTap: () => notifier.setCondition(condition),
                        ),
                      ),
                  ],
                ),
              ),
              // `margin-top: 6px` en la etiqueta y `-6px` en los chips: entre
              // los dos quedan 4.
              if (used)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      CssLineBox(
                        fontSize: 13,
                        child: Text(
                          '¿Cómo está?',
                          style: MusubiType.label.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final detail in UsedDetail.values)
                            _DetailChip(
                              detail: detail,
                              selected: draft.usedDetail == detail,
                              onTap: () => notifier.setUsedDetail(detail),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _QuantityRow(quantity: draft.quantity, onStep: notifier.step),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Text(
                'Así se verá tu publicación',
                style: MusubiType.style(
                  13,
                  weight: FontWeight.w700,
                  color: c.textSecondary,
                ),
              ),
              ListingPreviewCard(
                photo: _localPhoto(draft.photos.firstOrNull?.path),
                price: formatPrice(draft.priceCents),
                title: draft.title.trim(),
                footer: _Pill(text: draft.summaryLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget? _localPhoto(String? path) => path == null
      ? null
      : Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
}

class _ConditionCard extends StatelessWidget {
  const new({
    required this.condition,
    required this.selected,
    required this.onTap,
  });

  final ProductCondition condition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      key: Key('sell-condition-${condition.apiValue}'),
      onTap: onTap,
      selected: selected,
      semanticLabel: '${condition.label}: ${condition.description}',
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 76),
        // Container suma el borde al relleno, como `border-box` en CSS.
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? c.brandSoft
              : pressed
              ? c.surface
              : c.background,
          borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
          border: Border.all(
            color: selected ? c.brandBorder : c.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  condition.label,
                  style: MusubiType.style(
                    16,
                    weight: FontWeight.w800,
                    color: selected ? c.brandStrongText : c.textPrimary,
                  ),
                ),
                Text(
                  condition.description,
                  style: MusubiType.style(
                    12.5,
                    line: 17,
                    color: selected ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                // `top: 10; right: 10` desde el borde interior.
                top: -2,
                right: -4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: c.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: MusubiIcon(
                      MusubiIcons.check,
                      size: 13,
                      strokeWidth: 3,
                      color: Color(0xFFFFFFFF),
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

class _DetailChip extends StatelessWidget {
  const new({
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final UsedDetail detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      key: Key('sell-detail-${detail.apiValue}'),
      onTap: onTap,
      selected: selected,
      semanticLabel: detail.label,
      builder: (context, pressed) => SizedBox(
        height: MusubiSizes.minTouch,
        child: Center(
          widthFactor: 1,
          child: Container(
            height: 38,
            padding: EdgeInsets.only(left: selected ? 12 : 14, right: 14),
            decoration: BoxDecoration(
              color: selected
                  ? c.brandSoft
                  : pressed
                  ? c.surface
                  : c.background,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
              border: Border.all(
                color: selected ? c.brandSoftBorder : c.border,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                if (selected)
                  MusubiIcon(
                    MusubiIcons.check,
                    size: 15,
                    strokeWidth: 2.6,
                    color: c.brandStrongText,
                  ),
                Text(
                  detail.label,
                  style: MusubiType.style(
                    14,
                    weight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? c.brandStrongText : c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Piezas disponibles" con quitar y agregar (1 a 10, HU-50).
class _QuantityRow extends StatelessWidget {
  const new({required this.quantity, required this.onStep});

  final int quantity;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget button({
      required MusubiIconData icon,
      required String label,
      required bool enabled,
      required int delta,
    }) => Pressable(
      key: Key('sell-quantity-$delta'),
      onTap: enabled ? () => onStep(delta) : null,
      semanticLabel: label,
      builder: (context, pressed) => SizedBox.square(
        dimension: MusubiSizes.minTouch,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: enabled ? c.inverse : c.surface,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
            ),
            child: Center(
              child: MusubiIcon(
                icon,
                size: 18,
                strokeWidth: 2.4,
                color: enabled ? const Color(0xFFFFFFFF) : c.disabledIcon,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
        border: Border.all(color: c.border, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Piezas disponibles',
              style: MusubiType.style(
                15,
                weight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
          button(
            icon: MusubiIcons.minus,
            label: 'Quitar uno',
            enabled: quantity > 1,
            delta: -1,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24),
            child: Semantics(
              liveRegion: true,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: MusubiType.style(
                  18,
                  weight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          button(
            icon: MusubiIcons.plus,
            label: 'Agregar uno',
            enabled: quantity < SellDraft.maxQuantity,
            delta: 1,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Text(
        text,
        style: MusubiType.style(
          11,
          weight: FontWeight.w700,
          color: c.textPrimary,
        ),
      ),
    );
  }
}
