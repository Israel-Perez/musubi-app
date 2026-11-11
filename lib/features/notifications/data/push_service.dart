import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';

/// Los avisos push del telefono (HU-31). Detras de una interfaz para que las
/// pruebas usen un fake y para que la app funcione sin Firebase (RNF-15).
///
/// Usa el ID de instalacion de Firebase (FID): `register()` y
/// `onRegistered`, que reemplazan al token de registro (obsoleto). La API lo
/// manda en el campo `fid` de FCM HTTP v1.
abstract interface class PushService {
  /// Inicia Firebase. `false` si no esta configurado (sin
  /// `google-services.json`): entonces nada mas hace algo.
  Future<bool> start();

  /// Si Android ya permite mostrar avisos (Android 13+ lo pregunta).
  Future<bool> permitted();

  /// Pide el permiso de avisos (en contexto, L-16f). `true` si lo dio.
  Future<bool> requestPermission();

  /// Registra este telefono en FCM; el ID llega por [installations]. Solo se
  /// llama con permiso: `register()` lo pediria si no lo hay.
  Future<void> register();

  /// El ID de instalacion cada vez que FCM lo da o lo cambia.
  Stream<String> get installations;

  /// Da de baja este telefono (al cerrar sesion: la API lo quita al primer
  /// envio que falle).
  Future<void> unregister();

  /// El push con el que se abrio la app desde cerrada, o `null`.
  Future<PushOpen?> initial();

  /// Cuando se toca un push con la app en segundo plano.
  Stream<PushOpen> get opened;

  /// Cuando llega un push con la app abierta (Android no lo muestra solo).
  Stream<PushOpen> get foreground;
}

/// [PushService] con Firebase Cloud Messaging.
class FirebasePushService implements PushService {
  bool _ready = false;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  static PushOpen _open(RemoteMessage m) => PushOpen.fromData(
    m.data,
    title: m.notification?.title,
    body: m.notification?.body,
  );

  @override
  Future<bool> start() async {
    if (_ready) return true;
    try {
      await Firebase.initializeApp();
      _ready = true;
    } on Object catch (error) {
      // Sin google-services.json (pruebas, CI de PR o un build local sin
      // Firebase): la app sigue sin avisos push.
      debugPrint('Avisos push apagados: $error');
    }
    return _ready;
  }

  @override
  Future<bool> permitted() async {
    if (!_ready) return false;
    final settings = await _fcm.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final settings = await _fcm.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<void> register() async {
    if (_ready) await _fcm.register();
  }

  @override
  Stream<String> get installations =>
      _ready ? _fcm.onRegistered : const Stream.empty();

  @override
  Future<void> unregister() async {
    if (_ready) await _fcm.unregister();
  }

  @override
  Future<PushOpen?> initial() async {
    if (!_ready) return null;
    final message = await _fcm.getInitialMessage();
    return message == null ? null : _open(message);
  }

  @override
  Stream<PushOpen> get opened => _ready
      ? FirebaseMessaging.onMessageOpenedApp.map(_open)
      : const Stream.empty();

  @override
  Stream<PushOpen> get foreground =>
      _ready ? FirebaseMessaging.onMessage.map(_open) : const Stream.empty();
}
