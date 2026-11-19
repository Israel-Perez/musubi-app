@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';

import 'support/live_api.dart';

/// Pantallas `Bienvenida`, `Crear-cuenta`, `Verificacion`, `Iniciar-sesion`,
/// `Recuperar` y `Ajustes` (contrasena, cerrar sesion, eliminar cuenta)
/// contra la API real (HU-01, HU-02, HU-03, HU-04, HU-46, HU-56).
void main() {
  group('Sesion contra la API real', skip: liveSkip, () {
    test('crear cuenta: campus, codigo reenviado y verificacion', () async {
      final visitor = LiveSession.visitor();
      addTearDown(visitor.dispose);
      final auth = visitor.read(authRepositoryProvider);
      final email = liveEmail('registro');

      final campus = await auth.resolveCampus(email);
      final registration = await auth.register(
        email: email,
        fullName: liveName,
        password: livePassword,
        acceptTerms: true,
        acceptPrivacy: true,
      );
      final first = await liveCodeFor(email);
      final wrong = auth.confirmCode(
        email: email,
        code: first == '000000' ? '111111' : '000000',
      );
      await expectLater(
        wrong,
        throwsA(
          isA<ApiFailure>().having((f) => f.code, 'code', 'auth.invalid_code'),
        ),
      );
      final session = await auth.confirmCode(email: email, code: first);

      expect(campus.shortName, 'UTTT');
      expect(registration.email, email);
      expect(session.user.email, email);
      expect(session.tokens.accessToken, isNotEmpty);
    });

    test('reenviar el codigo enseguida pide esperar', () async {
      final visitor = LiveSession.visitor();
      addTearDown(visitor.dispose);
      final auth = visitor.read(authRepositoryProvider);
      final email = liveEmail('reenvio');
      await auth.register(
        email: email,
        fullName: liveName,
        password: livePassword,
        acceptTerms: true,
        acceptPrivacy: true,
      );

      await expectLater(
        auth.resendCode(email),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'auth.resend_too_soon',
          ),
        ),
      );
    });

    test('iniciar sesion, y cerrarla revoca la sesion en la API', () async {
      final ana = await liveUser();
      addTearDown(ana.dispose);
      final phone = LiveSession.visitor();
      addTearDown(phone.dispose);

      final signedIn = await phone
          .read(authRepositoryProvider)
          .signIn(email: ana.email, password: livePassword);
      await phone
          .read(sessionControllerProvider.notifier)
          .signIn(signedIn.tokens);
      expect(
        (await phone.read(profileRepositoryProvider).me()).fullName,
        liveName,
      );

      await phone.read(sessionControllerProvider.notifier).logOut();

      expect(phone.read(sessionControllerProvider), isA<Visitor>());
      expect(phone.store.saved, isNull);
      // La otra sesion (otro dispositivo) sigue.
      expect(
        (await ana.read(profileRepositoryProvider).me()).fullName,
        liveName,
      );
    });

    test(
      'contrasena equivocada: el mismo error que un correo desconocido',
      () async {
        final ana = await liveUser();
        addTearDown(ana.dispose);
        final auth = ana.read(authRepositoryProvider);

        Future<String> codeOf(Future<Object?> call) async {
          try {
            await call;
          } on ApiFailure catch (failure) {
            return failure.code;
          }
          return 'sin error';
        }

        expect(
          await codeOf(
            auth.signIn(email: ana.email, password: 'otra2026clave'),
          ),
          'auth.invalid_credentials',
        );
        expect(
          await codeOf(auth.signIn(email: liveEmail(), password: livePassword)),
          'auth.invalid_credentials',
        );
      },
    );

    test('recuperar la contrasena con el codigo del correo', () async {
      final ana = await liveUser();
      addTearDown(ana.dispose);
      final visitor = LiveSession.visitor();
      addTearDown(visitor.dispose);
      final auth = visitor.read(authRepositoryProvider);

      await auth.requestPasswordReset(ana.email);
      await auth.resetPassword(
        email: ana.email,
        code: await liveCodeFor(ana.email),
        newPassword: 'nueva2027clave',
      );

      final back = await auth.signIn(
        email: ana.email,
        password: 'nueva2027clave',
      );
      expect(back.user.email, ana.email);
    });

    test('cambiar la contrasena devuelve una sesion nueva que sirve', () async {
      final ana = await liveUser();
      addTearDown(ana.dispose);

      final renewed = await ana
          .read(accountRepositoryProvider)
          .changePassword(current: livePassword, next: 'otra2027clave');
      await ana.read(sessionControllerProvider.notifier).signIn(renewed);

      expect(
        (await ana.read(profileRepositoryProvider).me()).fullName,
        liveName,
      );
    });

    test('eliminar la cuenta: ya no se puede iniciar sesion', () async {
      final ana = await liveUser();
      addTearDown(ana.dispose);

      await ana.read(accountRepositoryProvider).deleteAccount(livePassword);

      await expectLater(
        ana
            .read(authRepositoryProvider)
            .signIn(email: ana.email, password: livePassword),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'auth.invalid_credentials',
          ),
        ),
      );
    });
  });
}
