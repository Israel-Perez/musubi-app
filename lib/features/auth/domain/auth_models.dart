import 'package:flutter/foundation.dart';
import 'package:musubi_app/core/session/session_tokens.dart';

/// Campus detectado por el dominio del correo ("Campus detectado: UTTT").
@immutable
class Campus {
  const new({required this.shortName, required this.name});

  final String shortName;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is Campus && other.shortName == shortName && other.name == name;

  @override
  int get hashCode => Object.hash(shortName, name);
}

/// Cuenta creada: falta verificar el correo (HU-03).
@immutable
class Registration {
  const new({
    required this.email,
    required this.codeExpiresAt,
    required this.resendAvailableAt,
  });

  final String email;
  final DateTime codeExpiresAt;
  final DateTime resendAvailableAt;
}

/// Usuario de la sesion (pantalla "Verificacion-lista").
@immutable
class AuthUser {
  const new({
    required this.id,
    required this.fullName,
    required this.email,
    required this.emailVerified,
    required this.campus,
  });

  final String id;
  final String fullName;
  final String email;
  final bool emailVerified;
  final Campus campus;

  /// Primer nombre para saludar ("Listo, Ana").
  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  /// Iniciales del avatar ("AR").
  String get initials => initialsOf(fullName);
}

/// Sesion recien abierta: tokens + usuario.
@immutable
class SignedInSession {
  const new({required this.tokens, required this.user});

  final SessionTokens tokens;
  final AuthUser user;
}
