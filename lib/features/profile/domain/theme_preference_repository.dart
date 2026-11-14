import 'package:musubi_app/features/profile/domain/theme_preference.dart';

/// Preferencias por cuenta (filas HU-54 y HU-35 de musubi-api): el tema y
/// "Recomendarte productos según tu actividad".
abstract interface class ThemePreferenceRepository {
  Future<ThemePreference> getTheme();

  Future<ThemePreference> setTheme(ThemePreference theme);

  /// HU-35: si acepta las recomendaciones segun su actividad (sin valor
  /// guardado, si).
  Future<bool> getRecommendations();

  /// HU-35: la API pide el tema en cada cambio; apagarla borra el historial.
  Future<bool> setRecommendations({
    required bool enabled,
    required ThemePreference theme,
  });
}
