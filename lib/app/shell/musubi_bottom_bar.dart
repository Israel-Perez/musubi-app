import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';

/// Pestana de la barra inferior.
@immutable
class BottomBarItem {
  const new({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Barra inferior de la maqueta: Inicio, Se busca, (Publicar), Mensajes,
/// Perfil. Activo: icono y texto en rojo, peso 800. "Publicar" es un boton
/// central de 52 dp que abre las opciones de publicar (no es una pestana).
class MusubiBottomBar extends StatelessWidget {
  const new({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onPublish,
    super.key,
  });

  static const tabs = [
    BottomBarItem(
      label: 'Inicio',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    BottomBarItem(
      label: 'Se busca',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign,
    ),
    BottomBarItem(
      label: 'Mensajes',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
    ),
    BottomBarItem(
      label: 'Perfil',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  /// Indice de la pestana activa (0..3, sin contar "Publicar").
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget tab(int index) => Expanded(
      child: _TabButton(
        item: tabs[index],
        selected: index == currentIndex,
        onTap: () => onTabSelected(index),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MusubiSizes.navBarHeight,
          child: Row(
            children: [
              tab(0),
              tab(1),
              Expanded(
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Publicar',
                    child: SizedBox.square(
                      dimension: MusubiSizes.publishButton,
                      child: FloatingActionButton(
                        heroTag: null,
                        elevation: 0,
                        tooltip: 'Publicar',
                        backgroundColor: c.brand,
                        foregroundColor: c.onBrand,
                        shape: const CircleBorder(),
                        onPressed: onPublish,
                        child: const Icon(Icons.add, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
              tab(2),
              tab(3),
            ],
          ),
        ),
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
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.label.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
