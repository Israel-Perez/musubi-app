import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Tarjetas de la vitrina (maqueta `Inicio-visitante`): populares con su
/// lugar, recien publicados en cuadricula y boletos "Se busca".

/// Foto del producto o, sin foto, un icono sobre la superficie.
class _ProductPhoto extends StatelessWidget {
  const new({required this.product, required this.height});

  final ProductSummary product;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final url = product.photoUrl;
    final photo = url == null
        ? Center(
            child: Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: c.textSecondary,
            ),
          )
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: c.textSecondary,
              ),
            ),
          );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
        child: ColoredBox(
          color: c.surface,
          child: product.soldOut
              ? ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFBDBDBD),
                    BlendMode.saturation,
                  ),
                  child: Opacity(opacity: 0.7, child: photo),
                )
              : photo,
        ),
      ),
    );
  }
}

/// Pastilla blanca sobre la foto ("Quedan 2", "128 vistas", precio).
class _Pill extends StatelessWidget {
  const new({required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
    ),
    child: DefaultTextStyle.merge(
      style: MusubiType.label.copyWith(
        color: dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E),
        fontWeight: FontWeight.w800,
      ),
      child: child,
    ),
  );
}

class _StockPill extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => _Pill(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: context.musubi.warning,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: MusubiColors.light.warningText)),
      ],
    ),
  );
}

/// Corazon de "Guardar" (visitante: pide la cuenta).
class SaveButton extends StatelessWidget {
  const new({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Guardar',
    excludeSemantics: true,
    child: Material(
      color: const Color(0xFFFFFFFF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox.square(
          dimension: MusubiSizes.minTouch - 12,
          child: Icon(
            Icons.favorite_border,
            size: 19,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ),
    ),
  );
}

/// Popular: foto con su lugar (1, 2, 3...) y las vistas del periodo.
class PopularCard extends StatelessWidget {
  const new({
    required this.rank,
    required this.product,
    required this.onSave,
    super.key,
  });

  final int rank;
  final ProductSummary product;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stock = product.stockLabel;
    return SizedBox(
      width: 164,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _ProductPhoto(product: product, height: 196),
              if (stock != null)
                Positioned(top: 8, left: 8, child: _StockPill(label: stock)),
              Positioned(
                top: 6,
                right: 6,
                child: SaveButton(onPressed: onSave),
              ),
              Positioned(
                left: 10,
                bottom: -6,
                child: Text(
                  '$rank',
                  style: MusubiType.display.copyWith(
                    fontSize: 64,
                    height: 1,
                    color: const Color(0xFFFFFFFF),
                    shadows: const [
                      Shadow(blurRadius: 12, color: Color(0x66000000)),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: _Pill(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: context.musubi.brand,
                      ),
                      const SizedBox(width: 4),
                      Text('${product.views} vistas'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MusubiSizes.space2),
          Text(formatPrice(product.priceCents), style: MusubiType.price),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Recien publicado (cuadricula de 2 columnas).
class ProductTile extends StatelessWidget {
  const new({required this.product, required this.onSave, super.key});

  final ProductSummary product;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stock = product.stockLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            _ProductPhoto(product: product, height: 180),
            if (stock != null)
              Positioned(top: 8, left: 8, child: _StockPill(label: stock)),
            Positioned(top: 6, right: 6, child: SaveButton(onPressed: onSave)),
            if (product.soldOut)
              const Positioned.fill(
                child: Center(child: _Pill(dark: true, child: Text('Agotado'))),
              ),
            Positioned(
              left: 8,
              bottom: 8,
              child: _Pill(child: Text(formatPrice(product.priceCents))),
            ),
          ],
        ),
        const SizedBox(height: MusubiSizes.space2),
        Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            color: product.soldOut ? context.musubi.textSecondary : null,
          ),
        ),
      ],
    );
  }
}

/// Boleto "Se busca": presupuesto al frente y "Yo tengo este producto".
class WantedTicket extends StatelessWidget {
  const new({required this.wanted, required this.onOffer, super.key});

  final WantedSummary wanted;
  final VoidCallback onOffer;

  static const _days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// "lun 5 oct".
  static String shortDate(DateTime date) =>
      '${_days[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: 268,
      padding: const EdgeInsets.all(MusubiSizes.space4),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusWanted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
                ),
                child: Icon(Icons.campaign_outlined, color: c.brandText),
              ),
              const SizedBox(width: MusubiSizes.space3),
              Expanded(
                child: Text(
                  wanted.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MusubiSizes.space3),
            child: Divider(color: c.brand.withValues(alpha: 0.25), height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAGA HASTA',
                      style: MusubiType.overline.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    Text(
                      formatPrice(wanted.budgetCents),
                      style: MusubiType.title1.copyWith(color: c.brandText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MusubiSizes.space2,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: c.textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shortDate(wanted.neededBy),
                      style: MusubiType.label.copyWith(color: c.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MusubiSizes.space3),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: MusubiSizes.buttonHeightCard - 4,
            child: FilledButton.icon(
              onPressed: onOffer,
              icon: const Icon(Icons.front_hand_outlined, size: 18),
              label: const Text('Yo tengo este producto'),
            ),
          ),
        ],
      ),
    );
  }
}
