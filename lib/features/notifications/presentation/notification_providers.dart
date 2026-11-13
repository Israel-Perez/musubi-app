import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/features/notifications/data/http_notification_repository.dart';
import 'package:musubi_app/features/notifications/data/push_service.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';
import 'package:musubi_app/features/notifications/domain/notification_repository.dart';

/// El centro de notificaciones (HU-31). En pruebas, un fake.
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => HttpNotificationRepository(ref.watch(dioProvider)),
);

/// Los avisos push del telefono. En pruebas, un fake.
final pushServiceProvider = Provider<PushService>(
  (ref) => FirebasePushService(),
);

/// Para mostrar un aviso que llega con la app abierta en cualquier pantalla.
final scaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>(
      (ref) => GlobalKey<ScaffoldMessengerState>(),
    );

/// Una pestana de `Notificaciones`. Se vuelve a pedir al llegar un push.
final FutureProviderFamily<NotificationPage, NotificationTab>
notificationsProvider = FutureProvider.autoDispose
    .family<NotificationPage, NotificationTab>((ref, tab) {
      ref.listen(pushArrivedProvider, (_, _) => ref.invalidateSelf());
      return ref.watch(notificationRepositoryProvider).list(tab);
    }, retry: (_, _) => null);

/// Cuantos avisos sin leer (el punto de la campana de `Inicio`). Sin sesion o
/// sin red, 0.
final FutureProvider<int> unreadNotificationsProvider =
    FutureProvider.autoDispose<int>((ref) async {
      ref.listen(pushArrivedProvider, (_, _) => ref.invalidateSelf());
      if (ref.watch(sessionControllerProvider) is! SignedIn) return 0;
      try {
        final page = await ref
            .watch(notificationRepositoryProvider)
            .list(NotificationTab.all);
        return page.unread;
      } on ApiFailure {
        return 0;
      }
    }, retry: (_, _) => null);

/// Cuenta los push que llegan con la app abierta (para recargar las listas).
final pushArrivedProvider = NotifierProvider<PushArrived, int>(PushArrived.new);

/// Contador de push recibidos.
class PushArrived extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// La ruta de la pantalla de arriba (tambien si se abrio con `push`).
String currentPath(GoRouter router) {
  final config = router.routerDelegate.currentConfiguration;
  final last = config.lastOrNull;
  return last is ImperativeRouteMatch ? last.matches.uri.path : config.uri.path;
}

/// La ruta que abre un aviso, o `null` si no hay donde ir.
String? routeFor(NotificationTarget target, String id) => switch (target) {
  NotificationTarget.conversation when id.isNotEmpty => AppRoutes.conversation(
    id,
  ),
  NotificationTarget.order when id.isNotEmpty => AppRoutes.order(id),
  // HU-30: "Mis solicitudes" con esa solicitud y sus ofertas.
  NotificationTarget.wanted => AppRoutes.myWantedRequest(id),
  // HU-19: el tablero con "Yo tengo este producto" de esa solicitud.
  NotificationTarget.wantedBoard when id.isNotEmpty => AppRoutes.wantedOffer(
    id,
  ),
  _ => null,
};

/// Si ya se pregunto por el permiso de avisos en este telefono (L-16f: se
/// pregunta una vez, en contexto).
abstract interface class PushAskStore {
  Future<bool> asked();

  Future<void> markAsked();
}

