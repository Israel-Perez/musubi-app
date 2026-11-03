import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

/// Abre una hoja con titulo de la maqueta (`UI.sheet`): "Datos personales",
/// "Correo institucional", "Cambiar contraseña". El [builder] devuelve un
/// [MusubiPanel].
Future<T?> showMusubiPanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  barrierColor: context.musubi.scrim,
  sheetAnimationStyle: const AnimationStyle(
    duration: Duration(milliseconds: 340),
    reverseDuration: Duration(milliseconds: 220),
    curve: musubiEaseOut,
  ),
  builder: builder,
);

/// Hoja con titulo (`.sheet`): radio 28, relleno `8 0 30`, manija de 40 x 5,
/// encabezado `.sheet-h` (titulo de 19 y la X), cuerpo `.sheet-b` con
/// relleno de 22 a los lados y acciones `.sheet-a` (relleno `16 20 0`,
/// separadas por 10). [tall] es `.sheet-tall`: al menos el 62 % de la
/// pantalla.
class MusubiPanel extends StatelessWidget {
  const new({
    required this.title,
    required this.child,
    super.key,
    this.actions = const [],
    this.tall = false,
    this.onClose,
    this.bodyInset = 22,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool tall;

  /// La X; por defecto cierra la hoja.
  final VoidCallback? onClose;

  /// Relleno lateral del cuerpo: 22, o 12 con [MusubiOptions] (`.opts`
  /// lleva `margin: 0 -10px`).
  final double bodyInset;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final media = MediaQuery.of(context);
    // Con teclado, la hoja sube por encima de el.
    final keyboard = media.viewInsets.bottom;
    final bottom = math.max<double>(30, media.viewPadding.bottom) + keyboard;
    return Padding(
      padding: EdgeInsets.only(top: media.viewPadding.top),
      child: Container(
        constraints: BoxConstraints(
          minHeight: tall ? (media.size.height * 0.62) : 0,
          maxHeight: media.size.height - 60 - media.viewPadding.top,
        ),
        padding: EdgeInsets.only(top: 8, bottom: bottom),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(MusubiSizes.radiusSheet),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E1C1C1E),
              offset: Offset(0, -10),
              blurRadius: 40,
            ),
          ],
        ),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: title,
          explicitChildNodes: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: c.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 10, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: MusubiType.style(
                                  19,
                                  weight: FontWeight.w800,
                                  line: 25,
                                  em: -0.02,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          Pressable(
                            key: const Key('panel-close'),
                            onTap: onClose ?? () => Navigator.of(context).pop(),
                            semanticLabel: 'Cerrar',
                            builder: (context, _) => SizedBox.square(
                              dimension: MusubiSizes.minTouch,
                              child: Center(
                                child: MusubiIcon(
                                  MusubiIcons.x,
                                  size: 22,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          bodyInset,
                          4,
                          bodyInset,
                          0,
                        ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: actions,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opcion de una lista (`UI.options`).
@immutable
class MusubiOption<T> {
  const new({
    required this.value,
    required this.label,
    this.sub,
    this.icon,
    this.danger = false,
  });

  final T value;
  final String label;

  /// Linea pequena bajo la etiqueta (`.opt-t small`).
  final String? sub;

  /// Cuadro de 38 a la izquierda (`.opt-ico`).
  final MusubiIconData? icon;

  /// Texto e icono en rojo ("Quitar foto").
  final bool danger;
}

/// Lista de opciones de una hoja (`.opts`): filas de 56 con su marca
/// redonda (roja con palomita si esta elegida). Con [plain] no hay marca
/// (`.opt-plain`). Al tocar marca la opcion y llama [onPick] 160 ms despues,
/// como la maqueta. Va en un [MusubiPanel] con `bodyInset: 12`.
class MusubiOptions<T> extends StatefulWidget {
  const new({
    required this.options,
    required this.onPick,
    super.key,
    this.selected,
    this.plain = false,
  });

  final List<MusubiOption<T>> options;
  final T? selected;
  final bool plain;
  final ValueChanged<T> onPick;

  @override
  State<MusubiOptions<T>> createState() => _MusubiOptionsState<T>();
}

class _MusubiOptionsState<T> extends State<MusubiOptions<T>> {
  late T? _selected = widget.selected;
  Timer? _pick;

  @override
  void dispose() {
    _pick?.cancel();
    super.dispose();
  }

  void _tap(T value) {
    setState(() => _selected = value);
    _pick?.cancel();
    _pick = Timer(
      const Duration(milliseconds: 160),
      () => widget.onPick(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in widget.options)
          _row(c, option, option.value == _selected),
      ],
    );
  }

  Widget _row(MusubiColors c, MusubiOption<T> option, bool on) {
    final ink = option.danger ? c.dangerText : c.textPrimary;
    return Semantics(
      inMutuallyExclusiveGroup: !widget.plain,
      checked: widget.plain ? null : on,
      child: Pressable(
        key: ValueKey('option-${option.value}'),
        onTap: () => _tap(option.value),
        semanticLabel: option.label,
        builder: (context, pressed) => Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: pressed ? c.surface : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            spacing: 12,
            children: [
              if (option.icon != null)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: MusubiIcon(option.icon!, size: 19, color: ink),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: MusubiType.style(
                        15.5,
                        weight: on ? FontWeight.w800 : FontWeight.w600,
                        line: 21,
                        color: ink,
                      ),
                    ),
                    if (option.sub != null)
                      Text(
                        option.sub!,
                        style: MusubiType.style(
                          12.5,
                          weight: FontWeight.w600,
                          line: 17,
                          color: c.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (!widget.plain)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: on ? c.brand : null,
                    shape: BoxShape.circle,
                    border: on ? null : Border.all(color: c.border, width: 2),
                  ),
                  child: on
                      ? const Center(
                          child: MusubiIcon(
                            MusubiIcons.check,
                            size: 14,
                            strokeWidth: 3,
                            color: Color(0xFFFFFFFF),
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de datos de una hoja (`.s-card` con filas `.s-row`): "Correo",
/// "Estado", "Desde".
class PanelCard extends StatelessWidget {
  const new({required this.rows, super.key});

  /// Etiqueta gris a la izquierda y valor en negritas a la derecha.
  final List<(String, String, Color?)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        spacing: 8,
        children: [
          for (final (label, value, color) in rows)
            Row(
              spacing: 12,
              children: [
                Text(
                  label,
                  style: MusubiType.style(
                    14,
                    weight: FontWeight.w600,
                    line: 20,
                    color: c.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: MusubiType.style(
                      14,
                      weight: FontWeight.w800,
                      line: 20,
                      color: color ?? c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Nota gris bajo el contenido de una hoja (`.sheet-note`).
class PanelNote extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      text,
      style: MusubiType.style(
        13,
        line: 18,
        color: context.musubi.textSecondary,
      ),
    ),
  );
}
