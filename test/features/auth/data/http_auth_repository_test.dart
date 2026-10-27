import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/data/http_auth_repository.dart';

import '../../../helpers/fake_http_adapter.dart';

// HU-01 / HU-02 / HU-03 / HU-56: el repositorio habla el contrato de
// musubi-api
// (ContractTest/Fixtures/{campus,register,session}.json) y traduce los errores.
void main() {
  late FakeHttpAdapter adapter;
  late HttpAuthRepository repository;

  void serve(Object body, {int status = 200}) {
    adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json(body, status: status),
    );
    repository = HttpAuthRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
    );
  }

  test('campus: POST con el correo sin espacios', () async {
    serve({
      'shortName': 'UTTT',
      'name': 'Universidad Tecnológica de Tula-Tepeji',
    });

    final campus = await repository.resolveCampus('  ana@uttt.edu.mx ');

    expect(campus.shortName, 'UTTT');
    expect(adapter.requests.single.path, ApiPaths.authCampus);
    expect(adapter.requests.single.data, {'email': 'ana@uttt.edu.mx'});
  });

  test('registro: envia los consentimientos y lee las fechas', () async {
    serve({
      'email': 'ana@uttt.edu.mx',
      'codeExpiresAt': '2026-10-21T18:10:00Z',
      'resendAvailableAt': '2026-10-21T18:01:00Z',
    }, status: 201);

    final registration = await repository.register(
      email: 'ana@uttt.edu.mx',
      fullName: ' Ana Sofía ',
      password: 'musubi2026',
      acceptTerms: true,
      acceptPrivacy: true,
    );

    expect(registration.resendAvailableAt, DateTime.utc(2026, 10, 21, 18, 1));
    final sent = adapter.requests.single.data as Map<String, Object>;
    expect(sent['fullName'], 'Ana Sofía');
    expect(sent['acceptTerms'], isTrue);
    expect(sent['acceptPrivacy'], isTrue);
  });

  const sessionJson = {
    'accessToken': 'a',
    'accessTokenExpiresAt': '2026-10-21T18:15:00Z',
    'refreshToken': 'r',
    'refreshTokenExpiresAt': '2026-12-20T18:00:00Z',
    'user': {
      'id': 'u1',
      'fullName': 'Ana Sofía Ramírez',
      'email': 'ana@uttt.edu.mx',
      'emailVerified': true,
      'campus': {'shortName': 'UTTT', 'name': 'UTTT completa'},
    },
  };

  test('confirmacion: arma la sesion y el usuario', () async {
    serve({
      'accessToken': 'a',
      'accessTokenExpiresAt': '2026-10-21T18:15:00Z',
      'refreshToken': 'r',
      'refreshTokenExpiresAt': '2026-12-20T18:00:00Z',
      'user': {
        'id': 'u1',
        'fullName': 'Ana Sofía Ramírez',
        'email': 'ana@uttt.edu.mx',
        'emailVerified': true,
        'campus': {'shortName': 'UTTT', 'name': 'UTTT completa'},
      },
    });

    final session = await repository.confirmCode(
      email: 'ana@uttt.edu.mx',
      code: '482173',
    );

    // El perfil viaja con la sesion para saludar ("Hola, Ana") sin otra
    // llamada (SCRUM-82).
    expect(
      session.tokens,
      SessionTokens(
        accessToken: 'a',
        accessExpiresAt: DateTime.utc(2026, 10, 21, 18, 15),
        refreshToken: 'r',
        profile: const SessionProfile(
          fullName: 'Ana Sofía Ramírez',
          email: 'ana@uttt.edu.mx',
          campus: 'UTTT',
        ),
      ),
    );
    expect(session.user.initials, 'AR');
    expect(session.user.firstName, 'Ana');
    expect(session.user.campus.shortName, 'UTTT');
  });

  test('errores: ApiFailure con el code del catalogo, nunca DioException', () {
    serve({
      'title': 'Ese correo ya tiene una cuenta. Inicia sesión.',
      'status': 409,
      'code': 'auth.email_already_registered',
    }, status: 409);

    expect(
      () => repository.register(
        email: 'ana@uttt.edu.mx',
        fullName: 'Ana',
        password: 'musubi2026',
        acceptTerms: true,
        acceptPrivacy: true,
      ),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.code,
          'code',
          'auth.email_already_registered',
        ),
      ),
    );
  });

  test('login: POST con correo y contrasena, misma forma de sesion', () async {
    serve(sessionJson);

    final session = await repository.signIn(
      email: ' ana@uttt.edu.mx ',
      password: 'musubi2026',
    );

    expect(adapter.requests.single.path, ApiPaths.authLogin);
    expect(adapter.requests.single.data, {
      'email': 'ana@uttt.edu.mx',
      'password': 'musubi2026',
    });
    expect(session.tokens.refreshToken, 'r');
    expect(session.user.email, 'ana@uttt.edu.mx');
  });

  test('login: credenciales incorrectas llegan como ApiFailure', () {
    serve({
      'title': 'El correo o la contraseña no coinciden.',
      'status': 401,
      'code': 'auth.invalid_credentials',
    }, status: 401);

    expect(
      () => repository.signIn(email: 'ana@uttt.edu.mx', password: 'x'),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.code,
          'code',
          'auth.invalid_credentials',
        ),
      ),
    );
  });

  test('recuperar: pide el codigo y lee la espera', () async {
    serve({'resendAvailableAt': '2026-10-21T18:01:00Z'}, status: 202);

    final next = await repository.requestPasswordReset(' ana@uttt.edu.mx');

    expect(next, DateTime.utc(2026, 10, 21, 18, 1));
    expect(adapter.requests.single.path, ApiPaths.authPasswordForgot);
    expect(adapter.requests.single.data, {'email': 'ana@uttt.edu.mx'});
  });

  test('recuperar: 204 sin cuerpo al guardar la contrasena nueva', () async {
    adapter = FakeHttpAdapter((_) async => ResponseBody.fromString('', 204));
    repository = HttpAuthRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
    );

    await repository.resetPassword(
      email: 'ana@uttt.edu.mx',
      code: ' 482173 ',
      newPassword: 'nueva2026clave',
    );

    expect(adapter.requests.single.path, ApiPaths.authPasswordReset);
    expect(adapter.requests.single.data, {
      'email': 'ana@uttt.edu.mx',
      'code': '482173',
      'newPassword': 'nueva2026clave',
    });
  });
}
