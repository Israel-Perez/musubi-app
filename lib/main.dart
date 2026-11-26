import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/observability/crash_reporter.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/session/token_store.dart';

/// Ejecutar con: flutter run --dart-define-from-file=config/dev.json
///
/// Firebase Crashlytics (SCRUM-108) se enciende aqui, solo en release; los
/// avisos push (HU-31) los enciende `pushCoordinatorProvider`.
/// Chat en tiempo real (HU-20): `chatConnectionProvider`, al abrir `Mensajes`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Falla rapido si la configuracion de compilacion es invalida (01-04).
  final config = AppConfig.fromEnvironment();

  // Licencias de lo empaquetado en la pantalla de licencias: la fuente
  // (OFL 1.1) y los iconos de la maqueta (Lucide, ISC).
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Plus Jakarta Sans',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'Lucide',
    ], await rootBundle.loadString('assets/licenses/lucide.txt'));
  });

  // SCRUM-108: los fallos no controlados van a Crashlytics, sin datos
  // personales (solo en release y con google-services.json).
  final crashes = FirebaseCrashReporter();
  await crashes.start();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      crashes.record(
        details.exception,
        details.stack,
        fatal: true,
        reason: details.context?.toDescription(),
      ),
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(crashes.record(error, stack, fatal: true));
    return true;
  };

  // La sesion se lee antes de pintar: la app nunca muestra un estado "cargando
  // sesion" ni redirige dos veces al abrir (L-16g).
  final store = SecureTokenStore();
  final tokens = await _readSession(store);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        crashReporterProvider.overrideWithValue(crashes),
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
