import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';

/// Campus que ve un visitante. NOTE (HU-48): con mas comunidades activas
/// (RNF-21), el visitante elige campus y el de la cuenta sale de su correo.
abstract final class DefaultCampus {
  static const shortName = 'UTTT';
  static const place = 'Tula-Tepeji, Hidalgo';
  static const domain = 'uttt.edu.mx';
}

/// Chip "UTTT" junto al logo. Visitante: con flecha, abre la hoja del campus
/// ("Estás explorando la UTTT"). Con sesion: la insignia de verificado y no
/// se toca (maqueta `Inicio`).
class CampusChip extends StatelessWidget {
  const new({required this.signedIn, super.key});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget chip({bool pressed = false}) => Container(
      height: 34,
      padding: EdgeInsets.only(left: 4, right: signedIn ? 10 : 9),
      decoration: BoxDecoration(
        color: pressed ? c.surfacePressed : c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
            child: const Center(
              child: MusubiIcon(
                MusubiIcons.graduationCap,
                size: 15,
                strokeWidth: 2.2,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          Text(
            DefaultCampus.shortName,
            style: MusubiType.style(
              13.5,
              weight: FontWeight.w800,
              line: 16,
              em: 0.02,
              color: c.textPrimary,
            ),
          ),
          if (signedIn)
            const VerifiedBadge(size: 15)
          else
            MusubiIcon(
              MusubiIcons.chevronDown,
              size: 14,
              strokeWidth: 2.6,
              color: c.textSecondary,
            ),
        ],
      ),
    );

    if (signedIn) {
      return Semantics(
        label: 'Tu campus: ${DefaultCampus.shortName}',
        excludeSemantics: true,
        child: chip(),
      );
    }
    return Pressable(
      key: const Key('campus-chip'),
      semanticLabel: 'Campus ${DefaultCampus.shortName}',
      onTap: () => unawaited(
        showAccountGate(
          context,
          motive: AccountGateMotive.campus,
          returnTo: AppRoutes.home,
        ),
      ),
      builder: (context, pressed) => SizedBox(
        height: MusubiSizes.minTouch,
        child: Center(child: chip(pressed: pressed)),
      ),
    );
  }
}
