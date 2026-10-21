import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/session/token_store.dart';

/// Ejecutar con: flutter run --dart-define-from-file=config/dev.json
///
/// NOTE (02-06): Firebase Crashlytics. NOTE (HU-31): Firebase Messaging.
/// NOTE (HU-20): cliente SignalR para chat y avisos dentro de la app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Falla rapido si la configuracion de compilacion es invalida (01-04).
  final config = AppConfig.fromEnvironment();

  // Licencia de la fuente empaquetada (OFL 1.1) en la pantalla de licencias.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Plus Jakarta Sans',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });

  // La sesion se lee antes de pintar: la app nunca muestra un estado "cargando
  // sesion" ni redirige dos veces al abrir (L-16g).
  final store = SecureTokenStore();
  final tokens = await _readSession(store);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        tokenStoreProvider.overrideWithValue(store),
        initialSessionTokensProvider.overrideWithValue(tokens),
      ],
      child: const MusubiApp(),
    ),
  );
}

/// Un almacen danado (por ejemplo, tras restaurar el telefono) no bloquea la
/// app: se borra y se entra como visitante.
Future<SessionTokens?> _readSession(TokenStore store) async {
  try {
    return await store.read();
  } on PlatformException {
    await store.clear();
    return null;
  }
}
