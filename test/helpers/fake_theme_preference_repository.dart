import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/profile/domain/theme_preference.dart';
import 'package:musubi_app/features/profile/domain/theme_preference_repository.dart';

class FakeThemePreferenceRepository implements ThemePreferenceRepository {
  new({this.preference = ThemePreference.system});

  ThemePreference preference;
  bool failLoad = false;
  bool failSave = false;
  int loads = 0;
  final saves = <ThemePreference>[];

  @override
  Future<ThemePreference> getTheme() async {
    loads++;
    if (failLoad) throw _offline;
    return preference;
  }

  @override
  Future<ThemePreference> setTheme(ThemePreference theme) async {
    saves.add(theme);
    if (failSave) throw _offline;
    return preference = theme;
  }

  /// HU-35: "Recomendarte productos según tu actividad".
  bool recommendations = true;
  final recommendationSaves = <(bool, ThemePreference)>[];

  @override
  Future<bool> getRecommendations() async {
    if (failLoad) throw _offline;
    return recommendations;
  }

  @override
  Future<bool> setRecommendations({
    required bool enabled,
    required ThemePreference theme,
  }) async {
    recommendationSaves.add((enabled, theme));
    if (failSave) throw _offline;
    return recommendations = enabled;
  }

  static const _offline = ApiFailure(
    code: ApiFailure.networkOffline,
    message: 'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
  );
}
