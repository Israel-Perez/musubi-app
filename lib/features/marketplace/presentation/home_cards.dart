import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/css_dashes.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Tarjetas de la vitrina (maquetas `Inicio-visitante` e `Inicio`).

const _white = Color(0xFFFFFFFF);

/// Foto de un producto: de la red o, con `asset:`, empaquetada (catalogo de
/// muestra). Agotado: en grises y tenue. En modo noche se oscurece un poco
/// (`img{filter:brightness(.94)}`).
class ProductPhoto extends StatelessWidget {
  const new({required this.url, super.key, this.soldOut = false});

  final String? url;
  final bool soldOut;

  static const _grayscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  static const _dim = ColorFilter.matrix([
    0.94, 0, 0, 0, 0, //
    0, 0.94, 0, 0, 0, //
    0, 0, 0.94, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final url = this.url;
    var photo = switch (url) {
      null => const SizedBox.expand(),
      _ when url.startsWith('asset:') => Image.asset(
        url.substring('asset:'.length),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
      _ => Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    };
    if (c.isDark) photo = ColorFiltered(colorFilter: _dim, child: photo);
    if (soldOut) {
      photo = Opacity(
        opacity: 0.55,
        child: ColorFiltered(colorFilter: _grayscale, child: photo),
      );
    }
    return ColoredBox(color: c.surface, child: photo);
  }
}

/// "● Quedan 2" / "● Último" sobre la foto. [compact] es la de `Inicio`.
class StockPill extends StatelessWidget {
  const new({required this.label, super.key, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(6, 3, 8, 3)
          : const EdgeInsets.fromLTRB(7, 4, 9, 4),
      decoration: BoxDecoration(
        color: c.warningSoft,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c.warning, shape: BoxShape.circle),
          ),
          Text(
            label,
            style: MusubiType.style(
              compact ? 11 : 11.5,
              weight: FontWeight.w800,
              line: 15,
              color: c.warningText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Corazon de "Guardar": circulo de 32 sobre la foto dentro de 44 tocables.
class SaveButton extends StatelessWidget {
  const new({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onPressed,
      semanticLabel: 'Guardar',
      pressScale: 0.92,
      builder: (context, _) => SizedBox.square(
        dimension: MusubiSizes.minTouch,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.overlayPill,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: MusubiIcon(
                MusubiIcons.heart,
                size: 17,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Popular: foto con su lugar (1, 2, 3...) y las vistas del periodo. La de
/// visitante mide 164 x 196; la de `Inicio`, 156 x 164 y dice quien vende.
class PopularCard extends StatelessWidget {
  const new({
    required this.rank,
    required this.product,
    required this.onSave,
    super.key,
    this.member = false,
    this.onTap,
  });

  final int rank;
  final ProductSummary product;
  final VoidCallback onSave;
  final bool member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final stock = product.stockLabel;
    final seller = product.sellerName;
    final rating = product.sellerRating;

    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(
        member ? 18 : MusubiSizes.radiusWanted,
      ),
      child: SizedBox(
        height: member ? 164 : 196,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductPhoto(url: product.photoUrl),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: member ? 84 : 96,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x001C1C1E), Color(0xA81C1C1E)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: member ? 10 : 12,
              bottom: 2,
              child: Semantics(
                label: 'Lugar $rank',
                child: ExcludeSemantics(
                  child: Text(
                    '$rank',
                    style: MusubiType.style(
                      member ? 58 : 68,
                      weight: FontWeight.w800,
                      line: member ? 58 : 68,
                      em: -0.06,
                      color: _white,
                      tabular: true,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: member ? 8 : 10,
              bottom: member ? 10 : 12,
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: c.overlayPill,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    MusubiIcon(
                      MusubiIcons.eye,
                      size: 13,
                      strokeWidth: 2.4,
                      color: c.brandText,
                    ),
                    Text(
                      '${product.views} vistas',
                      style: MusubiType.style(
                        11.5,
                        weight: FontWeight.w800,
                        color: c.textPrimary,
                        tabular: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (stock != null)
              Positioned(
                left: 8,
                top: 8,
                child: StockPill(label: stock, compact: member),
              ),
          ],
        ),
      ),
    );

    final card = Pressable(
      onTap: onTap,
      pressScale: 0.97,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: MusubiSizes.space2,
        children: [
          photo,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: member ? 2 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: member ? 2 : 1,
              children: [
                Text(
                  formatPrice(product.priceCents),
                  style: MusubiType.price.copyWith(color: c.textPrimary),
                ),
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    13.5,
                    weight: FontWeight.w600,
                    line: 18,
                    color: c.textPrimary,
                  ),
                ),
                if (member && seller != null)
                  Row(
                    spacing: 4,
                    children: [
                      MusubiIcon(
                        MusubiIcons.star,
                        size: 12,
                        fillColor: c.warning,
                      ),
                      Flexible(
                        child: Text(
                          rating == null
                              ? seller
                              : '${rating.toStringAsFixed(1)} · $seller',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MusubiType.style(
                            12,
                            weight: FontWeight.w600,
                            line: 18,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      width: member ? 156 : 164,
      child: Stack(
        children: [
          card,
          Positioned(top: 2, right: 2, child: SaveButton(onPressed: onSave)),
        ],
      ),
    );
  }
}

/// Recien publicado del mosaico de visitante: alto alternado (200 o 156),
/// precio en pastilla y "Agotado" al centro.
class MosaicTile extends StatelessWidget {
  const new({
    required this.product,
    required this.height,
    required this.onSave,
    super.key,
    this.onTap,
  });

  final ProductSummary product;
  final double height;
  final VoidCallback onSave;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final stock = product.stockLabel;
    final ink = product.soldOut ? c.textSecondary : c.textPrimary;
    final tile = Pressable(
      onTap: onTap,
      pressScale: 0.97,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: MusubiSizes.space2,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductPhoto(url: product.photoUrl, soldOut: product.soldOut),
                  if (stock != null)
                    Positioned(left: 8, top: 8, child: StockPill(label: stock)),
                  if (product.soldOut)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: c.inverse,
                          borderRadius: BorderRadius.circular(
                            MusubiSizes.radiusChip,
                          ),
                        ),
                        child: Text(
                          'Agotado',
                          style: MusubiType.style(
                            12,
                            weight: FontWeight.w800,
                            line: 16,
                            color: _white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusChip,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F1C1C1E),
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        formatPrice(product.priceCents),
                        style: MusubiType.style(
                          14,
                          weight: FontWeight.w800,
                          line: 18,
                          color: ink,
                          tabular: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.style(
                13.5,
                weight: FontWeight.w700,
                line: 18,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
    return Stack(
      children: [
        tile,
        Positioned(top: 2, right: 2, child: SaveButton(onPressed: onSave)),
      ],
    );
  }
}

/// Recien publicado de `Inicio` (con sesion): foto de 150, estado, nombre en
/// dos lineas y "hace 20 min · Jorge S.".
class RecentTile extends StatelessWidget {
  const new({
    required this.product,
    required this.now,
    required this.onSave,
    super.key,
    this.onTap,
  });

  final ProductSummary product;
  final DateTime now;
  final VoidCallback onSave;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final stock = product.stockLabel;
    final published = product.publishedAt;
    final meta = [
      if (published != null) timeAgo(published, now),
      ?product.sellerName,
    ].join(' · ');
    final tile = Pressable(
      onTap: onTap,
      pressScale: 0.97,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: MusubiSizes.space2,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
            child: SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductPhoto(url: product.photoUrl, soldOut: product.soldOut),
                  if (product.condition != null)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: c.overlayPill,
                          borderRadius: BorderRadius.circular(
                            MusubiSizes.radiusChip,
                          ),
                        ),
                        child: Text(
                          product.condition!,
                          style: MusubiType.style(
                            11,
                            weight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  if (stock != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: StockPill(label: stock, compact: true),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  formatPrice(product.priceCents),
                  style: MusubiType.price.copyWith(color: c.textPrimary),
                ),
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    13.5,
                    weight: FontWeight.w600,
                    line: 18,
                    color: c.textPrimary,
                  ),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w600,
                      line: 18,
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return Stack(
      children: [
        tile,
        Positioned(top: 2, right: 2, child: SaveButton(onPressed: onSave)),
      ],
    );
  }
}

/// Icono del boleto "Se busca" segun la categoria.
MusubiIconData wantedIcon(String? category) => switch (category) {
  'laboratorio' => MusubiIcons.flaskConical,
  'tecnologia' || 'laptops' => MusubiIcons.laptop,
  'libros' => MusubiIcons.bookOpen,
  _ => MusubiIcons.megaphone,
};

/// Boleto "Se busca": presupuesto al frente, linea punteada con muescas y
/// "Yo tengo este producto". El de visitante mide 268; el de `Inicio`, 290
/// y lleva la etiqueta "SE BUSCA" con la categoria.
class WantedTicket extends StatelessWidget {
  const new({
    required this.wanted,
    required this.onOffer,
    super.key,
    this.member = false,
    this.now,
  });

  final WantedSummary wanted;
  final VoidCallback onOffer;
  final bool member;

  /// Para "hace 20 min" en la version con sesion.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final caption = MusubiType.style(
      10.5,
      weight: FontWeight.w700,
      em: 0.05,
      color: member ? c.textSecondary : c.textTertiary,
    );
    final created = wanted.createdAt;
    final meta = [
      ?wanted.categoryName,
      if (created != null && now != null) timeAgo(created, now!),
    ].join(' · ');

    final header = member
        ? Row(
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: c.brand,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    const MusubiIcon(
                      MusubiIcons.megaphone,
                      size: 12,
                      strokeWidth: 2.4,
                      color: _white,
                    ),
                    Text(
                      'SE BUSCA',
                      style: MusubiType.style(
                        10.5,
                        weight: FontWeight.w800,
                        em: 0.06,
                        color: _white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  meta,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          )
        : Row(
            spacing: 12,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
                ),
                child: Center(
                  child: MusubiIcon(
                    wantedIcon(wanted.category),
                    size: 22,
                    strokeWidth: 1.9,
                    color: c.brandText,
                  ),
                ),
              ),
              Expanded(child: _title(c)),
            ],
          );

    final budget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(member ? 'PRESUPUESTO MÁX.' : 'PAGA HASTA', style: caption),
        Text(
          formatPrice(wanted.budgetCents),
          style: MusubiType.style(
            member ? 24 : 26,
            weight: FontWeight.w800,
            line: 30,
            em: -0.02,
            color: c.brandStrongText,
            tabular: true,
          ),
        ),
      ],
    );

    final date = member
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('LO NECESITA', style: caption),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  MusubiIcon(
                    MusubiIcons.calendar,
                    size: 14,
                    color: c.textPrimary,
                  ),
                  Text(
                    shortDate(wanted.neededBy),
                    style: MusubiType.style(
                      14,
                      weight: FontWeight.w700,
                      line: 22,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                MusubiIcon(
                  MusubiIcons.calendar,
                  size: 14,
                  color: c.textPrimary,
                ),
                Text(
                  shortDate(wanted.neededBy),
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          );

    return Container(
      width: member ? 290 : 268,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(
          member ? 20 : MusubiSizes.radiusWanted,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: member ? 10 : 12,
        children: [
          header,
          if (member)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 42),
              child: _title(c),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: member ? 2 : 0),
            child: const TicketSeparator(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: MusubiSizes.space2,
            children: [
              // Con letra muy grande el precio se reduce antes que desbordar.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: budget,
                ),
              ),
              date,
            ],
          ),
          MusubiButton(
            label: 'Yo tengo este producto',
            height: MusubiSizes.buttonHeightSmall,
            icon: MusubiIcons.hand,
            onPressed: onOffer,
          ),
        ],
      ),
    );
  }

  Widget _title(MusubiColors c) => Text(
    wanted.title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: MusubiType.style(
      member ? 16 : 15.5,
      weight: FontWeight.w800,
      line: member ? 21 : 20,
      em: -0.01,
      color: c.textPrimary,
    ),
  );
}

/// Linea punteada del boleto con sus muescas (circulos del color del fondo
/// a los lados). Ocupa el ancho del boleto, fuera de su relleno.
class TicketSeparator extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    // Se pinta 16 px hacia cada lado, sobre el relleno del boleto.
    return SizedBox(
      width: double.infinity,
      height: 1.5,
      child: CustomPaint(
        painter: _TicketLinePainter(line: c.ticketLine, notch: c.background),
      ),
    );
  }
}

class _TicketLinePainter extends CustomPainter {
  const new({required this.line, required this.notch});

  final Color line;
  final Color notch;

  @override
  void paint(Canvas canvas, Size size) {
    // El boleto tiene 16 de relleno: la linea va de borde a borde.
    const bleed = 16.0;
    const left = -bleed;
    final right = size.width + bleed;
    paintCssDashedLine(canvas, left: left, right: right, top: 0, color: line);
    final fill = Paint()..color = notch;
    canvas
      ..drawCircle(const Offset(left, -1), 9, fill)
      ..drawCircle(Offset(right, -1), 9, fill);
  }

  @override
  bool shouldRepaint(_TicketLinePainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.notch != notch;
}

/// "Ver todo lo nuevo · 48 productos" (`Inicio` con sesion).
class SeeAllNewCard extends StatelessWidget {
  const new({
    required this.photos,
    required this.total,
    required this.onTap,
    super.key,
  });

  final List<String?> photos;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final shown = photos.take(4).toList();
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Ver todo lo nuevo, $total productos',
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pressed ? c.surfacePressed : c.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: MusubiSizes.space3,
          children: [
            Row(
              spacing: 6,
              children: [
                // Cinco columnas de la maqueta: cuatro fotos y el "+N".
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: i < shown.length
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ProductPhoto(url: shown[i]),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+${total - 4}',
                        style: MusubiType.style(
                          14,
                          weight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              spacing: MusubiSizes.space3,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        'Ver todo lo nuevo',
                        style: MusubiType.style(
                          15.5,
                          weight: FontWeight.w800,
                          line: 21,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        '$total productos',
                        style: MusubiType.style(
                          12.5,
                          weight: FontWeight.w600,
                          line: 17,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: pressed ? c.brandPressed : c.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: MusubiIcon(
                      MusubiIcons.arrowRight,
                      size: 20,
                      color: _white,
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

/// Seccion sin datos todavia: dice por que y que hacer (sin catalogo real).
class EmptyShelf extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
    this.tinted = false,
  });

  final MusubiIconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return RiseIn(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: tinted ? c.brandSoft : c.surface,
          borderRadius: BorderRadius.circular(MusubiSizes.radiusWanted),
        ),
        child: Column(
          spacing: MusubiSizes.space2,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: c.background,
                borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
              ),
              child: Center(
                child: MusubiIcon(
                  icon,
                  size: 26,
                  strokeWidth: 1.9,
                  color: c.brandText,
                ),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: MusubiType.style(
                16,
                weight: FontWeight.w800,
                line: 21,
                color: c.textPrimary,
              ),
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: MusubiType.style(14, line: 20, color: c.textSecondary),
            ),
            const SizedBox(height: MusubiSizes.space1),
            MusubiButton(
              label: actionLabel,
              height: MusubiSizes.buttonHeightSmall,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}
