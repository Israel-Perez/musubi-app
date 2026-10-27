import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

/// Pestana de la barra inferior.
@immutable
class BottomBarItem {
  const new({required this.label, required this.icon});

  final String label;
  final MusubiIconData icon;
}

/// Barra inferior de la maqueta: Inicio, Se busca, (Publicar), Mensajes,
/// Perfil. Activo: icono y texto en rojo, peso 800. "Publicar" es un boton
/// rojo de 52 con radio 18 que sobresale [overhang] px arriba de la barra.
///
/// Va con `extendBody: true`: la franja de arriba es transparente (deja ver
/// la pantalla) y solo el boton recibe toques ahi.
class MusubiBottomBar extends StatelessWidget {
  const new({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onPublish,
    super.key,
    this.publishOpen = false,
  });

  /// Lo que el boton "Publicar" sobresale arriba de la barra.
  static const overhang = 18.0;

  /// Borde de arriba: como en la maqueta (`box-sizing: border-box`), queda
  /// dentro de la barra y el contenido empieza debajo de el.
  static const _border = 1.0;

  static const tabs = [
    BottomBarItem(label: 'Inicio', icon: MusubiIcons.house),
    BottomBarItem(label: 'Se busca', icon: MusubiIcons.megaphone),
    BottomBarItem(label: 'Mensajes', icon: MusubiIcons.messageCircle),
    BottomBarItem(label: 'Perfil', icon: MusubiIcons.user),
  ];

  /// Indice de la pestana activa (0..3, sin contar "Publicar").
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onPublish;

  /// "¿Qué quieres publicar?" abierta: el boton central es "Cerrar".
  final bool publishOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    Widget tab(int index) => Expanded(
      child: _TabButton(
        item: tabs[index],
        selected: index == currentIndex,
        onTap: () => onTabSelected(index),
      ),
    );

    return SizedBox(
      height: overhang + MusubiSizes.navBarHeight + inset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: overhang,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.background,
                border: Border(top: BorderSide(color: c.border)),
              ),
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            top: overhang + _border,
            height: MusubiSizes.navBarHeight - _border,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [tab(0), tab(1), const Spacer(), tab(2), tab(3)],
            ),
          ),
          // Publicar: la quinta parte central, 18 px arriba del contenido.
          Positioned(
            top: _border,
            left: 4,
            right: 4,
            child: Row(
              children: [
                const Spacer(flex: 2),
                Expanded(
                  child: _PublishButton(open: publishOpen, onTap: onPublish),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const new({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final animate = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return Pressable(
      onTap: onTap,
      semanticLabel: open ? 'Cerrar' : 'Publicar',
      builder: (context, pressed) => Column(
        spacing: 3,
        children: [
          Container(
            width: MusubiSizes.publishButton,
            height: MusubiSizes.publishButton,
            decoration: BoxDecoration(
              color: open
                  ? c.inverse
                  : pressed
                  ? c.brandPressed
                  : c.brand,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: c.background, spreadRadius: 4),
                BoxShadow(
                  color: open
                      ? const Color(0x401C1C1E)
                      : const Color(0x4DD7191F),
                  offset: const Offset(0, 8),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Center(
              child: open
                  // `Publicar__turn`: la X entra girando desde -90 grados.
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: animate ? -0.25 : 0, end: 0),
                      duration: const Duration(milliseconds: 350),
                      curve: musubiEaseOut,
                      builder: (context, turns, child) => Transform.rotate(
                        angle: turns * 2 * math.pi,
                        child: child,
                      ),
                      child: const MusubiIcon(
                        MusubiIcons.x,
                        strokeWidth: 2.4,
                        color: Color(0xFFFFFFFF),
                      ),
                    )
                  : const MusubiIcon(
                      MusubiIcons.plus,
                      size: 26,
                      strokeWidth: 2.4,
                      color: Color(0xFFFFFFFF),
                    ),
            ),
          ),
          Text(
            open ? 'Cerrar' : 'Publicar',
            style: MusubiType.style(
              11,
              weight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const new({required this.item, required this.selected, required this.onTap});

  final BottomBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final color = selected ? c.brandText : c.textSecondary;
    return Pressable(
      onTap: onTap,
      semanticLabel: item.label,
      selected: selected,
      builder: (context, _) => SizedBox(
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3,
          children: [
            MusubiIcon(
              item.icon,
              strokeWidth: selected ? 2 : 1.8,
              color: color,
            ),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.style(
                11,
                weight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
