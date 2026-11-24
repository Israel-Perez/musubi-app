import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/network/offline_cache.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/widgets/offline_banner.dart';

/// HU-63: "Sin conexión · lo que ves puede no estar al día" sale mientras la
/// ultima peticion no llego a la API y se va al volver la red.
void main() {
  testWidgets('sale sin conexion y se quita al volver la red', (tester) async {
    final container = ProviderContainer.test();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: OfflineBanner()),
        ),
      ),
    );

    expect(find.byKey(const Key('offline-banner')), findsNothing);
    container.read(offlineProvider.notifier).set(offline: true);
    await tester.pumpAndSettle();
    expect(
      find.text('Sin conexión · lo que ves puede no estar al día'),
      findsOneWidget,
    );

    container.read(offlineProvider.notifier).set(offline: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offline-banner')), findsNothing);
  });
}
