import 'package:musubi_app/features/profile/domain/theme_preference.dart';

/// Preferencia de apariencia por cuenta (filas HU-54 de musubi-api).
abstract interface class ThemePreferenceRepository {
  Future<ThemePreference> getTheme();

  Future<ThemePreference> setTheme(ThemePreference theme);
}
