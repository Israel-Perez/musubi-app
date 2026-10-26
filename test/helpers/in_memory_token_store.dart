import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/session/token_store.dart';

/// Almacen de sesion en memoria para pruebas (sin Keystore).
class InMemoryTokenStore implements TokenStore {
  new([this.saved]);

  SessionTokens? saved;
  int writes = 0;
  int clears = 0;

  @override
  Future<SessionTokens?> read() async => saved;

  @override
  Future<void> write(SessionTokens tokens) async {
    writes++;
    saved = tokens;
  }

  @override
  Future<void> clear() async {
    clears++;
    saved = null;
  }
}

/// Tokens de prueba (nunca reales).
SessionTokens testTokens([String suffix = '1']) => SessionTokens(
  accessToken: 'access-$suffix',
  accessExpiresAt: DateTime.utc(2026, 10, 21, 12, 15),
  refreshToken: 'refresh-$suffix',
);
