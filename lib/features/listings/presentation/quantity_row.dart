import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';

/// "Piezas disponibles" con quitar y agregar (HU-50): de [min] a
/// [SellDraft.maxQuantity]. Al publicar el minimo es 1 (`Vender-4`); al
/// cambiar las piezas desde `Mis-productos` es 0 (queda agotada). Sin [onStep]
/// (al editar, HU-07) se ve la cantidad sin poder cambiarla, con [note].
class QuantityRow extends StatelessWidget {
  const new({
    required this.quantity,
    required this.onStep,
    super.key,
    this.min = 1,
    this.note,
    this.margin = const EdgeInsets.fromLTRB(20, 18, 20, 0),
  });

  final int quantity;
  final ValueChanged<int>? onStep;
  final int min;

  /// Linea debajo de "Piezas disponibles".
  final String? note;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget button({
      required MusubiIconData icon,
      required String label,
      required bool enabled,
      required int delta,
    }) => Pressable(
      key: Key('sell-quantity-$delta'),
      onTap: enabled && onStep != null ? () => onStep!(delta) : null,
      semanticLabel: label,
      builder: (context, pressed) => SizedBox.square(
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
    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
        border: Border.all(color: c.border, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  'Piezas disponibles',
                  style: MusubiType.style(
                    15,
                    weight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                if (note case final note?)
                  Text(
                    note,
                    key: const Key('sell-quantity-locked'),
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          button(
            icon: MusubiIcons.minus,
            label: 'Quitar uno',
            enabled: onStep != null && quantity > min,
            delta: -1,
          ),
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
          button(
            icon: MusubiIcons.plus,
            label: 'Agregar uno',
            enabled: onStep != null && quantity < SellDraft.maxQuantity,
            delta: 1,
          ),
        ],
      ),
    );
  }
}
