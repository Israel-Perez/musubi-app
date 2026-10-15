import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/core/config/app_config.dart';

/// Ejecutar con: flutter run --dart-define-from-file=config/dev.json
///
/// NOTE (02-01): Firebase Crashlytics. NOTE (HU-31): Firebase Messaging.
/// NOTE (HU-20): cliente SignalR para chat y avisos dentro de la app.
void main() {
  // Falla rapido si la configuracion de compilacion es invalida (01-04).
  final config = AppConfig.fromEnvironment();
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const MusubiApp(),
    ),
  );
}
