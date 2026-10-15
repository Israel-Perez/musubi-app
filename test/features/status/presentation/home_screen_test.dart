import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/home_screen.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../../../helpers/fake_status_repository.dart';

// 01-03: pantalla inicial "Musubi" (humo). Nunca se rompe si la API falla.
void main() {
  Future<void> pumpHome(WidgetTester tester, FakeStatusRepository fake) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [statusRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

  testWidgets('muestra "Conectando" mientras consulta', (tester) async {
    await pumpHome(tester, FakeStatusRepository.pending());

    expect(find.text('Musubi'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Conectando con el servidor…'), findsOneWidget);
  });

  testWidgets('API en linea: muestra servidor conectado y version', (
    tester,
  ) async {
    await pumpHome(
      tester,
      FakeStatusRepository([const ApiOnline(version: 'v1')]),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('status-online')), findsOneWidget);
    expect(find.text('Servidor conectado'), findsOneWidget);
    expect(find.text('API v1'), findsOneWidget);
  });

  testWidgets('API caida: muestra el motivo y permite reintentar', (
    tester,
  ) async {
    final fake = FakeStatusRepository([
      const ApiOffline(message: 'No hay conexión con el servidor.'),
      const ApiOnline(version: 'v1'),
    ]);
    await pumpHome(tester, fake);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('status-offline')), findsOneWidget);
    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(fake.calls, 2);
    expect(find.text('Servidor conectado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
