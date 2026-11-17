import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

// Piezas de `Administracion` (HU-39 y HU-40). La maqueta no tiene estas
// pantallas: se arman con las piezas de `Notificaciones` (pestanas) y
// `Ajustes` (grupos), con los tokens de 02-04.

/// "16/11/2026" en hora local.
String adminDate(DateTime utc) {
  final d = utc.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Pastilla de estado: gris, verde, ambar o roja.
enum PillTone { neutral, success, warning, danger }

class StatusPill extends StatelessWidget {
  const new(this.label, {super.key, this.tone = PillTone.neutral});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final (background, foreground) = switch (tone) {
      PillTone.neutral => (c.surface, c.textSecondary),
      PillTone.success => (c.successSoft, c.successText),
      PillTone.warning => (c.warningSoft, c.warningText),
      PillTone.danger => (c.errorSoft, c.dangerText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: MusubiType.style(
          12,
          weight: FontWeight.w800,
          line: 16,
          color: foreground,
        ),
      ),
    );
  }
}

/// Pestana de `Administracion`, como las de `Notificaciones`.
class AdminTabChip extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      builder: (context, _) => SizedBox(
        height: MusubiSizes.minTouch,
        child: Center(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? c.inverse : null,
              borderRadius: BorderRadius.circular(999),
              border: selected ? null : Border.all(color: c.border, width: 1.5),
            ),
            child: Center(
              child: Text(
                label,
                style: MusubiType.style(
                  13.5,
                  weight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? c.onBrand : c.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta gris con borde, como las de `Ajustes`.
class AdminCard extends StatelessWidget {
  const new({required this.child, super.key, this.onTap, this.semanticLabel});

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget box({required bool pressed}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pressed ? c.surfacePressed : c.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1.5),
      ),
      child: child,
    );
    final tap = onTap;
    if (tap == null) return box(pressed: false);
    return Pressable(
      onTap: tap,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => box(pressed: pressed),
    );
  }
}

/// Linea con icono: "Publicación · Calculadora Casio".
class AdminLine extends StatelessWidget {
  const new(this.icon, this.text, {super.key, this.strong = false});

  final MusubiIconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Row(
      spacing: 8,
      children: [
        MusubiIcon(icon, size: 16, color: c.textSecondary),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MusubiType.style(
              13.5,
              weight: strong ? FontWeight.w800 : FontWeight.w600,
              line: 19,
              color: strong ? c.textPrimary : c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
