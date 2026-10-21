import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';

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

/// Las dos reglas de la politica, en vivo mientras se escribe.
class PasswordRuleList extends StatelessWidget {
  const new({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      PasswordRuleRow(
        ok: PasswordRules.hasMinLength(password),
        text: 'Al menos 8 caracteres',
      ),
      PasswordRuleRow(
        ok: PasswordRules.hasLetterAndDigit(password),
        text: 'Una letra y un número',
      ),
    ],
  );
}

/// Una regla de la politica con su palomita (maqueta `Registro`).
class PasswordRuleRow extends StatelessWidget {
  const new({required this.ok, required this.text, super.key});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final color = ok ? c.successText : c.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: color,
          ),
          const SizedBox(width: MusubiSizes.space2),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
