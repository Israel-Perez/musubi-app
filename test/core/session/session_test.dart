import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/session/token_store.dart';

import '../../helpers/in_memory_token_store.dart';

// 02-01 / L-16g / L-10: la sesion vive en el almacen seguro y sobrevive a
// reiniciar la app; el logout la borra del dispositivo.
void main() {
  group('SessionTokens', () {
    test('se codifica y decodifica igual', () {
      final tokens = testTokens();

      expect(SessionTokens.tryDecode(tokens.encode()), tokens);
    });

    test('el perfil de la sesion se guarda y se lee con los tokens', () {
      final tokens = SessionTokens(
        accessToken: 'a',
        accessExpiresAt: DateTime.utc(2026, 10, 21, 12, 15),
        refreshToken: 'r',
        profile: const SessionProfile(
          fullName: 'Ana Sofía Ramírez',
          email: 'ana.ramirez@uttt.edu.mx',
          campus: 'UTTT',
        ),
      );

      final decoded = SessionTokens.tryDecode(tokens.encode());

      expect(decoded, tokens);
      expect(decoded?.profile?.firstName, 'Ana');
      expect(decoded?.profile?.initials, 'AR');
      expect(tokens.toString(), isNot(contains('Ana')));
    });

    test('una sesion guardada antes del perfil sigue valida', () {
      const old =
          '{"accessToken":"a","accessExpiresAt":"2026-10-21T12:15:00.000Z",'
          '"refreshToken":"r"}';

      final decoded = SessionTokens.tryDecode(old);

      expect(decoded?.refreshToken, 'r');
      expect(decoded?.profile, isNull);
    });

    test('la respuesta de la API trae el perfil (fixture session.json)', () {
      final tokens = SessionTokens.fromApi(const {
        'accessToken': 'a',
        'accessTokenExpiresAt': '2026-10-21T18:15:00Z',
        'refreshToken': 'r',
        'user': {
          'fullName': 'Ana Sofía Ramírez',
          'email': 'ana.ramirez@uttt.edu.mx',
          'campus': {'shortName': 'UTTT', 'name': 'Universidad'},
        },
      });

      expect(tokens.profile?.campus, 'UTTT');
      expect(tokens.profile?.email, 'ana.ramirez@uttt.edu.mx');
    });

    test('un valor corrupto o incompleto no es una sesion', () {
      expect(SessionTokens.tryDecode(null), isNull);
      expect(SessionTokens.tryDecode('no-es-json'), isNull);
      expect(SessionTokens.tryDecode('{"accessToken":"a"}'), isNull);
      expect(SessionTokens.tryDecode('[1,2]'), isNull);
    });

    test('toString nunca expone los tokens', () {
      final text = testTokens().toString();

      expect(text, isNot(contains('access-1')));
      expect(text, isNot(contains('refresh-1')));
    });

    test('se guarda bajo una sola llave del almacen seguro', () {
      expect(SecureTokenStore.key, 'musubi.session');
    });
  });

  group('SessionController', () {
    ProviderContainer container(InMemoryTokenStore store) =>
        ProviderContainer.test(
          overrides: [
            tokenStoreProvider.overrideWithValue(store),
            initialSessionTokensProvider.overrideWithValue(store.saved),
          ],
        );

    test('sin tokens guardados entra como visitante', () {
      final c = container(InMemoryTokenStore());

      expect(c.read(sessionControllerProvider), const Visitor());
    });

    test('con tokens guardados la sesion sigue viva al abrir', () {
      final c = container(InMemoryTokenStore(testTokens()));

      expect(c.read(sessionControllerProvider), SignedIn(testTokens()));
    });

    test(
      'signIn guarda primero en el almacen y luego cambia el estado',
      () async {
        final store = InMemoryTokenStore();
        final c = container(store);

        await c
            .read(sessionControllerProvider.notifier)
            .signIn(testTokens('2'));

        expect(store.saved, testTokens('2'));
        expect(c.read(sessionControllerProvider), SignedIn(testTokens('2')));
      },
    );

    test('signOut borra los tokens del dispositivo', () async {
      final store = InMemoryTokenStore(testTokens());
      final c = container(store);

      await c.read(sessionControllerProvider.notifier).signOut();

      expect(store.saved, isNull);
      expect(store.clears, 1);
      expect(c.read(sessionControllerProvider), const Visitor());
    });
  });
}