/// En el almacen cifrado del sistema, como la sesion.
class SecurePushAskStore implements PushAskStore {
  new([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const key = 'musubi.push_asked';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> asked() async => await _storage.read(key: key) == '1';

  @override
  Future<void> markAsked() => _storage.write(key: key, value: '1');
}

/// El registro de la pregunta del permiso. En pruebas, uno en memoria.
final pushAskStoreProvider = Provider<PushAskStore>(
  (ref) => SecurePushAskStore(),
);

/// Enciende los avisos push mientras la app vive (HU-31):
/// - con sesion y permiso, registra el telefono (su ID de instalacion de
///   FCM) en la API, tambien cada vez que cambia;
/// - al cerrar sesion, da de baja el telefono en FCM;
/// - al tocar un push, abre lo que corresponde y lo marca leido;
/// - con la app abierta, muestra el aviso como snack (salvo en ese chat).
final pushCoordinatorProvider = Provider<PushCoordinator>((ref) {
  final coordinator = PushCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  unawaited(coordinator.start());
  return coordinator;
});

/// Ver [pushCoordinatorProvider].
class PushCoordinator {
  new(this._ref);

  final Ref _ref;
  final List<StreamSubscription<Object>> _subscriptions = [];
  bool _ready = false;

  PushService get _push => _ref.read(pushServiceProvider);

  Future<void> start() async {
    _ready = await _push.start();
    if (!_ready) return;
    _ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next is SignedIn && previous is! SignedIn) {
        unawaited(register());
      } else if (next is! SignedIn && previous is SignedIn) {
        unawaited(_push.unregister());
      }
    });
    // Subscribirse antes de register(): FCM entrega aqui el ID al registrar,
    // al iniciar y cada vez que cambia.
    _subscriptions
      ..add(_push.installations.listen((id) => unawaited(_send(id))))
      ..add(_push.opened.listen(open))
      ..add(_push.foreground.listen(arrived));
    await register();
    final initial = await _push.initial();
    if (initial != null) open(initial);
  }

  /// Con sesion y permiso, registra este telefono en FCM (el ID llega por
  /// `installations` y se manda a la API).
  Future<void> register() async {
    if (!_ready || _ref.read(sessionControllerProvider) is! SignedIn) return;
    if (!await _push.permitted()) return;
    await _push.register();
  }

  Future<void> _send(String installationId) async {
    if (_ref.read(sessionControllerProvider) is! SignedIn) return;
    try {
      await _ref
          .read(notificationRepositoryProvider)
          .registerDevice(installationId);
    } on ApiFailure {
      // Sin red: se reintenta con el siguiente inicio de la app.
      return;
    }
  }

  /// Si toca preguntar por el permiso: hay Firebase, nunca se pregunto y
  /// Android todavia no lo da.
  Future<bool> shouldAsk() async {
    if (!_ready) return false;
    if (await _ref.read(pushAskStoreProvider).asked()) return false;
    return !await _push.permitted();
  }

  /// Pide el permiso del sistema (una sola vez) y, si lo da, registra.
  Future<void> request() async {
    await _ref.read(pushAskStoreProvider).markAsked();
    if (await _push.requestPermission()) await register();
  }

  /// "Ahora no": no se vuelve a preguntar.
  Future<void> decline() => _ref.read(pushAskStoreProvider).markAsked();

  /// Toca un push: abre lo que corresponde y lo marca leido.
  void open(PushOpen push) {
    final route = routeFor(push.target, push.targetId);
    if (push.notificationId case final id?) {
      unawaited(
        _ref
            .read(notificationRepositoryProvider)
            .markRead(id)
            .catchError((Object _) {}),
      );
    }
    _ref.read(pushArrivedProvider.notifier).bump();
    if (route != null) unawaited(_ref.read(routerProvider).push(route));
  }

  /// Llega un push con la app abierta.
  void arrived(PushOpen push) {
    _ref.read(pushArrivedProvider.notifier).bump();
    final router = _ref.read(routerProvider);
    final route = routeFor(push.target, push.targetId);
    final here = currentPath(router);
    // En el chat abierto el mensaje ya se ve.
    if (route != null && here == route) return;
    final messenger = _ref.read(scaffoldMessengerKeyProvider).currentState;
    final title = push.title;
    if (messenger == null || title == null) return;
    showMusubiSnack(
      messenger,
      push.body == null ? title : '$title: ${push.body}',
      icon: MusubiIcons.bell,
      tone: SnackTone.info,
      actionLabel: route == null ? null : 'Ver',
      onAction: route == null ? null : () => unawaited(router.push(route)),
      duration: const Duration(seconds: 4),
    );
  }

  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
  }
}
