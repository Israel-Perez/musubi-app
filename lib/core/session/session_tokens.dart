import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Quien tiene la sesion, tal como lo manda musubi-api en `SessionResponse`
/// (`user.fullName`, `user.email`, `user.campus.shortName`): para saludar
/// ("Hola, Ana") sin pedir el perfil (HU-04).
@immutable
class SessionProfile {
  const new({
    required this.fullName,
    required this.email,
    required this.campus,
  });

  final String fullName;
  final String email;

  /// Siglas del campus ("UTTT").
  final String campus;

  /// Primer nombre para saludar ("Ana").
  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  /// Iniciales del avatar ("AR").
  String get initials => initialsOf(fullName);

  static SessionProfile? tryParse(Object? json) {
    if (json is! Map) return null;
    final name = json['fullName'];
    final email = json['email'];
    final campus = json['campus'];
    final shortName = campus is Map ? campus['shortName'] : campus;
    if (name is! String || email is! String || shortName is! String) {
      return null;
    }
    return SessionProfile(fullName: name, email: email, campus: shortName);
  }

  Map<String, String> toJson() => {
    'fullName': fullName,
    'email': email,
    'campus': campus,
  };

  @override
  bool operator ==(Object other) =>
      other is SessionProfile &&
      other.fullName == fullName &&
      other.email == email &&
      other.campus == campus;

  @override
  int get hashCode => Object.hash(fullName, email, campus);
}

/// Iniciales de un nombre: la primera letra del primer y del ultimo nombre
/// ("Ana Sofía Ramírez" → "AR").
String initialsOf(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  final first = parts.first;
  final last = parts.length > 1 ? parts.last : '';
  return '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'
      .toUpperCase();
}

/// Tokens de una sesion (spec musubi-api:02-03): access JWT de 15 minutos y
/// refresh opaco de 60 dias que rota en cada uso.
@immutable
class SessionTokens {
  const new({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    this.profile,
  });

  /// Tokens de una `SessionResponse` de musubi-api (login, refresh y
  /// confirmacion del correo; fixture `session.json` del back).
  factory fromApi(Map<String, dynamic> json) => SessionTokens(
    accessToken: json['accessToken'] as String,
    accessExpiresAt: DateTime.parse('${json['accessTokenExpiresAt']}').toUtc(),
    refreshToken: json['refreshToken'] as String,
    profile: SessionProfile.tryParse(json['user']),
  );

  /// Lee el JSON guardado; devuelve `null` si esta corrupto o incompleto. Una
  /// sesion guardada antes de tener el perfil sigue valida (sin perfil).
  static SessionTokens? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final access = json['accessToken'];
      final refresh = json['refreshToken'];
      final expires = DateTime.tryParse('${json['accessExpiresAt']}');
      if (access is! String || refresh is! String || expires == null) {
        return null;
      }
      return SessionTokens(
        accessToken: access,
        accessExpiresAt: expires.toUtc(),
        refreshToken: refresh,
        profile: SessionProfile.tryParse(json['profile']),
      );
    } on FormatException {
      return null;
    }
  }

  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;

  /// `null` si la sesion se guardo antes de conocer el perfil.
  final SessionProfile? profile;

  String encode() => jsonEncode({
    'accessToken': accessToken,
    'accessExpiresAt': accessExpiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    if (profile != null) 'profile': profile!.toJson(),
  });

  @override
  bool operator ==(Object other) =>
      other is SessionTokens &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.accessExpiresAt == accessExpiresAt &&
      other.profile == profile;

  @override
  int get hashCode =>
      Object.hash(accessToken, refreshToken, accessExpiresAt, profile);

  // Nunca imprime los tokens ni datos personales (MASVS-STORAGE).
  @override
  String toString() => 'SessionTokens(expira: $accessExpiresAt)';
}
