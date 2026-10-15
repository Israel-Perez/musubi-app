import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ambientes soportados por `--dart-define-from-file=config/<ambiente>.json`.
enum AppEnvironment { dev, staging, prod }

/// Configuracion de la app leida de `--dart-define` (01-04).
///
/// Cada valor de aqui queda dentro del APK y es publico: solo la URL base de la
/// API y banderas. Nunca llaves privadas (00-04).
@immutable
class AppConfig {
  const new _({required this.environment, required this.apiBaseUrl});

  /// Valida y construye la configuracion. Lanza [AppConfigException] si:
  /// - el ambiente no es `dev`, `staging` ni `prod`;
  /// - la URL no es absoluta o su esquema no es http/https;
  /// - fuera de `dev` la URL no usa HTTPS (RNF-02);
  /// - en `dev` se usa HTTP hacia un host que no es local.
  factory parse({required String environment, required String apiBaseUrl}) {
    final env = AppEnvironment.values.asNameMap()[environment];
    if (env == null) {
      throw AppConfigException(
        'ENV invalido: "$environment" (usa dev, staging o prod).',
      );
    }

    final uri = Uri.tryParse(apiBaseUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const AppConfigException(
        'API_BASE_URL debe ser una URL absoluta '
        '(ver config/README.md).',
      );
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw AppConfigException('Esquema no soportado: ${uri.scheme}.');
    }
    if (uri.scheme == 'http') {
      if (env != AppEnvironment.dev) {
        throw AppConfigException(
          'Fuera de dev, API_BASE_URL debe usar HTTPS (RNF-02); '
          'ambiente: ${env.name}.',
        );
      }
      if (!localDevHosts.contains(uri.host)) {
        throw AppConfigException(
          'HTTP solo se permite hacia el equipo local '
          '(${localDevHosts.join(', ')}).',
        );
      }
    }

    final normalized = uri.replace(
      path: uri.path.endsWith('/')
          ? uri.path.substring(0, uri.path.length - 1)
          : uri.path,
    );
    return AppConfig._(environment: env, apiBaseUrl: normalized);
  }

  /// Lee `ENV` y `API_BASE_URL` definidos al compilar.
  factory fromEnvironment() => AppConfig.parse(
    environment: const String.fromEnvironment('ENV', defaultValue: 'dev'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
  );

  /// Hosts a los que `dev` puede hablar por HTTP. `10.0.2.2` es la PC vista
  /// desde el emulador de Android y coincide con la excepcion de
  /// `network_security_config.xml` de debug.
  static const localDevHosts = <String>{'10.0.2.2', 'localhost', '127.0.0.1'};

  final AppEnvironment environment;
  final Uri apiBaseUrl;
}

/// Configuracion invalida: es un error de quien compila, no del usuario.
class AppConfigException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}

/// Se sobrescribe en `main()` con la configuracion ya validada.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError(
    'appConfigProvider debe sobrescribirse en main() o en la prueba.',
  ),
);
