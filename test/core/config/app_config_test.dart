import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/config/app_config.dart';

// 01-04: configuracion por ambiente y HTTPS obligatorio fuera de dev (RNF-02).
void main() {
  group('AppConfig.parse', () {
    test('dev acepta HTTP hacia el host del emulador', () {
      final config = AppConfig.parse(
        environment: 'dev',
        apiBaseUrl: 'http://10.0.2.2:5080',
      );

      expect(config.environment, AppEnvironment.dev);
      expect(config.apiBaseUrl.host, '10.0.2.2');
      expect(config.apiBaseUrl.port, 5080);
    });

    test('staging y prod aceptan HTTPS y quitan la barra final', () {
      final config = AppConfig.parse(
        environment: 'prod',
        apiBaseUrl: 'https://api.musubi.example/',
      );

      expect(config.environment, AppEnvironment.prod);
      expect(config.apiBaseUrl.toString(), 'https://api.musubi.example');
    });

    test('fuera de dev rechaza HTTP (RNF-02)', () {
      expect(
        () => AppConfig.parse(
          environment: 'staging',
          apiBaseUrl: 'http://api.musubi.example',
        ),
        throwsA(
          isA<AppConfigException>().having(
            (e) => e.message,
            'message',
            contains('HTTPS'),
          ),
        ),
      );
    });

    test('dev rechaza HTTP hacia un host que no es local', () {
      expect(
        () => AppConfig.parse(
          environment: 'dev',
          apiBaseUrl: 'http://api.musubi.example',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rechaza una URL vacia o relativa', () {
      for (final url in ['', '/api', 'api.musubi.example']) {
        expect(
          () => AppConfig.parse(environment: 'dev', apiBaseUrl: url),
          throwsA(isA<AppConfigException>()),
          reason: 'URL: "$url"',
        );
      }
    });

    test('rechaza un ambiente desconocido', () {
      expect(
        () => AppConfig.parse(
          environment: 'production',
          apiBaseUrl: 'https://api.musubi.example',
        ),
        throwsA(
          isA<AppConfigException>().having(
            (e) => e.message,
            'message',
            contains('ENV invalido'),
          ),
        ),
      );
    });

    test('rechaza esquemas distintos de http/https', () {
      expect(
        () => AppConfig.parse(environment: 'dev', apiBaseUrl: 'ftp://10.0.2.2'),
        throwsA(isA<AppConfigException>()),
      );
    });

    // SCRUM-82: la vitrina de muestra nunca llega a staging ni a prod.
    test('DEMO_CATALOG solo en dev', () {
      final dev = AppConfig.parse(
        environment: 'dev',
        apiBaseUrl: 'https://d1.cloudfront.example',
        demoCatalog: true,
      );
      expect(dev.demoCatalog, isTrue);
      expect(
        AppConfig.parse(
          environment: 'dev',
          apiBaseUrl: 'http://10.0.2.2:5080',
        ).demoCatalog,
        isFalse,
      );

      for (final env in ['staging', 'prod']) {
        expect(
          () => AppConfig.parse(
            environment: env,
            apiBaseUrl: 'https://api.musubi.example',
            demoCatalog: true,
          ),
          throwsA(
            isA<AppConfigException>().having(
              (e) => e.message,
              'message',
              contains('DEMO_CATALOG'),
            ),
          ),
          reason: env,
        );
      }
    });
  });
}
