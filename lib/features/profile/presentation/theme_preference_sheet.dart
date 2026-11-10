import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/features/profile/domain/theme_preference.dart';
import 'package:musubi_app/features/profile/presentation/theme_preference_providers.dart';

Future<void> showThemePreferenceSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final selected = ref.read(themePreferenceProvider).value ??
      ThemePreference.system;
  await showMusubiPanel<void>(
    context,
    builder: (sheetContext) => MusubiPanel(
      key: const Key('theme-preference-sheet'),
      title: 'Apariencia',
      bodyInset: 12,
      child: MusubiOptions<ThemePreference>(
        selected: selected,
        options: const [
          MusubiOption(
            value: ThemePreference.system,
            label: 'Como el sistema',
            sub: 'Usa el tema de tu dispositivo',
            icon: MusubiIcons.settings,
          ),
          MusubiOption(
            value: ThemePreference.light,
            label: 'Modo claro',
            icon: MusubiIcons.lightbulb,
          ),
          MusubiOption(
            value: ThemePreference.dark,
            label: 'Modo noche',
            icon: MusubiIcons.moon,
          ),
        ],
        onPick: (preference) {
          Navigator.of(sheetContext).pop();
          unawaited(_saveTheme(context, ref, preference));
        },
      ),
    ),
  );
}

Future<void> _saveTheme(
  BuildContext context,
  WidgetRef ref,
  ThemePreference preference,
) async {
  try {
    await ref.read(themePreferenceProvider.notifier).setTheme(preference);
  } on Object catch (error) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    showMusubiSnack(
      messenger,
      error is ApiFailure
          ? error.message
          : 'No guardamos tu preferencia. Inténtalo de nuevo.',
      tone: SnackTone.warn,
      icon: MusubiIcons.x,
      actionLabel: 'Reintentar',
      onAction: () => unawaited(_saveTheme(context, ref, preference)),
    );
  }
}
