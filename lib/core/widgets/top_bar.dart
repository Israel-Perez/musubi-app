import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

/// Barra superior de las pantallas de la maqueta: 44 de alto bajo la barra
/// de estado y flecha "Regresar" (chevron de 24) a la izquierda. A la derecha
/// puede ir algo ("PASO 2 DE 2"); con [title], el titulo va al centro de 17
/// (`Ajustes`).
class MusubiTopBar extends StatelessWidget {
  const new({super.key, this.onBack, this.title, this.trailing});

  /// `null` deja el espacio sin flecha (`Verificacion-lista`).
  final VoidCallback? onBack;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final onBack = this.onBack;
    final back = onBack == null
        ? const SizedBox(width: MusubiSizes.minTouch)
        : Pressable(
            onTap: onBack,
            semanticLabel: 'Regresar',
            builder: (context, _) => SizedBox.square(
              dimension: MusubiSizes.minTouch,
              child: Center(
                child: MusubiIcon(
                  MusubiIcons.chevronLeft,
                  strokeWidth: 1.9,
                  color: c.textPrimary,
                ),
              ),
            ),
          );
    final title = this.title;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 8,
          right: title == null && trailing != null ? 20 : 8,
        ),
        child: SizedBox(
          height: MusubiSizes.minTouch,
          child: Row(
            children: [
              back,
              if (title != null) ...[
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: MusubiType.style(
                        17,
                        weight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MusubiSizes.minTouch),
              ] else ...[
                const Spacer(),
                ?trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado de una pestana (`Mensajes`, `Perfil`): titulo de 28 a la
/// izquierda y una accion de 44 a la derecha.
class TabHeader extends StatelessWidget {
  const new({required this.title, super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.only(left: 20, right: 10),
      child: SizedBox(
        height: MusubiSizes.minTouch,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: MusubiType.style(
                    28,
                    weight: FontWeight.w800,
                    line: 34,
                    em: -0.03,
                    color: context.musubi.textPrimary,
                  ),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    ),
  );
}

/// "PASO 1 DE 2" en rojo, 12 y peso 800 con espaciado de 0.08 em.
class Eyebrow extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: MusubiType.eyebrow.copyWith(color: context.musubi.brandText),
  );
}
