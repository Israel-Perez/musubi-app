@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/flows/account_flow.dart';
import '../../integration_test/flows/explore_flow.dart';
import '../../integration_test/flows/sell_flow.dart';
import '../../integration_test/flows/start_flow.dart';
import 'support/live_api.dart';

/// Ensayo de la suite del telefono (`integration_test/`) en la VM (02-10):
/// los mismos flujos de pantallas, con frames y tiempo reales, contra la API.
/// Asi el CI avisa si un cambio de pantalla rompe la suite que se corre en el
/// telefono con `scripts/run_device_tests.ps1`.
void main() {
  final binding = LiveTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  // El binding de pruebas simula la red; estos flujos usan la API real.
  HttpOverrides.global = null;
  setUp(
    () => binding.platformDispatcher.implicitView!
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3,
  );
  tearDown(() => binding.platformDispatcher.implicitView!.reset());

  group('Suite del telefono en la VM', skip: liveSkip, () {
    startFlow();
    accountFlow();
    exploreFlow();
    sellFlow();
  });
}
