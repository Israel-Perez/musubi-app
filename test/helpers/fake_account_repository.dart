import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/domain/account_repository.dart';

/// La cuenta de la prueba (HU-46, HU-04): su contrasena es [password].
class FakeAccountRepository implements AccountRepository {
  static const password = 'musubi2026';

  final attempts = <String>[];

  /// Sesion que devuelve el cambio de contrasena (HU-04).
  SessionTokens? changedTokens;

  /// Ultima contrasena nueva aceptada.
  String? newPassword;

  static const _wrongPassword = ApiFailure(
    code: 'auth.wrong_password',
    message: 'La contraseña no es correcta.',
    status: 400,
  );

  @override
  Future<void> deleteAccount(String password) async {
    attempts.add(password);
    if (password != FakeAccountRepository.password) throw _wrongPassword;
  }

  @override
  Future<SessionTokens> changePassword({
    required String current,
    required String next,
  }) async {
    attempts.add(current);
    if (current != password) throw _wrongPassword;
    newPassword = next;
    return changedTokens ??
        SessionTokens(
          accessToken: 'access-nuevo',
          accessExpiresAt: DateTime.utc(2030),
          refreshToken: 'refresh-nuevo',
          profile: const SessionProfile(
            fullName: 'Ana Sofía Ramírez',
            email: 'ana.ramirez@uttt.edu.mx',
            campus: 'UTTT',
          ),
        );
  }
}
