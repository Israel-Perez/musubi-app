import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';

/// Lo que llega a `Vender-listo`: la publicacion y la foto del telefono (se
/// ve al instante, sin esperar a CloudFront).
@immutable
class PublishedListing {
  const new({required this.product, this.localCover});

  final ProductSummary product;
  final String? localCover;
}

/// Tarjeta "Así se verá tu publicación" (`Vender-4`) y del producto recien
/// publicado (`Vender-listo`): foto de 84, precio, nombre y [footer].
class ListingPreviewCard extends StatelessWidget {
  const new({
    required this.photo,
    required this.price,
    required this.title,
    required this.footer,
    super.key,
  });

  final Widget? photo;
  final String price;
  final String title;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1C1C1E),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color(0x141C1C1E),
            offset: Offset(0, 6),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        spacing: 12,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
            child: SizedBox.square(
              dimension: 84,
              child: ColoredBox(color: c.surface, child: photo),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  price,
                  style: MusubiType.style(
                    18,
                    weight: FontWeight.w800,
                    color: c.textPrimary,
                    tabular: true,
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    13.5,
                    weight: FontWeight.w600,
                    line: 18,
                    color: c.textPrimary,
                  ),
                ),
                footer,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `Vender-listo`: "¡Tu producto ya está publicado!".
class SellDoneScreen extends StatelessWidget {
  const new({required this.published, super.key});

  final PublishedListing? published;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final published = this.published;
    final product = published?.product;
    final bottom = math.max(24, MediaQuery.viewPaddingOf(context).bottom);
    Duration ms(int value) => Duration(milliseconds: value);
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Pressable(
                  onTap: () => context.go(AppRoutes.home),
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
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      spacing: 12,
                      children: [
                        const _SealPop(child: _SuccessSeal()),
                        RiseIn(
                          offset: 12,
                          duration: ms(450),
                          delay: ms(200),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Semantics(
                              header: true,
                              child: Text(
                                '¡Tu producto ya está publicado!',
                                textAlign: TextAlign.center,
                                style: MusubiType.style(
                                  26,
                                  weight: FontWeight.w800,
                                  line: 32,
                                  em: -0.025,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        RiseIn(
                          offset: 12,
                          duration: ms(450),
                          delay: ms(280),
                          child: Text(
                            'Ya lo puede ver toda tu comunidad. Te avisaremos '
                            'cuando alguien te escriba.',
                            textAlign: TextAlign.center,
                            style: MusubiType.body.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (product != null)
                    RiseIn(
                      offset: 12,
                      duration: ms(450),
                      delay: ms(360),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        child: ListingPreviewCard(
                          photo: _cover(published!),
                          price: formatPrice(product.priceCents),
                          title: product.title,
                          footer: Row(
                            spacing: 5,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: c.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                'Publicado ahora',
                                style: MusubiType.style(
                                  12,
                                  weight: FontWeight.w700,
                                  color: c.successText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // NOTE (HU-18): "N estudiantes buscan algo similar" con las
                  // solicitudes que coinciden (Vender-listo).
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottom.toDouble()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                MusubiButton(
                  label: 'Ver mis productos',
                  kind: MusubiButtonKind.secondary,
                  onPressed: () {
                    context.go(AppRoutes.home);
                    unawaited(context.push(AppRoutes.myProducts));
                  },
                ),
                MusubiButton(
                  label: 'Volver al inicio',
                  kind: MusubiButtonKind.quiet,
                  height: MusubiSizes.buttonHeightSmall,
                  foreground: c.brandText,
                  fontSize: 14,
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cover(PublishedListing published) {
    final local = published.localCover;
    if (local != null) {
      return Image.file(
        File(local),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            ProductPhoto(url: published.product.photoUrl),
      );
    }
    return ProductPhoto(url: published.product.photoUrl);
  }
}

/// `Vender-listo__pop`: de 0.6 a 1.06 (70 %) y de vuelta a 1 en 0.55 s, cada
/// tramo con la curva de las hojas.
class _SealPop extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      builder: (context, t, child) {
        final grow = musubiEaseOut.transform((t / 0.7).clamp(0.0, 1.0));
        final settle = musubiEaseOut.transform(
          ((t - 0.7) / 0.3).clamp(0.0, 1.0),
        );
        final scale = t < 0.7 ? 0.6 + 0.46 * grow : 1.06 - 0.06 * settle;
        return Opacity(
          opacity: grow,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}

/// Circulo verde con la palomita (`Vender-listo__pop` + `__draw`).
class _SuccessSeal extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final animate = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(color: c.successSoft, shape: BoxShape.circle),
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: animate ? 0 : 1, end: 1),
              duration: const Duration(milliseconds: 800),
              // `stroke-dashoffset` de 0.45 s tras 0.35 s.
              curve: const Interval(0.4375, 1, curve: Curves.ease),
              builder: (context, t, _) => CustomPaint(
                size: const Size.square(32),
                painter: _CheckPainter(progress: t),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const new({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final path = Path()
      ..moveTo(20 * scale, 6 * scale)
      ..lineTo(9 * scale, 17 * scale)
      ..lineTo(4 * scale, 12 * scale);
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
