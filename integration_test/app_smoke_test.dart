import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/domain/status_repository.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

// Esqueleto de pruebas de integracion (01-05). Corre en un emulador o un
// dispositivo: flutter test integration_test --dart-define-from-file=...
// No corre en el CI de PR (requiere un dispositivo); los flujos de cada HU
// se agregan aqui cuando existan.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la app arranca y muestra la pantalla inicial', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statusRepositoryProvider.overrideWithValue(_OnlineRepository()),
        ],
        child: const MusubiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Musubi'), findsOneWidget);
    expect(find.text('Servidor conectado'), findsOneWidget);
  });
}

class _OnlineRepository implements StatusRepository {
  @override
  Future<ApiStatus> check() async => const ApiOnline(version: 'v1');
}
