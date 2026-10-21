import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/data/http_auth_repository.dart';

import '../../../helpers/fake_http_adapter.dart';

// HU-01 / HU-03: el repositorio habla el contrato de musubi-api
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

    expect(
      session.tokens,
      SessionTokens(
        accessToken: 'a',
        accessExpiresAt: DateTime.utc(2026, 10, 21, 18, 15),
        refreshToken: 'r',
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
}
