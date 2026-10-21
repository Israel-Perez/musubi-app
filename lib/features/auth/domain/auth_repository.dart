import 'package:musubi_app/features/auth/domain/auth_models.dart';

/// Registro y verificacion (HU-01, HU-03, HU-47) contra musubi-api.
///
/// Cada metodo lanza `ApiFailure` (nunca `DioException`) con el `code` del
/// catalogo `musubi-api/docs/errores.md`; la UI decide por ese codigo.
abstract interface class AuthRepository {
  /// Campus del correo, o `auth.email_not_institutional`.
  Future<Campus> resolveCampus(String email);

  /// Crea la cuenta pendiente y envia el codigo de 6 digitos.
  Future<Registration> register({
    required String email,
    required String fullName,
    required String password,
    required bool acceptTerms,
    required bool acceptPrivacy,
  });

  /// Pide otro codigo; devuelve desde cuando se puede volver a pedir.
  Future<DateTime> resendCode(String email);

  /// Verifica el correo y abre la sesion.
  Future<SignedInSession> confirmCode({
    required String email,
    required String code,
  });
}
