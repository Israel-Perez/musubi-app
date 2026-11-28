import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/platform/web_page.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/features/auth/presentation/legal_screens.dart';

import '../../../helpers/fake_web_page.dart';

// SCRUM-127 (lineamiento 16): el aviso de privacidad y los terminos de la app
// enlazan a sus paginas en la landing, y solo se abren paginas de la landing.
void main() {
  late FakeWebPage web;

  Future<void> open(WidgetTester tester, Widget screen) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          webPageProvider.overrideWithValue(web),
          // rootBundle guarda la carga entre pruebas: un texto fijo la evita.
          legalDocumentProvider.overrideWith(
            (ref, asset) async => 'Texto del documento.',
          ),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapLink(WidgetTester tester, String label) async {
    final link = find.bySemanticsLabel('Abrir $label');
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    // El aviso de "sin navegador" tiene su propia animacion: un momento basta.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  setUp(() => web = FakeWebPage());

  testWidgets('el aviso de privacidad abre su pagina en la landing', (
    tester,
  ) async {
    await open(tester, const PrivacyNoticeScreen());

    await tapLink(tester, 'musubiapp.com.mx/privacidad');

    expect(web.opened, ['https://musubiapp.com.mx/privacidad']);
  });

  testWidgets('los terminos abren su pagina en la landing', (tester) async {
    await open(tester, const TermsScreen());

    await tapLink(tester, 'musubiapp.com.mx/terminos');

    expect(web.opened, ['https://musubiapp.com.mx/terminos']);
  });

  testWidgets('sin navegador, dice a donde ir', (tester) async {
    web.result = false;
    await open(tester, const PrivacyNoticeScreen());

    await tapLink(tester, 'musubiapp.com.mx/privacidad');

    expect(
      find.text(
        'No pudimos abrir el navegador. Visita musubiapp.com.mx/privacidad',
      ),
      findsOneWidget,
    );
  });

  test('solo se abren paginas de la landing por HTTPS', () {
    expect(LandingPages.allowed(LandingPages.privacy), isTrue);
    expect(LandingPages.allowed(LandingPages.terms), isTrue);
    for (final url in [
      'http://musubiapp.com.mx/privacidad',
      'https://musubiapp.com.mx.evil.example/privacidad',
      'https://evil.example/?musubiapp.com.mx',
      'https://user@musubiapp.com.mx/privacidad',
      'https://musubiapp.com.mx:8443/privacidad',
      'javascript:alert(1)',
      '',
    ]) {
      expect(LandingPages.allowed(url), isFalse, reason: url);
    }
  });

  test('sin el canal nativo, una pagina ajena ni se intenta', () async {
    expect(
      await const PlatformWebPage().open('https://evil.example/'),
      isFalse,
    );
  });
}
