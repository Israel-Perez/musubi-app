import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/profile/domain/theme_preference.dart';
import 'package:musubi_app/features/profile/domain/theme_preference_repository.dart';

class FakeThemePreferenceRepository implements ThemePreferenceRepository {
  ThemePreference preference;
  bool failLoad = false;
  bool failSave = false;
  int loads = 0;
  final saves = <ThemePreference>[];

  FakeThemePreferenceRepository({this.preference = ThemePreference.system});

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

  static const _offline = ApiFailure(
    code: ApiFailure.networkOffline,
    message: 'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
  );
}
