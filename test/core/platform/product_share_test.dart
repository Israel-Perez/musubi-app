import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/platform/product_share.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('musubi/share');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('envía el texto y título del chooser al canal nativo (HU-61)', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return true;
        });

    final result = await const PlatformProductShareLauncher().share(
      'Calculadora · \$450\nhttps://musubiapp.com.mx/p/p1',
    );

    expect(result, isTrue);
    expect(received?.method, 'shareText');
    expect(received?.arguments, {
      'text': 'Calculadora · \$450\nhttps://musubiapp.com.mx/p/p1',
      'chooserTitle': 'Compartir con',
    });
  });

  test(
    'si el canal nativo no está disponible, no propaga la excepción',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'unavailable');
          });

      expect(
        await const PlatformProductShareLauncher().share('texto'),
        isFalse,
      );
    },
  );
}
