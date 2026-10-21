import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musubi_app/core/session/session_tokens.dart';

/// Donde vive la sesion entre aperturas de la app (MASVS-STORAGE).
abstract interface class TokenStore {
  Future<SessionTokens?> read();

  Future<void> write(SessionTokens tokens);

  Future<void> clear();
}

/// Almacen cifrado del sistema (Android Keystore) via flutter_secure_storage.
/// Nunca SharedPreferences ni archivos: el backup esta desactivado y el
/// contenido no sale del dispositivo.
class SecureTokenStore implements TokenStore {
  new([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const key = 'musubi.session';

  final FlutterSecureStorage _storage;

  @override
  Future<SessionTokens?> read() async =>
      SessionTokens.tryDecode(await _storage.read(key: key));

  @override
  Future<void> write(SessionTokens tokens) =>
      _storage.write(key: key, value: tokens.encode());

  @override
  Future<void> clear() => _storage.delete(key: key);
}
