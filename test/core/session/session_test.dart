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
