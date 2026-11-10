/// Preferencia de apariencia de la cuenta (HU-54, musubi-api M-02).
enum ThemePreference {
  system('system', 'Como el sistema'),
  light('light', 'Modo claro'),
  dark('dark', 'Modo noche');

  new(this.value, this.label);

  final String value;
  final String label;

  static ThemePreference parse(Object? value) =>
      ThemePreference.values
          .where((preference) => preference.value == value)
          .firstOrNull ??
      ThemePreference.system;
}
