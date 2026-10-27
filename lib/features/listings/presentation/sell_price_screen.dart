import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/css_line_box.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/shake.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';
import 'package:musubi_app/features/listings/presentation/sell_layout.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Icono de una categoria (maqueta `Vender-3`).
MusubiIconData categoryIcon(String slug) => switch (slug) {
  'calculadoras' => MusubiIcons.calculator,
  'libros' => MusubiIcons.bookOpen,
  'laptops' => MusubiIcons.laptop,
  'laboratorio' => MusubiIcons.flaskConical,
  'dibujo' => MusubiIcons.ruler,
  'electronica' => MusubiIcons.cpu,
  _ => MusubiIcons.tagPlain,
};

/// `Vender-3`: "Precio y categoría".
class SellPriceScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SellPriceScreen> createState() => _SellPriceScreenState();
}

class _SellPriceScreenState extends ConsumerState<SellPriceScreen> {
  late final _price = TextEditingController(
    text: switch (ref.read(sellDraftProvider).priceCents) {
      0 => '',
      final cents => '${cents ~/ 100}',
    },
  );
  final _priceFocus = FocusNode();
  bool _priceError = false;
  Object? _priceShake;
  Object? _categoryShake;

  @override
  void dispose() {
    _price.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  void _continue() {
    final draft = ref.read(sellDraftProvider);
    if (draft.priceCents <= 0) {
      setState(() {
        _priceError = true;
        _priceShake = Object();
      });
      showSellSnack(
        context,
        'Ponle un precio a tu producto',
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
      return;
    }
    if (draft.category == null) {
      setState(() => _categoryShake = Object());
      showSellSnack(
        context,
        'Elige una categoría',
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
      return;
    }
    unawaited(context.push(AppRoutes.sellCondition));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final draft = ref.watch(sellDraftProvider);
    final notifier = ref.read(sellDraftProvider.notifier);
    final categories = ref.watch(sellCategoriesProvider);
    final category = draft.category;
    final range = category == null
        ? null
        : ref.watch(priceRangeProvider(category)).value;
    return SellStepLayout(
      step: 3,
      label: 'Precio',
      title: 'Precio y categoría',
      actions: [
        SizedBox(
          width: 112,
          child: MusubiButton(
            label: 'Atrás',
            kind: MusubiButtonKind.secondary,
            onPressed: () => context.pop(),
          ),
        ),
        Expanded(
          child: MusubiButton(label: 'Continuar', onPressed: _continue),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              CssLineBox(
                fontSize: 13,
                child: Text(
                  'Precio',
                  style: MusubiType.label.copyWith(color: c.textPrimary),
                ),
              ),
              Shake(
                trigger: _priceShake,
                pattern: ShakePattern.field,
                child: SellFieldBox(
                  focusNode: _priceFocus,
                  error: _priceError && draft.priceCents <= 0,
                  radius: MusubiSizes.radiusButton,
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    spacing: 6,
                    children: [
                      Text(
                        r'$',
                        style: MusubiType.style(
                          28,
                          weight: FontWeight.w800,
                          color: c.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          key: const Key('sell-price'),
                          controller: _price,
                          focusNode: _priceFocus,
                          keyboardType: TextInputType.number,
                          cursorColor: c.brand,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: (value) {
                            notifier.setPrice((int.tryParse(value) ?? 0) * 100);
                            if (_priceError) setState(() {});
                          },
                          style: MusubiType.style(
                            30,
                            weight: FontWeight.w800,
                            em: -0.02,
                            color: c.textPrimary,
                            tabular: true,
                          ),
                          decoration: InputDecoration.collapsed(
                            hintText: '0',
                            hintStyle: MusubiType.style(
                              30,
                              weight: FontWeight.w800,
                              em: -0.02,
                              color: c.placeholder,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'MXN',
                        style: MusubiType.style(
                          14,
                          weight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (range != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _PriceRangeCard(range: range, price: draft.priceCents),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              CssLineBox(
                fontSize: 13,
                child: Text(
                  'Categoría',
                  style: MusubiType.label.copyWith(color: c.textPrimary),
                ),
              ),
              Shake(
                trigger: _categoryShake,
                pattern: ShakePattern.field,
                child: switch (categories) {
                  AsyncData(:final value) => _CategoryGrid(
                    categories: value,
                    selected: category,
                    onSelect: notifier.setCategory,
                  ),
                  AsyncError() => _CategoriesError(
                    onRetry: () => ref.invalidate(sellCategoriesProvider),
                  ),
                  _ => const SizedBox(
                    height: 48 * 3 + 16,
                    child: Center(child: MusubiSpinner()),
                  ),
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const new({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<CatalogCategory> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: Pressable(
                  key: Key('sell-category-${category.slug}'),
                  onTap: () => onSelect(category.slug),
                  selected: category.slug == selected,
                  semanticLabel: category.name,
                  builder: (context, pressed) {
                    final on = category.slug == selected;
                    final ink = on ? c.brandStrongText : c.textPrimary;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: on
                            ? c.brandSoft
                            : pressed
                            ? c.surface
                            : c.background,
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusField,
                        ),
                        border: Border.all(
                          color: on ? c.brandBorder : c.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          MusubiIcon(
                            categoryIcon(category.slug),
                            size: 18,
                            strokeWidth: 1.9,
                            color: ink,
                          ),
                          Expanded(
                            child: Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MusubiType.style(
                                14,
                                weight: on ? FontWeight.w800 : FontWeight.w600,
                                color: ink,
                              ),
                            ),
                          ),
                          if (on)
                            MusubiIcon(
                              MusubiIcons.check,
                              size: 16,
                              strokeWidth: 2.8,
                              color: ink,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoriesError extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 4,
    children: [
      Text(
        'No pudimos cargar las categorías.',
        style: MusubiType.style(
          14,
          weight: FontWeight.w600,
          color: context.musubi.textSecondary,
        ),
      ),
      MusubiButton(
        label: 'Reintentar',
        kind: MusubiButtonKind.link,
        expand: false,
        onPressed: onRetry,
      ),
    ],
  );
}

/// "Productos parecidos se venden entre $X y $Y." con la barra y la marca
/// del precio (maqueta `Vender-3`).
class _PriceRangeCard extends StatelessWidget {
  const new({required this.range, required this.price});

  final PriceRange range;
  final int price;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final low = range.lowCents;
    final high = range.highCents;
    // Como la maqueta: la franja ocupa del 22 % al 70 % de la barra.
    final width = (high - low).clamp(1, 1 << 40);
    final min = low - 0.22 * width / 0.48;
    final max = high + 0.30 * width / 0.48;
    final at = ((price - min) / (max - min)).clamp(0.0, 1.0);
    final (message, color) = price < low
        ? ('Tu precio está abajo del rango: se venderá rápido', c.successText)
        : price > high
        ? (
            'Tu precio está arriba del rango: podría tardar en venderse',
            c.error,
          )
        : ('Tu precio está dentro del rango', c.successText);
    final bold = MusubiType.style(
      13,
      weight: FontWeight.w800,
      line: 18,
      color: c.textPrimary,
    );
    return Container(
      key: const Key('sell-price-range'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          MusubiIcon(
            MusubiIcons.tag,
            size: 18,
            strokeWidth: 1.9,
            color: c.textPrimary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Text.rich(
                  TextSpan(
                    style: MusubiType.style(
                      13,
                      weight: FontWeight.w600,
                      line: 18,
                      color: c.textPrimary,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Productos parecidos se venden entre ',
                      ),
                      TextSpan(text: formatPrice(low), style: bold),
                      const TextSpan(text: ' y '),
                      TextSpan(text: formatPrice(high), style: bold),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    // Barra de 6 de alto; la marca de 16 sobresale 5 arriba.
                    return SizedBox(
                      height: 6,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          Positioned(
                            left: w * 0.22,
                            right: w * 0.30,
                            top: 0,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.successBand,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 250),
                            curve: musubiEaseOut,
                            left: w * at - 8,
                            top: -5,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: c.brand,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFFFFF),
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x4D1C1C1E),
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Text(
                  message,
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w700,
                    color: color,
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
