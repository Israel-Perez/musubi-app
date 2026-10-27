import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/css_dashes.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';

/// Ilustraciones de la hoja "Crea tu cuenta" (maqueta `Inicio-visitante`,
/// un panel rojo claro de 168 de alto por motivo). Las piezas aparecen con
/// `__pop` (desde 0.6) en el orden de la maqueta.

const _white = Color(0xFFFFFFFF);
const _photos = 'assets/products';

/// Sombra rojiza de las tarjetas de la ilustracion.
List<BoxShadow> _shadow(double y, double blur, double alpha) => [
  BoxShadow(
    color: const Color(0xFFA50F15).withValues(alpha: alpha),
    offset: Offset(0, y),
    blurRadius: blur,
  ),
];

/// Panel de 168 con radio 24 donde se acomodan las piezas.
class GateArtPanel extends StatelessWidget {
  const new({required this.builder, super.key});

  /// Recibe el ancho del panel (las piezas se centran como en la maqueta).
  final List<Widget> Function(double width) builder;

  // Es una imagen: el texto no crece con la letra del sistema.
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: MediaQuery.withNoTextScaling(child: _panel(context)),
  );

  Widget _panel(BuildContext context) => Container(
    height: 168,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.musubi.brandSoft,
      borderRadius: BorderRadius.circular(24),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.none,
        children: builder(constraints.maxWidth),
      ),
    ),
  );
}

/// `__pop`: aparece desde 0.6 con la curva de la maqueta, tras [delay].
class PopIn extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final total = delay + duration;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: musubiEaseOut,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: child,
    );
  }
}

Duration _ms(int value) => Duration(milliseconds: value);

/// Circulo rojo con icono blanco y un aro del color del panel.
class _Badge extends StatelessWidget {
  const new({
    required this.size,
    required this.icon,
    this.iconSize = 24,
    this.ring = 5,
    this.filled = false,
  });

  final double size;
  final MusubiIconData icon;
  final double iconSize;
  final double ring;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.brand,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c.brandSoft, spreadRadius: ring)],
      ),
      child: Center(
        child: MusubiIcon(icon, size: iconSize, color: _white, filled: filled),
      ),
    );
  }
}

/// Tarjeta blanca de la ilustracion.
class _Card extends StatelessWidget {
  const new({
    required this.child,
    required this.padding,
    required this.radius,
    required this.shadow,
    this.width,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final List<BoxShadow> shadow;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: padding,
    decoration: BoxDecoration(
      color: context.musubi.background,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow,
    ),
    child: child,
  );
}

Widget _rotated(double degrees, Widget child) =>
    Transform.rotate(angle: degrees * math.pi / 180, child: child);

Widget _photo(String name, double width, double height, double radius) =>
    ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        '$_photos/$name.webp',
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );

TextStyle _text(
  double size,
  FontWeight weight,
  Color color, {
  double? line,
  double em = 0,
}) => MusubiType.style(size, weight: weight, line: line, em: em, color: color);

