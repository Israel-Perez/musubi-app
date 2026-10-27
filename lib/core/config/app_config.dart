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
  const new _({
    required this.environment,
    required this.apiBaseUrl,
    this.demoCatalog = false,
  });

  /// Valida y construye la configuracion. Lanza [AppConfigException] si:
  /// - el ambiente no es `dev`, `staging` ni `prod`;
  /// - la URL no es absoluta o su esquema no es http/https;
  /// - fuera de `dev` la URL no usa HTTPS (RNF-02);
  /// - en `dev` se usa HTTP hacia un host que no es local;
  /// - se pide el catalogo de muestra fuera de `dev`.
  factory parse({
    required String environment,
    required String apiBaseUrl,
    bool demoCatalog = false,
  }) {
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

    if (demoCatalog && env != AppEnvironment.dev) {
      throw AppConfigException(
        'DEMO_CATALOG solo se permite en dev; ambiente: ${env.name}.',
      );
    }

    final normalized = uri.replace(
      path: uri.path.endsWith('/')
          ? uri.path.substring(0, uri.path.length - 1)
          : uri.path,
    );
    return AppConfig._(
      environment: env,
      apiBaseUrl: normalized,
      demoCatalog: demoCatalog,
    );
  }

  /// Lee `ENV`, `API_BASE_URL` y `DEMO_CATALOG` definidos al compilar.
  factory fromEnvironment() => AppConfig.parse(
    environment: const String.fromEnvironment('ENV', defaultValue: 'dev'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    // ignore: avoid_redundant_argument_values, se fija al compilar.
    demoCatalog: const bool.fromEnvironment('DEMO_CATALOG'),
  );

  /// Hosts a los que `dev` puede hablar por HTTP. `10.0.2.2` es la PC vista
  /// desde el emulador de Android y coincide con la excepcion de
  /// `network_security_config.xml` de debug.
  static const localDevHosts = <String>{'10.0.2.2', 'localhost', '127.0.0.1'};

  final AppEnvironment environment;
  final Uri apiBaseUrl;

  /// Vitrina con los productos ficticios de la maqueta en lugar del catalogo
  /// de la API (solo `dev`). NOTE (HU-06): sin uso cuando haya catalogo real.
  final bool demoCatalog;
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
