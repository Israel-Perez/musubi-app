import 'package:musubi_app/core/session/session_tokens.dart';

/// La cuenta de quien tiene sesion (HU-46, HU-04). Lanza `ApiFailure`: la
/// pantalla decide por el `code` (`auth.wrong_password`, `auth.weak_password`).
abstract interface class AccountRepository {
  /// Elimina la cuenta y sus datos; pide la contrasena actual.
  Future<void> deleteAccount(String password);

  /// Cambia la contrasena (HU-04): la API cierra las demas sesiones y
  /// devuelve una nueva para este dispositivo.
  Future<SessionTokens> changePassword({
    required String current,
    required String next,
  });
}
