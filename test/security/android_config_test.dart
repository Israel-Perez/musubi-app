import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

// 02-01 / L-07 / MASVS: pruebas de seguridad de la configuracion de Android.
// Un cambio que abra permisos, backup o trafico en claro rompe el CI.
void main() {
  final manifest = read('android/app/src/main/AndroidManifest.xml');

  test('sin backup: los datos de la app no salen del dispositivo', () {
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, isNot(contains('android:fullBackupContent="true"')));
  });

  test('solo los permisos aprobados (se piden en contexto, 02-01)', () {
    const approved = {'android.permission.INTERNET'};
    final declared = RegExp('uses-permission[^>]*android:name="([^"]+)"')
        .allMatches(manifest)
        .map((m) => m.group(1))
        .toSet();

    expect(declared.difference(approved), isEmpty, reason: '$declared');
  });

  test('release: sin trafico en claro (RNF-02)', () {
    final config = read(
      'android/app/src/main/res/xml/network_security_config.xml',
    );

    expect(manifest, contains('@xml/network_security_config'));
    expect(manifest, isNot(contains('usesCleartextTraffic="true"')));
    expect(config, contains('cleartextTrafficPermitted="false"'));
    expect(config, isNot(contains('cleartextTrafficPermitted="true"')));
  });

  test('debug y profile: HTTP en claro solo hacia el emulador', () {
    for (final variant in ['debug', 'profile']) {
      final config = read(
        'android/app/src/$variant/res/xml/network_security_config.xml',
      );
      final domains = RegExp('<domain[^>]*>([^<]+)</domain>')
          .allMatches(config)
          .map((m) => m.group(1)!.trim())
          .toSet();

      expect(domains, {'10.0.2.2'}, reason: variant);
      expect(
        config,
        contains('<base-config cleartextTrafficPermitted="false"'),
      );
    }
  });

  test('ningun archivo de Firebase o de firma versionado', () {
    final tracked = Process.runSync('git', ['ls-files']).stdout as String;

    expect(tracked, isNot(contains('google-services.json')));
    expect(tracked, isNot(contains('key.properties')));
    expect(tracked, isNot(contains('.jks')));
  });
}
