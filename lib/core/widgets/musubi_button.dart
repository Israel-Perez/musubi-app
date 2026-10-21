import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';

enum MusubiButtonKind { primary, secondary, text }

/// Boton de la guia de estilo: 56 dp en acciones de pantalla, un solo
/// primario por vista. Con [loading] se deshabilita y muestra un indicador
/// (evita envios dobles).
class MusubiButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.kind = MusubiButtonKind.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final MusubiButtonKind kind;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final action = loading ? null : onPressed;
    final child = loading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Text(label);
    final iconWidget = icon == null || loading ? null : Icon(icon, size: 22);

    final button = switch (kind) {
      MusubiButtonKind.primary =>
        iconWidget == null
            ? FilledButton(onPressed: action, child: child)
            : FilledButton.icon(
                onPressed: action,
                icon: iconWidget,
                label: child,
              ),
      MusubiButtonKind.secondary =>
        iconWidget == null
            ? OutlinedButton(onPressed: action, child: child)
            : OutlinedButton.icon(
                onPressed: action,
                icon: iconWidget,
                label: child,
              ),
      MusubiButtonKind.text => TextButton(onPressed: action, child: child),
    };

    return Semantics(
      button: true,
      enabled: action != null,
      label: loading ? '$label, cargando' : null,
      excludeSemantics: loading,
      child: expand && kind != MusubiButtonKind.text
          ? SizedBox(
              width: double.infinity,
              height: MusubiSizes.buttonHeight,
              child: button,
            )
          : button,
    );
  }
}
