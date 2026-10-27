import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

/// Curva de las hojas y dialogos de la maqueta: `cubic-bezier(.2,.8,.2,1)`.
const musubiEaseOut = Cubic(0.2, 0.8, 0.2, 1);

/// Estilos de hoja inferior de la maqueta.
enum MusubiSheetStyle {
  /// "Crea tu cuenta": radio 32, relleno `8 20 26` y velo de 0.55.
  gate(MusubiSizes.radiusGate, EdgeInsets.fromLTRB(20, 8, 20, 26)),

  /// Hojas de la pantalla ("Filtrar"): radio 28, relleno `8 20 30`.
  screen(MusubiSizes.radiusSheet, EdgeInsets.fromLTRB(20, 8, 20, 30));

  new(this.radius, this.padding);

  final double radius;
  final EdgeInsets padding;
}

/// Abre una hoja inferior con la forma de la maqueta: manija de 40 x 5,
/// sombra hacia arriba y entrada de 0.4 s.
Future<T?> showMusubiSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  MusubiSheetStyle style = MusubiSheetStyle.gate,
}) {
  final c = context.musubi;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: style == MusubiSheetStyle.gate ? c.gateScrim : c.scrim,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 400),
      reverseDuration: Duration(milliseconds: 220),
      curve: musubiEaseOut,
    ),
    builder: (context) => MusubiSheet(style: style, child: builder(context)),
  );
}

/// Cuerpo de una hoja inferior (ver [showMusubiSheet]).
class MusubiSheet extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.style = MusubiSheetStyle.gate,
  });

  final MusubiSheetStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final padding = style.padding.copyWith(
      bottom: math.max(style.padding.bottom, inset),
    );
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height - 60,
      ),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(style.radius)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331C1C1E),
            offset: Offset(0, -10),
            blurRadius: 40,
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: style == MusubiSheetStyle.gate
                      ? c.border
                      : c.borderStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// X de una hoja: circulo de 34 con sombra rojiza dentro de 44 tocables.
class SheetCloseButton extends StatelessWidget {
  const new({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Cerrar',
      builder: (context, pressed) => SizedBox.square(
        dimension: MusubiSizes.minTouch,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: pressed ? c.surface : c.background,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24A50F15),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: MusubiIcon(
                MusubiIcons.x,
                size: 18,
                strokeWidth: 2.2,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
