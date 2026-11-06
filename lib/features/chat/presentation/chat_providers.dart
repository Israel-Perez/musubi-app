import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/data/http_chat_repository.dart';
import 'package:musubi_app/features/chat/data/signalr_chat_realtime.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/domain/chat_repository.dart';

/// Conversaciones y bandeja (HU-20, HU-22), con sesion. En pruebas, un fake.
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => HttpChatRepository(
    ref.watch(dioProvider),
    ref.watch(appConfigProvider).apiBaseUrl,
  ),
);

/// Margen para renovar el access token antes de abrir el WebSocket.
const _tokenMargin = Duration(minutes: 1);

/// Tiempo real del chat: conectado mientras haya sesion. En pruebas, un fake.
final chatRealtimeProvider = Provider<ChatRealtime>((ref) {
  final realtime = SignalRChatRealtime(
    apiBaseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    readToken: () async {
      final current = ref.read(sessionControllerProvider);
      if (current is! SignedIn) return null;
      final now = ref.read(clockProvider)();
      if (current.tokens.accessExpiresAt.isBefore(now.add(_tokenMargin))) {
        // Renueva por el mismo camino que el resto de la app (AuthInterceptor
        // en cola): un refresh token usado dos veces cierra la sesion (02-03).
        await ref
            .read(dioProvider)
            .get<void>(ApiPaths.conversations, queryParameters: {'limit': 1});
      }
      return switch (ref.read(sessionControllerProvider)) {
        SignedIn(:final tokens) => tokens.accessToken,
        Visitor() => null,
      };
    },
  );
  ref.onDispose(() => unawaited(realtime.stop()));
  return realtime;
});

/// Enciende el tiempo real al abrir `Mensajes` o un chat y lo apaga al cerrar
/// la sesion. Despues sigue conectado (la bandeja se actualiza sola).
final chatConnectionProvider = Provider<void>((ref) {
  final signedIn = ref.watch(
    sessionControllerProvider.select((s) => s is SignedIn),
  );
  final realtime = ref.watch(chatRealtimeProvider);
  if (signedIn) {
    realtime.start();
  } else {
    unawaited(realtime.stop());
  }
});

/// Cada mensaje que llega en tiempo real.
final StreamProvider<ChatMessage> chatIncomingProvider =
    StreamProvider<ChatMessage>(
      (ref) => ref.watch(chatRealtimeProvider).messages,
    );

/// Bandeja por pestana. Se vuelve a pedir al llegar un mensaje.
final FutureProviderFamily<InboxPage, InboxFilter> inboxProvider =
    FutureProvider.autoDispose.family<InboxPage, InboxFilter>((ref, filter) {
      ref.listen(chatIncomingProvider, (_, next) {
        if (next.hasValue) ref.invalidateSelf();
      });
      return ref.watch(chatRepositoryProvider).inbox(filter: filter);
    }, retry: (_, _) => null);
