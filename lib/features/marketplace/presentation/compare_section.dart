import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/marketplace/domain/comparison.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/comparison_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';

/// "Compara antes de comprar" (maqueta `Producto`, HU-51): la barra de precios
/// del mismo modelo (o de la categoria), "Ordenar por" con cuatro pestanas y
/// hasta 5 opciones con su lugar, insignias, diferencia de precio y quien
/// vende. Sin opciones (o si la API falla) no se muestra.
class CompareSection extends ConsumerStatefulWidget {
  const new({
    required this.productId,
    required this.currentPriceCents,
    required this.categoryName,
    required this.campus,
    required this.onOpen,
    required this.onSeeAll,
    super.key,
  });

  final String productId;
  final int currentPriceCents;
  final String categoryName;

  /// Siglas del campus ("UTTT").
  final String campus;
  final ValueChanged<ProductSummary> onOpen;
  final VoidCallback onSeeAll;

  @override
  ConsumerState<CompareSection> createState() => _CompareSectionState();
}

class _CompareSectionState extends ConsumerState<CompareSection> {
  CompareOrder _order = CompareOrder.forYou;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final options =
        ref.watch(comparisonProvider(widget.productId)).value ?? const [];
    if (options.isEmpty) return const SizedBox.shrink();
    final comparison = Comparison(widget.currentPriceCents, options);
    final band = comparison.priceBand!;
    // HU-58: la estimacion del modelo de ML, debajo de la regla de la maqueta.
    final estimate = ref.watch(priceEstimateProvider(widget.productId)).value;
    final count = options.length;
    final same = comparison.sameModelCount;
    final subtitle =
        '$count ${count == 1 ? 'opción' : 'opciones'} en ${widget.campus}'
        '${same > 0 ? ' · $same del mismo modelo' : ''}';

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.surface, width: 8)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Compara antes de comprar',
                        style: MusubiType.style(
                          20,
                          weight: FontWeight.w800,
                          line: 26,
                          em: -0.02,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: MusubiType.style(
                        13.5,
                        weight: FontWeight.w600,
                        line: 19,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _PriceCard(
                  band: band,
                  title: band.sameModel
                      ? 'Este modelo en ${widget.campus}'
                      : '${widget.categoryName} en ${widget.campus}',
                  currentCents: widget.currentPriceCents,
                  estimate: estimate,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _OrderTabs(
                  order: _order,
                  onPick: (order) => setState(() => _order = order),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    for (final option in comparison.ranked(_order))
                      OptionCard(
                        key: Key('compare-${option.option.product.id}'),
                        option: option,
                        order: _order,
                        onTap: () => widget.onOpen(option.option.product),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _SeeAll(
                  label: seeAllLabel(widget.categoryName),
                  onTap: widget.onSeeAll,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Este modelo en UTTT", el veredicto, la barra y el promedio.
class _PriceCard extends StatelessWidget {
  const new({
    required this.band,
    required this.title,
    required this.currentCents,
    this.estimate,
  });

  final PriceBand band;
  final String title;
  final int currentCents;

  /// "Musubi estima $X – $Y para algo así" (HU-58), o `null`.
  final PriceEstimate? estimate;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final (verdictBg, verdictInk) = band.verdict == PriceVerdict.high
        ? (c.warningSoft, c.warningText)
        : (c.successSoft, c.successText);
    final small = MusubiType.style(
      12,
      weight: FontWeight.w700,
      line: 16,
      color: c.textSecondary,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: MusubiType.style(
                    13.5,
                    weight: FontWeight.w800,
                    line: 18,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: verdictBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    MusubiIcon(
                      MusubiIcons.check,
                      size: 13,
                      strokeWidth: 2.8,
                      color: verdictInk,
                    ),
                    Text(
                      band.verdict.label,
                      style: MusubiType.style(
                        12,
                        weight: FontWeight.w800,
                        color: verdictInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 22,
              child: LayoutBuilder(
                builder: (context, box) {
                  double left(int percent, double size) =>
                      box.maxWidth * percent / 100 - size / 2;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 8,
                        height: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      for (final percent in band.otherPercents)
                        Positioned(
                          left: left(percent, 12),
                          top: 5,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: c.background,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.chevron, width: 3),
                            ),
                          ),
                        ),
                      Positioned(
                        left: left(band.currentPercent, 20),
                        top: 1,
                        child: Container(
                          key: const Key('compare-current'),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: c.brand,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.onBrand, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x59A50F15),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${formatPrice(band.minCents)} más bajo', style: small),
              Text('${formatPrice(band.maxCents)} más alto', style: small),
            ],
          ),
          Row(
            spacing: 6,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: c.brand,
                  shape: BoxShape.circle,
                ),
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Esta publicación: '),
                      TextSpan(
                        text: formatPrice(currentCents),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: ' · promedio ${formatPrice(band.averageCents)}',
                      ),
                    ],
                  ),
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w600,
                    line: 17,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (estimate case final e?)
            Row(
              key: const Key('compare-estimate'),
              spacing: 6,
              children: [
                MusubiIcon(
                  MusubiIcons.sparkle,
                  size: 12,
                  color: c.textSecondary,
                ),
                Flexible(
                  child: Text(
                    'Musubi estima ${formatPrice(e.minCents)} – '
                    '${formatPrice(e.maxCents)} para algo así · '
                    '${e.verdict.label.toLowerCase()}',
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w600,
                      line: 16,
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

/// "Ordenar por": Para ti, Reputación, Ventas y Precio, y su explicacion.
class _OrderTabs extends StatelessWidget {
  const new({required this.order, required this.onPick});

  final CompareOrder order;
  final ValueChanged<CompareOrder> onPick;

  static MusubiIconData _icon(CompareOrder order) => switch (order) {
    CompareOrder.forYou => MusubiIcons.sparkle,
    CompareOrder.reputation => MusubiIcons.starOutline,
    CompareOrder.sales => MusubiIcons.trendingUp,
    CompareOrder.price => MusubiIcons.tag,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(
          'Ordenar por',
          style: MusubiType.style(
            13,
            weight: FontWeight.w800,
            line: 16,
            color: c.textPrimary,
          ),
        ),
        Container(
          height: 56,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            spacing: 3,
            children: [
              for (final tab in CompareOrder.values)
                Expanded(
                  child: Pressable(
                    key: Key('compare-order-${tab.name}'),
                    onTap: () => onPick(tab),
                    semanticLabel: 'Ordenar por ${tab.label}',
                    selected: tab == order,
                    builder: (context, _) {
                      final on = tab == order;
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: on ? c.background : null,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: on
                              ? const [
                                  BoxShadow(
                                    color: Color(0x1F1C1C1E),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 3,
                          children: [
                            MusubiIcon(
                              _icon(tab),
                              size: 16,
                              color: on ? c.brand : c.textSecondary,
                            ),
                            Text(
                              tab.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MusubiType.style(
                                12,
                                weight: on ? FontWeight.w800 : FontWeight.w600,
                                line: 15,
                                color: on ? c.textPrimary : c.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        Row(
          spacing: 6,
          children: [
            MusubiIcon(MusubiIcons.info, size: 14, color: c.textSecondary),
            Flexible(
              child: Text(
                order.explanation,
                style: MusubiType.style(
                  12.5,
                  weight: FontWeight.w600,
                  line: 17,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Una opcion: foto con su lugar y estado, insignias, nombre, precio con la
/// diferencia, quien vende y su reputacion y ventas. La foto mide 96 de ancho
/// y crece con el texto (como `min-height` en la maqueta).
class OptionCard extends StatelessWidget {
  const new({
    required this.option,
    required this.order,
    required this.onTap,
    super.key,
  });

  final RankedOption option;
  final CompareOrder order;
  final VoidCallback onTap;

  static const _photo = 96.0;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final product = option.option.product;
    return Pressable(
      onTap: onTap,
      semanticLabel:
          '${option.rank}. ${product.title}, '
          '${formatPrice(product.priceCents)}',
      builder: (context, pressed) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pressed
                  ? c.surface
                  : option.best
                  ? c.brandWash
                  : c.background,
              border: Border.all(
                color: option.best ? c.brand : c.border,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: _photo + 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: _photo),
                    child: _OptionDetails(option: option, order: order),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _photo,
                  child: _OptionPhoto(option: option),
                ),
              ],
            ),
          ),
          if (option.best)
            Positioned(
              top: -11,
              left: 14,
              child: Container(
                key: const Key('compare-best'),
                height: 22,
                padding: const EdgeInsets.fromLTRB(7, 0, 9, 0),
                decoration: BoxDecoration(
                  color: c.brand,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    MusubiIcon(
                      MusubiIcons.sparkle,
                      size: 12,
                      strokeWidth: 2.2,
                      color: c.onBrand,
                    ),
                    Text(
                      'Mejor opción',
                      style: MusubiType.style(
                        11,
                        weight: FontWeight.w800,
                        line: 14,
                        color: c.onBrand,
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

/// La foto con el lugar (arriba) y el estado (abajo).
class _OptionPhoto extends StatelessWidget {
  const new({required this.option});

  final RankedOption option;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final product = option.option.product;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProductPhoto(url: product.photoUrl),
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.inverse,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${option.rank}',
                style: MusubiType.style(
                  11.5,
                  weight: FontWeight.w800,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
          if (product.condition case final condition?)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: c.overlayPill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  condition,
                  style: MusubiType.style(
                    10.5,
                    weight: FontWeight.w700,
                    line: 14,
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

/// Insignias, nombre, precio con su diferencia, quien vende y su reputacion.
class _OptionDetails extends StatelessWidget {
  const new({required this.option, required this.order});

  final RankedOption option;
  final CompareOrder order;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final product = option.option.product;
    final seller = option.option.seller;
    final difference = option.differenceCents;
    final (badgeBg, badgeInk) = switch (option.badge) {
      CompareBadge.bestReputation => (c.warningSoft, c.warningText),
      CompareBadge.mostSales => (c.infoSoft, c.infoText),
      CompareBadge.lowestPrice => (c.successSoft, c.successText),
      null => (c.surface, c.textTertiary),
    };
    final rating = seller.ratingAvg;
    final sales = seller.sales;
    final byReputation = order == CompareOrder.reputation;
    final bySales = order == CompareOrder.sales;

    Widget pill(String text, Color bg, Color ink, {double size = 10.5}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: MusubiType.style(
              size,
              weight: FontWeight.w800,
              line: 15,
              color: ink,
            ),
          ),
        );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (option.badge != null || option.option.sameModel)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (option.badge case final badge?)
                pill(badge.label, badgeBg, badgeInk),
              if (option.option.sameModel)
                pill('Mismo modelo', c.brandSoft, c.brandStrongText),
            ],
          ),
        Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MusubiType.style(
            14,
            weight: FontWeight.w700,
            line: 18,
            color: c.textPrimary,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatPrice(product.priceCents),
              style: MusubiType.style(
                18,
                weight: FontWeight.w800,
                line: 22,
                tabular: true,
                color: c.textPrimary,
              ),
            ),
            pill(
              difference < 0
                  ? '${formatPrice(-difference)} menos'
                  : difference > 0
                  ? '${formatPrice(difference)} más'
                  : 'Mismo precio',
              difference < 0 ? c.successSoft : c.surface,
              difference < 0 ? c.successText : c.textTertiary,
              size: 11.5,
            ),
          ],
        ),
        Row(
          spacing: 6,
          children: [
            InitialsAvatar(
              initials: initialsOf(seller.name),
              size: 18,
              fontSize: 8,
              palette: seller.id.codeUnits.fold(0, (a, b) => a + b) % 5,
            ),
            Flexible(
              child: Text(
                seller.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MusubiType.style(
                  12.5,
                  weight: FontWeight.w700,
                  line: 17,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: MusubiIcon(
                    MusubiIcons.star,
                    size: 12,
                    fillColor: c.warning,
                    color: c.warning,
                    filled: true,
                  ),
                ),
              ),
              if (rating != null) ...[
                TextSpan(
                  text: rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: byReputation ? c.textPrimary : c.textTertiary,
                    fontWeight: byReputation
                        ? FontWeight.w800
                        : FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' (${seller.ratingCount})'),
              ] else
                const TextSpan(text: 'Sin calificaciones'),
              if (sales != null) ...[
                const TextSpan(text: ' · '),
                TextSpan(
                  text: sales == 1 ? '1 venta' : '$sales ventas',
                  style: TextStyle(
                    color: bySales ? c.textPrimary : c.textSecondary,
                    fontWeight: bySales ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MusubiType.style(
            12,
            weight: FontWeight.w600,
            line: 17,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// "Ver todas las calculadoras" → la busqueda con esa categoria.
class _SeeAll extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, pressed) => Container(
        height: 50,
        decoration: BoxDecoration(
          color: pressed ? c.surface : null,
          border: Border.all(color: c.border, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MusubiType.style(
                  15,
                  weight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            MusubiIcon(
              MusubiIcons.arrowRight,
              size: 18,
              strokeWidth: 2.2,
              color: c.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
