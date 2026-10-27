import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';

/// Circulo con iniciales y los colores pastel de la maqueta. [palette] elige
/// la pareja de colores (0..4) de `MusubiColors.avatars`.
class InitialsAvatar extends StatelessWidget {
  const new({
    required this.initials,
    required this.size,
    super.key,
    this.palette = 4,
    this.fontSize,
    this.borderColor,
    this.borderWidth = 0,
  });

  final String initials;
  final double size;
  final int palette;
  final double? fontSize;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final avatars = context.musubi.avatars;
    final (background, ink) = avatars[palette % avatars.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: MusubiType.style(
          fontSize ?? size * 0.33,
          weight: FontWeight.w800,
          color: ink,
        ),
      ),
    );
  }
}

/// Las cuatro personas de muestra de la maqueta (iniciales ficticias de la
/// comunidad), encimadas. Con [plus] se agrega el circulo rojo con "+".
class CommunityAvatars extends StatelessWidget {
  const new({
    required this.size,
    required this.overlap,
    required this.borderColor,
    required this.borderWidth,
    required this.fontSize,
    super.key,
    this.plus = false,
  });

  static const people = ['VC', 'PN', 'JS', 'DH'];

  final double size;
  final double overlap;
  final Color borderColor;
  final double borderWidth;
  final double fontSize;
  final bool plus;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final count = people.length + (plus ? 1 : 0);
    return ExcludeSemantics(
      child: SizedBox(
        width: size + (count - 1) * (size - overlap),
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < people.length; i++)
              Positioned(
                left: i * (size - overlap),
                child: InitialsAvatar(
                  initials: people[i],
                  size: size,
                  palette: i,
                  fontSize: fontSize,
                  borderColor: borderColor,
                  borderWidth: borderWidth,
                ),
              ),
            if (plus)
              Positioned(
                left: people.length * (size - overlap),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: c.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                  alignment: Alignment.center,
                  child: const MusubiIcon(
                    MusubiIcons.plus,
                    size: 18,
                    strokeWidth: 2.6,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Insignia de "verificado": la estrella redondeada roja con la palomita
/// blanca (`badge-check` relleno de la maqueta).
class VerifiedBadge extends StatelessWidget {
  const new({required this.size, super.key, this.checkWidth = 2.4});

  final double size;
  final double checkWidth;

  @override
  Widget build(BuildContext context) => MusubiIcon(
    MusubiIcons.badgeCheck,
    size: size,
    strokeWidth: checkWidth,
    color: const Color(0xFFFFFFFF),
    fillColor: context.musubi.brand,
  );
}
