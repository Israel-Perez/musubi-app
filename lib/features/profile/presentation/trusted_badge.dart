import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';

/// "Vendedor confiable" (HU-64): no esta en la maqueta; se arma con sus piezas
/// (la pastilla verde de "Precio justo" y el escudo de "Verificada"). La
/// [chip] es la de `Perfil-vendedor` (como "En Musubi desde"); la compacta, la
/// de la tarjeta de quien vende en `Producto`.
class TrustedBadge extends StatelessWidget {
  const new({super.key, this.chip = false});

  final bool chip;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Semantics(
      label: 'Vendedor confiable: 4.5 estrellas o más con al menos 5 ventas',
      excludeSemantics: true,
      child: Container(
        key: const Key('trusted-badge'),
        padding: chip
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: c.successSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: chip ? 5 : 4,
          children: [
            MusubiIcon(
              MusubiIcons.shieldCheck,
              size: chip ? 14 : 12,
              strokeWidth: 2.2,
              color: c.successText,
            ),
            Flexible(
              child: Text(
                'Vendedor confiable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MusubiType.style(
                  chip ? 12.5 : 11,
                  weight: chip ? FontWeight.w700 : FontWeight.w800,
                  line: chip ? null : 15,
                  color: c.successText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
