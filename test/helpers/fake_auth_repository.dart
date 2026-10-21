import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/domain/auth_repository.dart';

const uttt = Campus(
  shortName: 'UTTT',
  name: 'Universidad Tecnológica de Tula-Tepeji',
);

/// Fake de [AuthRepository] con el comportamiento del back (HU-01/02/03/47/56):
/// solo `@uttt.edu.mx`, codigo `482173`, reenvio cada 60 s. Cuenta activa:
/// [activeEmail] con [activePassword]; [pending] son cuentas sin verificar.
class FakeAuthRepository implements AuthRepository {
  new({DateTime? now}) : now = now ?? DateTime.utc(2026, 10, 21, 12);

  static const validCode = '482173';
  static const activeEmail = 'ana.ramirez@uttt.edu.mx';
  static const activePassword = 'musubi2026';

  DateTime now;
  final Set<String> registered = {};
  final Map<String, String> passwords = {activeEmail: activePassword};
  final Set<String> pending = {};
  final List<String> calls = [];
  ApiFailure? nextFailure;

  ApiFailure? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }

  @override
  Future<Campus> resolveCampus(String email) async {
    calls.add('campus:$email');
    final failure = _takeFailure();
    if (failure != null) throw failure;
    if (!email.trim().toLowerCase().endsWith('@uttt.edu.mx')) {
      throw const ApiFailure(
        code: 'auth.email_not_institutional',
        message: 'Usa el correo que te dio tu universidad.',
        status: 422,
      );
    }
    return uttt;
  }

  @override
  Future<Registration> register({
    required String email,
    required String fullName,
    required String password,
    required bool acceptTerms,
    required bool acceptPrivacy,
  }) async {
    calls.add('register:$email:$acceptTerms:$acceptPrivacy');
    final failure = _takeFailure();
    if (failure != null) throw failure;
    final normalized = email.trim().toLowerCase();
    if (!registered.add(normalized)) {
      throw const ApiFailure(
        code: 'auth.email_already_registered',
        message: 'Ese correo ya tiene una cuenta. Inicia sesión.',
        status: 409,
      );
    }
    return Registration(
      email: normalized,
      codeExpiresAt: now.add(const Duration(minutes: 10)),
      resendAvailableAt: now.add(const Duration(seconds: 60)),
    );
  }

  @override
  Future<DateTime> resendCode(String email) async {
    calls.add('resend:$email');
    final failure = _takeFailure();
    if (failure != null) throw failure;
    return now.add(const Duration(seconds: 60));
  }

  @override
  Future<SignedInSession> confirmCode({
    required String email,
    required String code,
  }) async {
    calls.add('confirm:$email:$code');
    if (code != validCode) throw invalidCode;
    return _session(email);
  }

  @override
  Future<SignedInSession> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    calls.add('signIn:$normalized');
    final failure = _takeFailure();
    if (failure != null) throw failure;
    if (pending.contains(normalized) && password == activePassword) {
      throw const ApiFailure(
        code: 'auth.email_not_verified',
        message: 'Verifica tu correo institucional para continuar.',
        status: 403,
      );
    }
    if (passwords[normalized] != password) {
      throw const ApiFailure(
        code: 'auth.invalid_credentials',
        message:
            'El correo o la contraseña no coinciden. Revísalos e inténtalo '
            'otra vez.',
        status: 401,
      );
    }
    return _session(normalized);
  }

  @override
  Future<DateTime> requestPasswordReset(String email) async {
    calls.add('forgot:${email.trim().toLowerCase()}');
    final failure = _takeFailure();
    if (failure != null) throw failure;
    return now.add(const Duration(seconds: 60));
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    calls.add('reset:$email:$code');
    final failure = _takeFailure();
    if (failure != null) throw failure;
    if (code != validCode) throw invalidCode;
    passwords[email] = newPassword;
  }

  static const invalidCode = ApiFailure(
    code: 'auth.invalid_code',
    message: 'El código no es válido o ya venció. Pide uno nuevo.',
    status: 400,
  );

  SignedInSession _session(String email) => SignedInSession(
    tokens: SessionTokens(
      accessToken: 'access',
      accessExpiresAt: now.add(const Duration(minutes: 15)),
      refreshToken: 'refresh',
    ),
    user: AuthUser(
      id: 'u1',
      fullName: 'Ana Sofía Ramírez',
      email: email,
      emailVerified: true,
      campus: uttt,
    ),
  );
}
