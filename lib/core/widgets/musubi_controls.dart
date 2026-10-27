import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/shake.dart';

/// Casilla de la maqueta (`Registro`): cuadro de 22 con radio 7 dentro de 44
/// tocables. Marcada: roja con la palomita blanca; sin marcar: aro gris de 2.
class MusubiCheckbox extends StatelessWidget {
  const new({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
    this.shakeTrigger,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  /// Cambia para sacudir la casilla ("Acepta los términos para continuar").
  final Object? shakeTrigger;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Semantics(
      checked: value,
      child: Pressable(
        onTap: () => onChanged(!value),
        semanticLabel: semanticLabel,
        builder: (context, _) => SizedBox.square(
          dimension: 44,
          child: Center(
            child: Shake(
              trigger: shakeTrigger,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: value ? c.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: value
                      ? null
                      : Border.all(color: c.neutralStrong, width: 2),
                ),
                child: value
                    ? const Center(
                        child: MusubiIcon(
                          MusubiIcons.check,
                          size: 15,
                          strokeWidth: 3,
                          color: Color(0xFFFFFFFF),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interruptor de la maqueta: pista roja (encendido) o gris (apagado) con su
/// perilla blanca. `Ajustes` usa 51 x 31 (perilla de 27); "Filtrar", 50 x 30
/// (perilla de 24).
class MusubiSwitch extends StatelessWidget {
  const new({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
    this.width = 51,
    this.height = 31,
    this.knob = 27,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;
  final double width;
  final double height;
  final double knob;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Semantics(
      toggled: value,
      child: Pressable(
        onTap: () => onChanged(!value),
        semanticLabel: semanticLabel,
        builder: (context, _) => SizedBox(
          width: width + 14,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width,
              height: height,
              padding: EdgeInsets.all((height - knob) / 2),
              decoration: BoxDecoration(
                color: value ? c.brand : c.borderStrong,
                borderRadius: BorderRadius.circular(height / 2),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.ease,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: knob,
                  height: knob,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x401C1C1E),
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
