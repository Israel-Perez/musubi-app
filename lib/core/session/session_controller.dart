import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/session/token_store.dart';

/// Estado de la sesion: visitante o con sesion (L-16g: siempre viva salvo
/// logout).
@immutable
sealed class SessionState {
  const new();
}

/// Sin cuenta o sin sesion: explora como visitante (HU-48).
final class Visitor extends SessionState {
  const new();

  @override
  bool operator ==(Object other) => other is Visitor;

  @override
  int get hashCode => 0;
}

/// Con sesion: los tokens viajan solo a musubi-api (AuthInterceptor).
final class SignedIn extends SessionState {
  const new(this.tokens);

  final SessionTokens tokens;

  @override
  bool operator ==(Object other) => other is SignedIn && other.tokens == tokens;

  @override
  int get hashCode => tokens.hashCode;
}

/// Almacen de la sesion; en pruebas se sobrescribe con uno en memoria.
final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

/// Tokens leidos en `main()` antes de pintar la app (sin estado "cargando").
final initialSessionTokensProvider = Provider<SessionTokens?>((ref) => null);

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Fuente unica de la sesion. Escribe primero en el almacen seguro y despues
/// cambia el estado, para que la app y el disco nunca discrepen.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    final tokens = ref.watch(initialSessionTokensProvider);
    return tokens == null ? const Visitor() : SignedIn(tokens);
  }

  /// Inicio de sesion o tokens renovados.
  Future<void> signIn(SessionTokens tokens) async {
    await ref.read(tokenStoreProvider).write(tokens);
    state = SignedIn(tokens);
  }

  /// Logout local: borra los tokens del dispositivo (L-10). La revocacion en
  /// la API la hace quien llama antes de esto.
  /// NOTE (HU-02): `POST /api/v1/auth/logout` antes de borrar.
  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = const Visitor();
  }
}
