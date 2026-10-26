import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/widgets/musubi_logo.dart';

// SCRUM-81: splash animado de ~1.5 s sobre la app (que ya se construye
// debajo); con "reducir animaciones", solo un fundido corto.
void main() {
  Future<void> pumpSplash(
    WidgetTester tester, {
    bool reduced = false,
    bool enabled = true,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [brandSplashEnabledProvider.overrideWithValue(enabled)],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: BrandSplash(child: child!),
        ),
        home: Scaffold(
          body: Center(
            child: TextButton(
              onPressed: onTap ?? () {},
              child: const Text('Inicio'),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('muestra el logo y se retira a los ~1.5 s', (tester) async {
    await pumpSplash(tester);

    expect(find.byKey(const Key('brand-splash')), findsOneWidget);
    expect(find.byType(MusubiRings), findsOneWidget);
    // La app ya existe debajo: el splash no retrasa la carga.
    expect(find.text('Inicio'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(const Key('brand-splash')), findsOneWidget);
    expect(find.text('Musubi'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byKey(const Key('brand-splash')), findsNothing);
  });

  testWidgets('mientras se ve, no deja tocar la app', (tester) async {
    var taps = 0;
    await pumpSplash(tester, onTap: () => taps++);

    await tester.tap(find.text('Inicio'), warnIfMissed: false);
    expect(taps, 0);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Inicio'));
    expect(taps, 1);
  });

  testWidgets('con "reducir animaciones" dura 600 ms', (tester) async {
    await pumpSplash(tester, reduced: true);

    expect(find.byKey(const Key('brand-splash')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump();
    expect(find.byKey(const Key('brand-splash')), findsNothing);
  });

  testWidgets('apagado (pruebas): no aparece', (tester) async {
    await pumpSplash(tester, enabled: false);

    expect(find.byKey(const Key('brand-splash')), findsNothing);
  });
}
