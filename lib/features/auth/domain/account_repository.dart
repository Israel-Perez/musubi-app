/// La cuenta de quien tiene sesion (HU-46). Lanza `ApiFailure`: la pantalla
/// decide por el `code` (`auth.wrong_password`).
abstract interface class AccountRepository {
  /// Elimina la cuenta y sus datos; pide la contrasena actual.
  Future<void> deleteAccount(String password);
}
