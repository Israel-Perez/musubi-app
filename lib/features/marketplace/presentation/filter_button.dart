import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

/// Boton de filtros con el globo de activos: Inicio (44, `Filtrar`) y
/// `Busqueda` (48, `Filtros`, fondo rojo claro con filtros) de la maqueta.
class FilterButton extends StatelessWidget {
  const new({
    required this.count,
    required this.onTap,
    required this.semanticLabel,
    super.key,
    this.size = 44,
    this.active = false,
  });

  final int count;
  final VoidCallback onTap;
  final String semanticLabel;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: pressed
                      ? c.surfacePressed
                      : active
                      ? c.brandSoft
                      : c.surface,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
                ),
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.slidersHorizontal,
                    size: 20,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.background, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: MusubiType.style(
                      10.5,
                      weight: FontWeight.w800,
                      color: const Color(0xFFFFFFFF),
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
