import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';

// Piezas de `Necesidad-1…3`, `Necesidad-publicada` y `Mis-solicitudes`
// (HU-13), con las medidas de la maqueta.

/// "Así funciona" (`Necesidad-1`): tarjeta rosa con los tres pasos.
class NeedHowItWorks extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget step(MusubiIconData icon, String text) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: MusubiIcon(icon, size: 17, color: c.brand)),
          ),
          Text(
            text,
            style: MusubiType.style(
              12,
              weight: FontWeight.w700,
              line: 16,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(
            'ASÍ FUNCIONA',
            style: MusubiType.style(
              11.5,
              weight: FontWeight.w800,
              em: 0.08,
              color: c.brandStrongText,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              step(MusubiIcons.megaphone, '1. Publicas lo que buscas'),
              step(MusubiIcons.bell, '2. Avisamos a quien pueda tenerlo'),
              step(MusubiIcons.hand, '3. Te responden “Yo tengo”'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Etiqueta de un campo (13, peso 700).
class NeedLabel extends StatelessWidget {
  const new(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: 6,
      children: [
        Flexible(
          child: Text(
            text,
            style: MusubiType.style(
              13,
              weight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Chip de una opcion (categoria, fecha): 38 de alto en un toque de 44. El
/// elegido va en rosa con palomita.
class NeedChip extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Icono cuando no esta elegido ("Elegir fecha").
  final MusubiIconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final leading = selected ? MusubiIcons.check : icon;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        builder: (context, pressed) => SizedBox(
          height: MusubiSizes.minTouch,
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 38,
              padding: EdgeInsets.only(
                left: leading == null ? 14 : 12,
                right: 14,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? c.brandSoft
                    : pressed
                    ? c.surface
                    : null,
                borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                border: Border.all(
                  color: selected ? c.brandSoftBorder : c.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  if (leading != null)
                    MusubiIcon(
                      leading,
                      size: 15,
                      strokeWidth: selected ? 2.6 : 2,
                      color: selected ? c.brandStrongText : c.textPrimary,
                    ),
                  Text(
                    label,
                    style: MusubiType.style(
                      14,
                      weight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? c.brandStrongText : c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Una caracteristica deseada con su "Quitar" (`Necesidad-2`).
class NeedFeatureChip extends StatelessWidget {
  const new({required this.text, required this.onRemove, super.key});

  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      height: MusubiSizes.minTouch,
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.style(
                14,
                weight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          Pressable(
            onTap: onRemove,
            semanticLabel: 'Quitar $text',
            builder: (context, _) => SizedBox.square(
              dimension: MusubiSizes.minTouch,
              child: Center(
                child: MusubiIcon(
                  MusubiIcons.x,
                  size: 15,
                  strokeWidth: 2.4,
                  color: c.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso verde (`Necesidad-1`: "Ya hay 3 publicaciones parecidas…").
class NeedNotice extends StatelessWidget {
  const new({required this.text, super.key, this.icon = MusubiIcons.target});

  final String text;
  final MusubiIconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.successSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 8,
        children: [
          MusubiIcon(icon, size: 17, color: c.successText),
          Expanded(
            child: Text(
              text,
              style: MusubiType.style(
                13,
                weight: FontWeight.w600,
                color: c.successText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Cantidad" con quitar y agregar uno (`Necesidad-3`).
class NeedQuantityRow extends StatelessWidget {
  const new({
    required this.quantity,
    required this.max,
    required this.onStep,
    super.key,
  });

  final int quantity;
  final int max;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget button(MusubiIconData icon, String label, int delta) {
      final enabled = delta < 0 ? quantity > 1 : quantity < max;
      return Pressable(
        key: Key('need-quantity-$delta'),
        onTap: enabled ? () => onStep(delta) : null,
        semanticLabel: label,
        builder: (context, _) => SizedBox.square(
          dimension: MusubiSizes.minTouch,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: enabled ? c.inverse : c.surface,
                borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
              ),
              child: Center(
                child: MusubiIcon(
                  icon,
                  size: 18,
                  strokeWidth: 2.4,
                  color: enabled ? const Color(0xFFFFFFFF) : c.disabledIcon,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
        border: Border.all(color: c.border, width: 1.5),
      ),
      child: Row(
        spacing: 4,
        children: [
          Expanded(
            child: Text(
              'Cantidad',
              style: MusubiType.style(
                15,
                weight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
          button(MusubiIcons.minus, 'Quitar uno', -1),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24),
            child: Semantics(
              liveRegion: true,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: MusubiType.style(
                  18,
                  weight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          button(MusubiIcons.plus, 'Agregar uno', 1),
        ],
      ),
    );
  }
}

/// "SE BUSCA" en rojo (10.5, peso 800).
class SeBuscaBadge extends StatelessWidget {
  const new({super.key, this.small = false});

  /// La de `Mis-solicitudes` (10, icono de 11).
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 9,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: c.brand,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          MusubiIcon(
            MusubiIcons.megaphone,
            size: small ? 11 : 12,
            strokeWidth: 2.4,
            color: const Color(0xFFFFFFFF),
          ),
          Text(
            'SE BUSCA',
            style: MusubiType.style(
              small ? 10 : 10.5,
              weight: FontWeight.w800,
              em: 0.06,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boleto de la solicitud: "Así la verá tu comunidad" (`Necesidad-3`) y la
/// de `Necesidad-publicada` (con "Activa" y "Avisando…").
class WantedPreviewCard extends StatelessWidget {
  const new({
    required this.title,
    required this.budgetCents,
    required this.when,
    super.key,
    this.meta,
    this.dateCaption = 'Lo necesita',
    this.published = false,
  });

  final String title;
  final int? budgetCents;

  /// "vie 9 oct · 1 pieza".
  final String when;

  /// "Calculadoras · Ana R."; sin el, la pastilla "Activa".
  final String? meta;
  final String dateCaption;

  /// Con "Avisando a vendedores con productos parecidos…".
  final bool published;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final caption = MusubiType.style(
      10.5,
      weight: FontWeight.w700,
      em: 0.05,
      color: c.textSecondary,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, published ? 14 : 16),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            children: [
              const SeBuscaBadge(),
              if (meta case final meta?)
                Flexible(
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                )
              else
                const ActivePill(),
            ],
          ),
          Text(
            title,
            style: MusubiType.style(
              16,
              weight: FontWeight.w800,
              line: 21,
              em: -0.01,
              color: c.textPrimary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: TicketSeparator(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: MusubiSizes.space2,
            children: [
              // Con letra muy grande el precio se reduce antes que desbordar.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRESUPUESTO MÁX.', style: caption),
                      Text(
                        budgetCents == null ? r'$—' : formatPrice(budgetCents!),
                        style: MusubiType.style(
                          24,
                          weight: FontWeight.w800,
                          line: 30,
                          em: -0.02,
                          color: c.brandStrongText,
                          tabular: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dateCaption.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: caption,
                    ),
                    Text(
                      when,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        14,
                        weight: FontWeight.w700,
                        line: 22,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (published)
            Row(
              spacing: 8,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.success,
                    shape: BoxShape.circle,
                  ),
                ),
                // NOTE (HU-18): el aviso real a quien tenga algo parecido.
                Flexible(
                  child: Text(
                    'Avisando a vendedores con productos parecidos…',
                    style: MusubiType.style(
                      12.5,
                      weight: FontWeight.w700,
                      color: c.textPrimary,
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

/// Pastilla blanca "Activa" con punto verde.
class ActivePill extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
          ),
          Text(
            'Activa',
            style: MusubiType.style(
              11.5,
              weight: FontWeight.w800,
              color: c.successText,
            ),
          ),
        ],
      ),
    );
  }
}

/// "vie 9 oct · 1 pieza" / "Sin fecha · 2 piezas".
String needWhenLine(DateTime? day, int quantity) =>
    '${day == null ? 'Sin fecha' : shortDate(day)} · '
    '$quantity ${quantity == 1 ? 'pieza' : 'piezas'}';
