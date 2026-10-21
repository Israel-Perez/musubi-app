/// Politica de contrasena de la maqueta ("Al menos 8 caracteres · Una letra y
/// un numero"), igual a la del back (musubi-api `PasswordPolicy`).
abstract final class PasswordRules {
  static const minLength = 8;
  static const maxLength = 128;

  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _digit = RegExp(r'\d');

  static bool hasMinLength(String value) =>
      value.length >= minLength && value.length <= maxLength;

  static bool hasLetterAndDigit(String value) =>
      _letter.hasMatch(value) && _digit.hasMatch(value);

  static bool isValid(String value) =>
      hasMinLength(value) && hasLetterAndDigit(value);
}
