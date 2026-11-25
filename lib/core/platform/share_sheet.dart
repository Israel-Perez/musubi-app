import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lo que se comparte: el texto (con el enlace) y el asunto para correo.
class ShareText {
  const new({required this.text, required this.subject});

  final String text;
  final String subject;
}

/// "Compartir" (HU-61). En Android abre la hoja del sistema
/// (`Intent.ACTION_SEND` con `createChooser`, en `MainActivity.kt`): la
/// persona elige WhatsApp u otra app. Sin paquete ni permisos.
abstract interface class ShareSheet {
  /// `false` si no hay ninguna app que lo reciba.
  Future<bool> share(ShareText content);
}

class PlatformShareSheet implements ShareSheet {
  const new();

  static const _channel = MethodChannel('musubi/share');

  @override
  Future<bool> share(ShareText content) async {
    try {
      return await _channel.invokeMethod<bool>('shareText', {
            'text': content.text,
            'subject': content.subject,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// En pruebas, un fake.
final shareSheetProvider = Provider<ShareSheet>(
  (ref) => const PlatformShareSheet(),
);
