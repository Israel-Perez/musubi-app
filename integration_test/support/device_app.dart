import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/platform/app_review.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/session/token_store.dart';
import 'package:musubi_app/features/listings/data/photo_picker.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/notifications/presentation/notification_providers.dart';

import '../../test/helpers/fake_app_review.dart';
import '../../test/helpers/fake_notifications.dart';
import '../../test/helpers/in_memory_token_store.dart';
import '../../test/integration/support/live_api.dart';

/// La app real en el telefono (02-10): mismas pantallas, router y repositorios
/// HTTP que en Play, contra musubi-api en la PC (`adb reverse`).
///
/// Solo se cambia lo que una prueba no puede manejar en el telefono: el
/// selector de fotos de Android (una foto generada), el permiso de avisos push
/// (sin FCM), la ventana de resenas de Play y la animacion de la marca.
class DeviceApp {
  new _(this.tester, this.container);

  final WidgetTester tester;
  final ProviderContainer container;

  /// Abre la app como si se tocara el icono: con [tokens] guardados entra con
  /// sesion (L-16g); sin ellos, como visitante.
  static Future<DeviceApp> open(
    WidgetTester tester, {
    SessionTokens? tokens,
    TokenStore? store,
    String? at,
  }) async {
    // Cierra la app anterior (si la hay): reabrir es empezar de cero, como al
    // tocar el icono otra vez; solo queda lo que este en el almacen.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.parse(environment: 'dev', apiBaseUrl: liveApiUrl),
          ),
          tokenStoreProvider.overrideWithValue(
            store ?? InMemoryTokenStore(tokens),
          ),
          initialSessionTokensProvider.overrideWithValue(tokens),
          photoPickerProvider.overrideWithValue(_GeneratedPhotos()),
          pushServiceProvider.overrideWithValue(
            FakePushService(available: false),
          ),
          appReviewProvider.overrideWithValue(FakeAppReview()),
          brandSplashEnabledProvider.overrideWithValue(false),
        ],
        child: const MusubiApp(),
      ),
    );
    final app = DeviceApp._(
      tester,
      ProviderScope.containerOf(tester.element(find.byType(MusubiApp))),
    );
    if (at != null) app.go(at);
    await app.settle();
    return app;
  }

  SessionState get session => container.read(sessionControllerProvider);

  void go(String location) => container.read(routerProvider).go(location);

  /// Deja correr la red real y las animaciones un momento.
  Future<void> settle([
    Duration duration = const Duration(milliseconds: 500),
  ]) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Espera a que aparezca (la API real tarda; `pumpAndSettle` no espera a la
  /// red y se cuelga con los indicadores de carga).
  Future<Finder> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 150));
      if (finder.evaluate().isNotEmpty) return finder;
    }
    throw TestFailure('No aparecio en la pantalla: $finder');
  }

  /// Espera a que se cumpla una condicion del estado de la app.
  Future<void> waitUntil(
    bool Function() condition, {
    String reason = 'la condicion',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 150));
      if (condition()) return;
    }
    throw TestFailure('No se cumplio $reason');
  }

  Future<void> see(String text) => waitFor(find.text(text));

  /// `Inicio` termino de cargar desde la API (sin el indicador ni el error).
  Future<void> waitForHome() async {
    await waitFor(find.text('Inicio'));
    await waitUntil(
      () =>
          find.byKey(const Key('home-loading')).evaluate().isEmpty &&
          find.byKey(const Key('home-error')).evaluate().isEmpty &&
          find.byKey(const Key('home-enter')).evaluate().isNotEmpty !=
              session is SignedIn,
      reason: 'que Inicio cargue',
    );
  }

  Future<void> seeContaining(String text) => waitFor(find.textContaining(text));

  /// Lo busca y, si no esta dibujado (una lista larga solo dibuja lo visible),
  /// desplaza la pantalla hacia abajo hasta encontrarlo.
  Future<Finder> reveal(Finder finder) async {
    try {
      return await waitFor(finder, timeout: const Duration(seconds: 4));
    } on TestFailure {
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) rethrow;
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: scrollable.last,
        maxScrolls: 40,
      );
      return await waitFor(finder);
    }
  }

  Future<void> tap(Finder finder) async {
    await reveal(finder);
    final target = finder.last;
    await tester.ensureVisible(target);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(target);
    await settle();
  }

  Future<void> tapText(String text) => tap(find.text(text));

  Future<void> tapKey(String key) => tap(find.byKey(Key(key)));

  Future<void> tapLabel(String label) => tap(find.bySemanticsLabel(label));

  Future<void> type(String key, String text) async {
    final field = await reveal(find.byKey(Key(key)));
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await settle(const Duration(milliseconds: 300));
  }

  /// La tecla de accion del teclado (Buscar, Enviar).
  Future<void> submit() async {
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle();
  }

  /// Texto de un `Text` con esa llave.
  Future<String> textOf(String key) async {
    final found = await waitFor(find.byKey(Key(key)));
    final widget = found.evaluate().first.widget;
    if (widget is Text) return widget.data ?? '';
    final text = find.descendant(of: found, matching: find.byType(Text));
    return tester.widget<Text>(text.first).data ?? '';
  }
}

/// La camara y la galeria de Android no se pueden tocar desde una prueba: la
/// "foto" es un PNG generado en el telefono (400 x 300).
class _GeneratedPhotos implements PhotoPicker {
  @override
  Future<String?> takePhoto() async => livePhoto().path;

  @override
  Future<List<String>> pickFromGallery({required int max}) async => [
    livePhoto(green: 90).path,
  ];
}
