import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Tokens de una sesion (spec musubi-api:02-03): access JWT de 15 minutos y
/// refresh opaco de 60 dias que rota en cada uso.
@immutable
class SessionTokens {
  const new({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
  });

  /// Lee el JSON guardado; devuelve `null` si esta corrupto o incompleto.
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
      );
    } on FormatException {
      return null;
    }
  }

  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;

  String encode() => jsonEncode({
    'accessToken': accessToken,
    'accessExpiresAt': accessExpiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
  });

  @override
  bool operator ==(Object other) =>
      other is SessionTokens &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.accessExpiresAt == accessExpiresAt;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, accessExpiresAt);

  // Nunca imprime los tokens (MASVS-STORAGE: nada sensible en los logs).
  @override
  String toString() => 'SessionTokens(expira: $accessExpiresAt)';
}
