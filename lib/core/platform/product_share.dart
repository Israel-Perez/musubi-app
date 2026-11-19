import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre la hoja nativa para compartir texto (HU-61).
abstract interface class ProductShareLauncher {
  Future<bool> share(String text);
}

/// Puente Android `musubi/share`; en otros targets responde como no disponible.
class PlatformProductShareLauncher implements ProductShareLauncher {
  const new();

  static const _channel = MethodChannel('musubi/share');

  @override
  Future<bool> share(String text) async {
    try {
      return await _channel.invokeMethod<bool>('shareText', {
            'text': text,
            'chooserTitle': 'Compartir con',
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final productShareLauncherProvider = Provider<ProductShareLauncher>(
  (ref) => const PlatformProductShareLauncher(),
);
