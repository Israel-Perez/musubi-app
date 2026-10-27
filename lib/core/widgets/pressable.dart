import 'dart:async';

import 'package:flutter/widgets.dart';

/// Area tocable de la maqueta, sin ripple: al presionar, [builder] recibe
/// `pressed` para cambiar el fondo (`.pr`, `.ps`, `.pc`) y, con [pressScale],
/// el contenido encoge un poco (`.press`, 0.97).
///
/// Para el lector de pantalla es un solo boton: con [semanticLabel] se anuncia
/// ese texto; sin el, se juntan los textos del contenido.
class Pressable extends StatefulWidget {
  const new({
    required this.builder,
    required this.onTap,
    super.key,
    this.pressScale = 1,
    this.semanticLabel,
    this.selected,
  });

  // ignore: avoid_positional_boolean_parameters, como los builders de Flutter.
  final Widget Function(BuildContext context, bool pressed) builder;

  /// `null` deshabilita el area (sin efecto al presionar).
  final VoidCallback? onTap;
  final double pressScale;
  final String? semanticLabel;
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  Timer? _release;

  @override
  void dispose() {
    _release?.cancel();
    super.dispose();
  }

  void _set(bool value) {
    _release?.cancel();
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  void _tap() {
    // Un toque rapido baja y sube en el mismo cuadro: el estado presionado
    // se sostiene un instante para que se vea, como `:active` en el celular.
    _set(true);
    _release = Timer(const Duration(milliseconds: 120), () => _set(false));
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final child = widget.builder(context, enabled && _pressed);
    final gestures = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled ? _tap : null,
      child: widget.pressScale == 1
          ? child
          : AnimatedScale(
              scale: enabled && _pressed ? widget.pressScale : 1,
              duration: const Duration(milliseconds: 150),
              curve: Curves.ease,
              child: child,
            ),
    );
    final label = widget.semanticLabel;
    final node = Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: label,
      onTap: enabled ? widget.onTap : null,
      excludeSemantics: label != null,
      child: gestures,
    );
    return label == null ? MergeSemantics(child: node) : node;
  }
}
