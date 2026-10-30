import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

/// Fila de `Ajustes` y `Privacidad`: icono en su cuadro de 36, titulo, valor
/// y flecha.
class SettingsRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    this.value,
    this.valueColor,
    this.onTap,
    super.key,
  });

  final MusubiIconData icon;
  final String title;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget row({bool pressed = false}) => Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: pressed ? c.surface : null,
      child: Row(
        spacing: MusubiSizes.space3,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: MusubiIcon(
                icon,
                size: 19,
                strokeWidth: 1.9,
                color: c.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: MusubiType.style(
                15,
                weight: FontWeight.w700,
                line: 20,
                color: c.textPrimary,
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: MusubiType.style(
                13.5,
                weight: FontWeight.w700,
                color: valueColor ?? c.textSecondary,
              ),
            ),
          if (onTap != null)
            MusubiIcon(
              MusubiIcons.chevronRight,
              size: 18,
              color: c.textSecondary,
            ),
        ],
      ),
    );
    return onTap == null
        ? Semantics(
            label: value == null ? title : '$title: $value',
            excludeSemantics: true,
            child: row(),
          )
        : Pressable(
            onTap: onTap,
            semanticLabel: title,
            builder: (context, pressed) => row(pressed: pressed),
          );
  }
}