/// Comprar: la calculadora con su precio y la bolsa.
class BuyArt extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return GateArtPanel(
      builder: (w) => [
        Positioned(
          left: w / 2 - 74,
          top: 18,
          child: PopIn(
            delay: _ms(100),
            duration: _ms(450),
            child: _rotated(
              -4,
              _Card(
                width: 148,
                padding: const EdgeInsets.all(7),
                radius: 20,
                shadow: _shadow(14, 30, 0.18),
                child: Column(
                  spacing: 6,
                  children: [
                    _photo('casio', 134, 94, 14),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r'$450',
                            style: _text(
                              16,
                              FontWeight.w800,
                              c.textPrimary,
                              line: 20,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'Casio fx-991ES',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _text(
                                10.5,
                                FontWeight.w700,
                                c.textSecondary,
                                line: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: w / 2 + 46,
          top: 12,
          child: PopIn(
            delay: _ms(350),
            child: const _Badge(size: 50, icon: MusubiIcons.shoppingBag),
          ),
        ),
      ],
    );
  }
}

/// Chatear: dos globos y "escribiendo".
class ChatArt extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final bubble = _text(13.5, FontWeight.w600, c.textPrimary, line: 18);
    return GateArtPanel(
      builder: (w) => [
        Positioned(
          left: 22,
          top: 22,
          child: PopIn(
            delay: _ms(100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [
                const InitialsAvatar(
                  initials: 'VC',
                  size: 32,
                  palette: 0,
                  fontSize: 11,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(5),
                    ),
                    boxShadow: _shadow(4, 12, 0.08),
                  ),
                  child: Text('¿Sigue disponible?', style: bubble),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 22,
          top: 70,
          child: PopIn(
            delay: _ms(400),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: c.brand,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: Text(
                '¡Sí! ¿Hoy en la biblioteca?',
                style: bubble.copyWith(color: _white),
              ),
            ),
          ),
        ),
        Positioned(
          left: 62,
          top: 118,
          child: PopIn(
            delay: _ms(700),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(5),
                ),
              ),
              child: Row(
                spacing: 4,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: c.neutralStrong,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Guardar: tres fotos en abanico y el corazon.
class SaveArt extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    // `<img>` con borde de 5 (caja de contenido): mide 10 mas por lado.
    Widget framed(String name, double w, double h, double radius, double y) =>
        Container(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: _shadow(y, y == 14 ? 28 : 24, y == 14 ? 0.2 : 0.16),
          ),
          padding: const EdgeInsets.all(5),
          child: _photo(name, w, h, radius - 5),
        );
    return GateArtPanel(
      builder: (w) => [
        Positioned(
          left: w / 2 - 150,
          top: 30,
          child: PopIn(
            delay: _ms(100),
            child: _rotated(-9, framed('calculo', 90, 100, 18, 10)),
          ),
        ),
        Positioned(
          left: w / 2 + 40,
          top: 40,
          child: PopIn(
            delay: _ms(200),
            child: _rotated(9, framed('set-dibujo', 90, 100, 18, 10)),
          ),
        ),
        Positioned(
          left: w / 2 - 57,
          top: 16,
          child: PopIn(
            delay: _ms(300),
            child: framed('laptop', 104, 116, 20, 14),
          ),
        ),
        Positioned(
          left: w / 2 - 26,
          top: 106,
          child: PopIn(
            delay: _ms(550),
            child: const _Badge(
              size: 52,
              icon: MusubiIcons.heart,
              filled: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Yo tengo": el boleto "Se busca" y la mano.
class OfferArt extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return GateArtPanel(
      builder: (w) => [
        Positioned(
          left: w / 2 - 118,
          top: 24,
          child: PopIn(
            delay: _ms(100),
            duration: _ms(450),
            child: _rotated(
              -3,
              _Card(
                width: 236,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                radius: 18,
                shadow: _shadow(14, 30, 0.16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.brand,
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusChip,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          const MusubiIcon(
                            MusubiIcons.megaphone,
                            size: 11,
                            strokeWidth: 2.6,
                            color: _white,
                          ),
                          Text(
                            'SE BUSCA',
                            style: _text(
                              10,
                              FontWeight.w800,
                              _white,
                              line: 14,
                              em: 0.06,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Bata de laboratorio talla M',
                      style: _text(
                        15,
                        FontWeight.w800,
                        c.textPrimary,
                        line: 19,
                      ),
                    ),
                    _DashedLine(color: c.ticketLine, bleed: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            'PAGA HASTA',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(
                              10,
                              FontWeight.w700,
                              c.textSecondary,
                              em: 0.05,
                            ),
                          ),
                        ),
                        Text(
                          r'$300',
                          style: _text(
                            22,
                            FontWeight.w800,
                            c.brandStrongText,
                            line: 26,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: w / 2 + 70,
          top: 8,
          child: PopIn(
            delay: _ms(350),
            child: const _Badge(size: 52, icon: MusubiIcons.hand),
          ),
        ),
      ],
    );
  }
}

/// Pedir: el megafono y tres ofertas.
class RequestArt extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget offer(String price) => Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
        boxShadow: _shadow(6, 16, 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          ClipOval(
            child: Image.asset(
              '$_photos/bata.webp',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
          Text(
            price,
            style: _text(14, FontWeight.w800, c.textPrimary, line: 18),
          ),
          Text(
            'Oferta',
            style: _text(11, FontWeight.w700, c.textSecondary, line: 14),
          ),
        ],
      ),
    );
    return GateArtPanel(
      builder: (w) => [
        Positioned(
          left: 30,
          top: 46,
          child: PopIn(
            delay: _ms(100),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: c.brand,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.brand.withValues(alpha: 0.12),
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: MusubiIcon(
                  MusubiIcons.megaphone,
                  size: 34,
                  strokeWidth: 1.9,
                  color: _white,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 134,
          top: 22,
          child: PopIn(delay: _ms(350), child: offer(r'$250')),
        ),
        Positioned(
          left: 162,
          top: 66,
          child: PopIn(delay: _ms(500), child: offer(r'$280')),
        ),
        Positioned(
          left: 144,
          top: 110,
          child: PopIn(delay: _ms(650), child: offer(r'$300')),
        ),
      ],
    );
  }
}

/// Vender: el set publicado y la camara.
class PublishArt extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return GateArtPanel(
      builder: (w) => [
        Positioned(
          left: w / 2 - 72,
          top: 16,
          child: PopIn(
            delay: _ms(100),
            duration: _ms(450),
            child: _rotated(
              3,
              _Card(
                width: 160,
                padding: const EdgeInsets.all(7),
                radius: 20,
                shadow: _shadow(14, 30, 0.18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 7,
                  children: [
                    _photo('set-dibujo', 146, 94, 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.successSoft,
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusChip,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 5,
                        children: [
                          MusubiIcon(
                            MusubiIcons.check,
                            size: 12,
                            strokeWidth: 3,
                            color: c.successText,
                          ),
                          Text(
                            'Publicado',
                            style: _text(
                              11.5,
                              FontWeight.w800,
                              c.successText,
                              line: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: w / 2 - 112,
          top: 24,
          child: PopIn(
            delay: _ms(350),
            child: const _Badge(size: 52, icon: MusubiIcons.camera),
          ),
        ),
      ],
    );
  }
}

/// Mensajes: la lista de chats con su globo rojo.
class MessagesArt extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget row(
      String initials,
      int palette,
      String name,
      double bar, {
      bool dot = false,
    }) => SizedBox(
      height: 48,
      child: Row(
        spacing: 10,
        children: [
          InitialsAvatar(
            initials: initials,
            size: 34,
            palette: palette,
            fontSize: 11.5,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                Text(
                  name,
                  style: _text(13, FontWeight.w800, c.textPrimary, line: 16),
                ),
                FractionallySizedBox(
                  widthFactor: bar,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: c.surfacePressed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (dot)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
            ),
        ],
      ),
    );
    return GateArtPanel(
      builder: (w) => [
        Positioned(
          left: 24,
          right: 24,
          top: 50,
          child: PopIn(
            delay: _ms(100),
            duration: _ms(450),
            child: _Card(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              radius: 20,
              shadow: _shadow(12, 28, 0.12),
              child: Column(
                children: [
                  row('VC', 0, 'Valeria C.', 0.78, dot: true),
                  Container(height: 1, color: c.divider),
                  row('DH', 3, 'Diego H.', 0.56),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          top: 10,
          child: PopIn(
            delay: _ms(350),
            child: const _Badge(
              size: 40,
              icon: MusubiIcons.messageCircle,
              iconSize: 20,
              ring: 4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Perfil: avatar verificado, cinco estrellas y "Estudiante verificado".
class ProfileArt extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return GateArtPanel(
      builder: (w) => [
        Positioned(
          left: w / 2 - 110,
          top: 16,
          child: PopIn(
            delay: _ms(100),
            duration: _ms(450),
            child: _Card(
              width: 220,
              padding: const EdgeInsets.all(14),
              radius: 22,
              shadow: _shadow(14, 30, 0.14),
              child: Column(
                spacing: 8,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.brandSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: MusubiIcon(
                            MusubiIcons.user,
                            size: 26,
                            color: c.brandText,
                          ),
                        ),
                      ),
                      const Positioned(
                        right: -4,
                        bottom: -2,
                        child: _OutlinedBadge(size: 20),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 2,
                    children: [
                      for (var i = 0; i < 5; i++)
                        MusubiIcon(
                          MusubiIcons.star,
                          size: 15,
                          fillColor: c.warning,
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.brandSoft,
                      borderRadius: BorderRadius.circular(
                        MusubiSizes.radiusChip,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 5,
                      children: [
                        MusubiIcon(
                          MusubiIcons.shieldCheck,
                          size: 12,
                          strokeWidth: 2.4,
                          color: c.brandStrongText,
                        ),
                        Flexible(
                          child: Text(
                            'Estudiante verificado',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(
                              11.5,
                              FontWeight.w800,
                              c.brandStrongText,
                              line: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Campus: la tarjeta de la UTTT y el correo que la fija.
class CampusArt extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return GateArtPanel(
      builder: (w) => [
        Positioned(
          left: w / 2 - 120,
          top: 20,
          child: PopIn(
            delay: _ms(100),
            duration: _ms(450),
            child: _Card(
              width: 240,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              radius: 20,
              shadow: _shadow(14, 30, 0.14),
              child: Row(
                spacing: 12,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.brand,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: MusubiIcon(
                        MusubiIcons.graduationCap,
                        color: _white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 1,
                      children: [
                        Text(
                          'UTTT',
                          style: _text(
                            20,
                            FontWeight.w800,
                            c.textPrimary,
                            line: 24,
                            em: -0.01,
                          ),
                        ),
                        Text(
                          'Tula-Tepeji, Hidalgo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(
                            11.5,
                            FontWeight.w700,
                            c.textSecondary,
                            line: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 108,
          child: PopIn(
            delay: _ms(350),
            duration: _ms(450),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Flexible(
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: c.background,
                      borderRadius: BorderRadius.circular(
                        MusubiSizes.radiusChip,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        MusubiIcon(
                          MusubiIcons.mail,
                          size: 15,
                          color: c.textSecondary,
                        ),
                        Flexible(
                          child: Text.rich(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            TextSpan(
                              style: _text(13, FontWeight.w700, c.textPrimary),
                              children: [
                                const TextSpan(text: 'tu.nombre'),
                                TextSpan(
                                  text: '@uttt',
                                  style: TextStyle(
                                    color: c.brandText,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const TextSpan(text: '.edu.mx'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                MusubiIcon(
                  MusubiIcons.arrowRight,
                  size: 16,
                  strokeWidth: 2.4,
                  color: c.brandStrongText,
                ),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                  ),
                  child: Text(
                    'UTTT',
                    style: _text(13, FontWeight.w800, _white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Insignia de verificado con contorno blanco (avatar de la ilustracion).
class _OutlinedBadge extends StatelessWidget {
  const new({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: MusubiIconPainter(
        icon: const MusubiIconData([
          IconPath(
            'M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 '
            '4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 '
            '0 1-4.78-4.77 4 4 0 0 1 0-6.76Z',
          ),
        ]),
        color: _white,
        fillColor: context.musubi.brand,
        strokeWidth: 1.5,
        filled: true,
      ),
      foregroundPainter: const MusubiIconPainter(
        icon: MusubiIconData([IconPath('m8.5 12 2.5 2.5 4.5-5')]),
        color: _white,
        fillColor: _white,
        strokeWidth: 2.4,
      ),
    ),
  );
}

/// Linea punteada sin muescas que cruza la tarjeta de lado a lado.
class _DashedLine extends StatelessWidget {
  const new({required this.color, required this.bleed});

  final Color color;
  final double bleed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 1.5,
    child: CustomPaint(
      painter: _DashPainter(color: color, bleed: bleed),
    ),
  );
}

class _DashPainter extends CustomPainter {
  const new({required this.color, required this.bleed});

  final Color color;
  final double bleed;

  @override
  void paint(Canvas canvas, Size size) {
    paintCssDashedLine(
      canvas,
      left: -bleed,
      right: size.width + bleed,
      top: 0,
      color: color,
    );
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bleed != bleed;
}
