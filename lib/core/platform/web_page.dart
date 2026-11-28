import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Las paginas de la landing que la app enlaza (lineamiento 16: el aviso de
/// privacidad y el manejo de datos, enlazados a la landing; SCRUM-127).
abstract final class LandingPages {
  static const origin = 'https://musubiapp.com.mx';
  static const privacy = '$origin/privacidad';
  static const terms = '$origin/terminos';

  /// Solo se abren paginas de la landing, por HTTPS.
  static bool allowed(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'musubiapp.com.mx' &&
        uri.userInfo.isEmpty &&
        !uri.hasPort;
  }
}

/// Abre una pagina de la landing en el navegador del telefono. En Android es
/// un `Intent.ACTION_VIEW` (`MainActivity.kt`, canal `musubi/web`), sin
/// paquete ni permisos; el lado nativo vuelve a revisar el dominio.
abstract interface class WebPage {
  /// `false` si la direccion no es de la landing o no hay navegador.
  Future<bool> open(String url);
}

class PlatformWebPage implements WebPage {
  const new();

  static const _channel = MethodChannel('musubi/web');

  @override
  Future<bool> open(String url) async {
    if (!LandingPages.allowed(url)) return false;
    try {
      return await _channel.invokeMethod<bool>('open', {'url': url}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// En pruebas, un fake.
final webPageProvider = Provider<WebPage>((ref) => const PlatformWebPage());
