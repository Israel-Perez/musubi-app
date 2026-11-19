import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/integration/support/live_api.dart';
import 'flows/account_flow.dart';
import 'flows/explore_flow.dart';
import 'flows/sell_flow.dart';
import 'flows/start_flow.dart';

/// Suite automatizada en un telefono fisico (02-10, SCRUM-120): las pantallas
/// reales de la app contra musubi-api en la PC.
///
/// ```powershell
/// pwsh scripts/run_device_tests.ps1
/// ```
///
/// Un solo archivo para compilar e instalar la app una sola vez; cada flujo
/// vive en `flows/`. Sin `MUSUBI_API_URL` (fuera del script) se salta.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Musubi en el telefono', skip: liveSkip, () {
    startFlow();
    accountFlow();
    exploreFlow();
    sellFlow();
  });
}
