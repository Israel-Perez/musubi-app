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
    const approved = {
      'android.permission.INTERNET',
      // HU-31: avisos push, pedido en contexto (askForPushInContext).
      'android.permission.POST_NOTIFICATIONS',
      // HU-52: escanear el QR del apartado, pedido al abrir la camara.
      'android.permission.CAMERA',
    };
    final declared = RegExp('uses-permission[^>]*android:name="([^"]+)"')
        .allMatches(manifest)
        .map((m) => m.group(1))
        .toSet();

    expect(declared.difference(approved), isEmpty, reason: '$declared');
    // HU-52: la camara no es requisito para instalar (se escribe el codigo).
    expect(
      manifest,
      contains(
        '<uses-feature android:name="android.hardware.camera" '
        'android:required="false" />',
      ),
    );
  });

  test('Crashlytics arranca apagado (SCRUM-108): solo la app lo enciende en '
      'release', () {
    expect(
      RegExp(
        r'firebase_crashlytics_collection_enabled"\s+android:value="false"',
      ).hasMatch(manifest),
      isTrue,
    );
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

  test('debug y profile: HTTP en claro solo hacia la PC de desarrollo', () {
    for (final variant in ['debug', 'profile']) {
      final config = read(
        'android/app/src/$variant/res/xml/network_security_config.xml',
      );
      final domains = RegExp('<domain[^>]*>([^<]+)</domain>')
          .allMatches(config)
          .map((m) => m.group(1)!.trim())
          .toSet();

      expect(domains, {'10.0.2.2', 'localhost'}, reason: variant);
      expect(
        config,
        contains('<base-config cleartextTrafficPermitted="false"'),
      );
    }
  });

  test('App Links (HU-61): solo https://musubiapp.com.mx/p/ y verificado', () {
    final filters = RegExp(
      '<intent-filter[^>]*>(.*?)</intent-filter>',
      dotAll: true,
    ).allMatches(manifest).map((m) => m.group(0)!).toList();
    final views = filters
        .where((f) => f.contains('android.intent.action.VIEW'))
        .toList();

    // Un solo filtro de enlaces, verificado con assetlinks.json de la landing.
    expect(views, hasLength(1));
    final links = views.single;
    expect(links, contains('android:autoVerify="true"'));
    expect(links, contains('android.intent.category.BROWSABLE'));
    final data = RegExp('<data([^>]*)/>').allMatches(links).toList();
    expect(data, hasLength(1));
    final attrs = data.single.group(1)!;
    expect(attrs, contains('android:scheme="https"'));
    expect(attrs, contains('android:host="musubiapp.com.mx"'));
    expect(attrs, contains('android:pathPrefix="/p/"'));
    // Nunca http ni un esquema propio que cualquier app podria usar.
    expect(manifest, isNot(contains('android:scheme="http"')));
    expect(RegExp('android:scheme="(?!https")').hasMatch(manifest), isFalse);
  });

  test('ningun archivo de Firebase o de firma versionado', () {
    final tracked = Process.runSync('git', ['ls-files']).stdout as String;

    expect(tracked, isNot(contains('google-services.json')));
    expect(tracked, isNot(contains('key.properties')));
    expect(tracked, isNot(contains('.jks')));
  });
}
