import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/profile/data/http_theme_preference_repository.dart';
import 'package:musubi_app/features/profile/domain/theme_preference.dart';
import 'package:musubi_app/features/profile/domain/theme_preference_repository.dart';

final themePreferenceRepositoryProvider = Provider<ThemePreferenceRepository>(
  (ref) => HttpThemePreferenceRepository(ref.watch(dioProvider)),
);

/// Preferencia de la cuenta; visitante y cuenta aún sin valor usan el sistema.
final themePreferenceProvider =
    AsyncNotifierProvider<ThemePreferenceController, ThemePreference>(
      ThemePreferenceController.new,
      retry: (_, _) => null,
    );

class ThemePreferenceController extends AsyncNotifier<ThemePreference> {
  ThemePreferenceRepository get _repository =>
      ref.read(themePreferenceRepositoryProvider);

  @override
  Future<ThemePreference> build() {
    final signedIn = ref.watch(
      sessionControllerProvider.select((session) => session is SignedIn),
    );
    return signedIn ? _repository.getTheme() : Future.value(ThemePreference.system);
  }

  Future<void> setTheme(ThemePreference theme) async {
    final previous = state.value ?? ThemePreference.system;
    state = AsyncData(theme);
    try {
      state = AsyncData(await _repository.setTheme(theme));
    } on Object {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

ThemeMode materialThemeMode(ThemePreference preference) => switch (preference) {
  ThemePreference.system => ThemeMode.system,
  ThemePreference.light => ThemeMode.light,
  ThemePreference.dark => ThemeMode.dark,
};
