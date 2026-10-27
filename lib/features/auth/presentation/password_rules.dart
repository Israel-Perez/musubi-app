import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/css_line_box.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';

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

/// Las dos reglas de la politica, en vivo mientras se escribe (maqueta
/// `Registro`: en verde las que ya se cumplen).
class PasswordRuleList extends StatelessWidget {
  const new({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 6,
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

/// Una regla de la politica con su palomita.
class PasswordRuleRow extends StatelessWidget {
  const new({required this.ok, required this.text, super.key});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final color = ok ? c.successText : c.textSecondary;
    return Semantics(
      label: '$text: ${ok ? 'cumple' : 'pendiente'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          MusubiIcon(
            MusubiIcons.check,
            size: 16,
            strokeWidth: 2.2,
            color: color,
          ),
          CssLineBox(
            fontSize: 13,
            child: Text(
              text,
              style: MusubiType.style(
                13,
                weight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
