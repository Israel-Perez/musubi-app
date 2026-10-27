import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre la bandeja de la app de correo del telefono ("Abrir mi correo" de la
/// maqueta `Verificacion`). En Android es un `Intent` de la categoria
/// `APP_EMAIL` (`MainActivity.kt`): sin permisos ni datos de la persona.
abstract interface class EmailInbox {
  /// `false` si no hay una app de correo que lo abra.
  Future<bool> open();
}

class PlatformEmailInbox implements EmailInbox {
  const new();

  static const _channel = MethodChannel('musubi/email');

  @override
  Future<bool> open() async {
    try {
      return await _channel.invokeMethod<bool>('openInbox') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// En pruebas, un fake.
final emailInboxProvider = Provider<EmailInbox>(
  (ref) => const PlatformEmailInbox(),
);
