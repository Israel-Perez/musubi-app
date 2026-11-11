import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_controls.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/features/profile/domain/theme_preference.dart';
import 'package:musubi_app/features/profile/presentation/theme_preference_providers.dart';

/// "Modo noche" de `Ajustes` · "Preferencias" (HU-54), como la maqueta: un
/// interruptor. Muestra el tema que se ve (si la cuenta no ha elegido, el del
/// telefono) y guarda `dark` o `light` en la cuenta. Avisa "Modo noche
/// activado" o "desactivado"; si no se guarda, vuelve al tema anterior y deja
/// reintentar.
class DarkModeRow extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      // Como `Privacidad`: el interruptor trae 7 de area tactil a cada lado.
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: MusubiIcon(
                MusubiIcons.moon,
                size: 19,
                strokeWidth: 1.9,
                color: c.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Modo noche',
              style: MusubiType.style(
                15,
                weight: FontWeight.w700,
                line: 20,
                color: c.textPrimary,
              ),
            ),
          ),
          MusubiSwitch(
            key: const Key('settings-dark'),
            value: dark,
            semanticLabel: 'Modo noche',
            onChanged: (on) => unawaited(
              _save(
                ref.read(themePreferenceProvider.notifier),
                ScaffoldMessenger.of(context),
                on: on,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _save(
  ThemePreferenceController theme,
  ScaffoldMessengerState messenger, {
  required bool on,
}) async {
  try {
    await theme.setTheme(on ? ThemePreference.dark : ThemePreference.light);
    showMusubiSnack(
      messenger,
      on ? 'Modo noche activado' : 'Modo noche desactivado',
      tone: SnackTone.info,
      duration: const Duration(milliseconds: 1800),
    );
  } on ApiFailure catch (failure) {
    showMusubiSnack(
      messenger,
      'No pudimos guardar el cambio. ${failure.message}',
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
      actionLabel: 'Reintentar',
      onAction: () => unawaited(_save(theme, messenger, on: on)),
    );
  }
}
