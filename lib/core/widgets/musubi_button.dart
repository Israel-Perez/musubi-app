import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

/// Tipos de boton de la maqueta.
enum MusubiButtonKind {
  /// Rojo (`.pr`): la accion principal de la vista.
  primary,

  /// Fondo de la pantalla con borde de 1.5 (`.ps`): "Ya tengo cuenta".
  secondary,

  /// Sin fondo, texto gris (`.ab-quiet`): "Seguir explorando", "Cancelar".
  quiet,

  /// Enlace rojo: "¿Olvidaste tu contraseña?", "Crea tu cuenta".
  link,
}

/// Boton de la maqueta: 56 de alto en acciones de pantalla (radio 16), 54 en
/// hojas y 44 en tarjetas (radio 12). Sin ripple: al presionar cambia el
/// fondo. Con [loading] gira el arco y muestra [loadingLabel] ("Entrando…"),
/// y no acepta otro toque (evita envios dobles).
class MusubiButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.kind = MusubiButtonKind.primary,
    this.height = MusubiSizes.buttonHeight,
    this.icon,
    this.iconSize = 18,
    this.iconStrokeWidth = 2,
    this.trailingIcon,
    this.loading = false,
    this.loadingLabel,
    this.expand = true,
    this.foreground,
    this.fontSize,
    this.gap,
    this.dimmed = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final MusubiButtonKind kind;
  final double height;
  final MusubiIconData? icon;
  final double iconSize;
  final double iconStrokeWidth;

  /// Icono despues del texto ("Ver todo ›", "Empezar a explorar →").
  final MusubiIconData? trailingIcon;
  final bool loading;
  final String? loadingLabel;
  final bool expand;

  /// Color del texto y del icono en lugar del de [kind] ("Abrir mi correo").
  final Color? foreground;

  /// Tamano del texto en lugar del que sale de [kind] y [height].
  final double? fontSize;

  /// Espacio entre icono y texto en lugar del de [kind] (8; 4 en enlaces):
  /// "Abrir mi correo" lleva 6.
  final double? gap;

  /// Se ve deshabilitado (`aria-disabled` de la maqueta) pero responde al
  /// toque para explicar que falta: "Crear cuenta" con un correo que no es
  /// de la universidad (`Registro-error`).
  final bool dimmed;

  double get _fontSize =>
      fontSize ??
      switch (kind) {
        MusubiButtonKind.link => 14,
        MusubiButtonKind.quiet => height >= 46 ? 16 : 15,
        _ => height >= MusubiSizes.buttonHeightSheet ? 16 : 14,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final enabled = onPressed != null && !loading;
    final disabled = (onPressed == null || dimmed) && !loading;
    final radius = BorderRadius.circular(
      height >= MusubiSizes.buttonHeightSheet ? MusubiSizes.radiusButton : 12,
    );

    return Pressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: loading ? '$label, cargando' : label,
      builder: (context, pressed) {
        final (background, kindInk) = switch (kind) {
          _ when disabled && kind == MusubiButtonKind.primary => (
            c.border,
            c.disabledText,
          ),
          _ when disabled => (null, c.disabledText),
          MusubiButtonKind.primary => (
            pressed ? c.brandPressed : c.brand,
            c.onBrand,
          ),
          MusubiButtonKind.secondary => (
            pressed ? c.surface : c.background,
            c.textPrimary,
          ),
          MusubiButtonKind.quiet => (
            pressed ? c.surface : null,
            c.textSecondary,
          ),
          MusubiButtonKind.link => (
            null,
            pressed ? c.brandStrongText : c.brandText,
          ),
        };
        final ink = disabled ? kindInk : foreground ?? kindInk;
        final text = MusubiType.style(
          _fontSize,
          weight: FontWeight.w700,
          color: ink,
        );
        final children = <Widget>[
          if (loading)
            MusubiSpinner(color: ink)
          else if (icon != null)
            MusubiIcon(
              icon!,
              size: iconSize,
              strokeWidth: iconStrokeWidth,
              color: ink,
            ),
          Flexible(
            child: Text(
              loading ? loadingLabel ?? label : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text,
            ),
          ),
          if (trailingIcon != null && !loading)
            MusubiIcon(
              trailingIcon!,
              size: iconSize,
              strokeWidth: iconStrokeWidth,
              color: ink,
            ),
        ];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: kind == MusubiButtonKind.link ? MusubiSizes.minTouch : height,
          width: expand && kind != MusubiButtonKind.link
              ? double.infinity
              : null,
          padding: EdgeInsets.symmetric(
            horizontal: kind == MusubiButtonKind.link ? 0 : 16,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: kind == MusubiButtonKind.secondary
                ? Border.all(color: c.border, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisSize: expand && kind != MusubiButtonKind.link
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: loading
                ? 10
                : gap ?? (kind == MusubiButtonKind.link ? 4 : 8),
            children: children,
          ),
        );
      },
    );
  }
}

/// Arco que gira (0.8 s por vuelta) mientras algo carga.
class MusubiSpinner extends StatefulWidget {
  const new({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  State<MusubiSpinner> createState() => _MusubiSpinnerState();
}

class _MusubiSpinnerState extends State<MusubiSpinner>
    with SingleTickerProviderStateMixin {
  late final _turns = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat();

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _turns,
    child: MusubiIcon(
      MusubiIcons.spinner,
      size: widget.size,
      strokeWidth: 2.4,
      color: widget.color,
    ),
  );
}
