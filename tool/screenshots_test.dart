// Capturas de la app para compararlas con la maqueta (SCRUM-82): cada
// pantalla a 390 x 844 puntos a 3x (otro tamano con SHOT_WIDTH/SHOT_HEIGHT),
// con Plus Jakarta Sans, sombras y fotos reales, y la barra de estado de la
// maqueta (54 arriba, 24 abajo).
//
// No corre con `flutter test` (vive en tool/). Para generarlas:
//   flutter test tool/screenshots_test.dart --dart-define=SHOTS=<carpeta>
// Opcionales: --dart-define=ONLY=inicio-visitante,registro (solo esas),
// --dart-define=DARK=true (modo noche) y --dart-define=RECTS=true (imprime la
// caja de cada texto, para compararla con la del DOM de la maqueta).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/platform/email_inbox.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/listings/data/photo_picker.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/data/demo_catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../test/helpers/fake_auth_repository.dart';
import '../test/helpers/fake_catalog_repository.dart';
import '../test/helpers/fake_listings_repository.dart';
import '../test/helpers/fake_session_api.dart';
import '../test/helpers/fake_status_repository.dart';
import '../test/helpers/in_memory_token_store.dart';

const _out = String.fromEnvironment('SHOTS');
const _only = String.fromEnvironment('ONLY');
const _dark = bool.fromEnvironment('DARK');
const _rects = bool.fromEnvironment('RECTS');

/// Tamano en pt (390 x 844 = maqueta). Google Play pide capturas 9:16:
/// 360 x 640 da 1080 x 1920 (02-02).
const _width = int.fromEnvironment('SHOT_WIDTH', defaultValue: 390);
const _height = int.fromEnvironment('SHOT_HEIGHT', defaultValue: 844);

/// Hora de la maqueta ("hace 20 min" sale igual que en el prototipo).
final _now = DateTime.utc(2026, 10, 5, 20);

const _ana = SessionProfile(
  fullName: 'Ana Sofía Ramírez',
  email: 'ana.ramirez@uttt.edu.mx',
  campus: 'UTTT',
);

final _anaUser = AuthUser(
  id: 'u1',
  fullName: _ana.fullName,
  email: _ana.email,
  emailVerified: true,
  campus: uttt,
);

/// Fotos reales para `Vender-1` (la de la maqueta, copiada a archivos).
final List<String> _photoFiles = [];

class _FilePicker implements PhotoPicker {
  @override
  Future<String?> takePhoto() async => _photoFiles.first;

  @override
  Future<List<String>> pickFromGallery({required int max}) async =>
      _photoFiles.take(max).toList();
}

class _InboxStub implements EmailInbox {
  @override
  Future<bool> open() async => true;
}

/// La app con la vitrina de muestra, lista para tomar capturas.
class _Shot {
  new(this.tester, {required this.member, CatalogRepository? catalog})
    : catalog = catalog ?? DemoCatalogRepository(() => _now);

  final WidgetTester tester;
  final bool member;
  final CatalogRepository catalog;
  final auth = FakeAuthRepository(now: _now);
  final GlobalKey _boundary = GlobalKey();
  late ProviderContainer container;

  /// Con [wait] espera a que todo se acomode (sin el: estados que animan
  /// sin fin, como el esqueleto de carga).
  Future<void> open({bool wait = true}) async {
    final tokens = member
        ? SessionTokens(
            accessToken: 'access',
            accessExpiresAt: _now.add(const Duration(minutes: 15)),
            refreshToken: 'refresh',
            profile: _ana,
          )
        : null;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: ProviderScope(
          overrides: [
            brandSplashEnabledProvider.overrideWithValue(false),
            catalogRepositoryProvider.overrideWithValue(catalog),
            authRepositoryProvider.overrideWithValue(auth),
            sessionApiProvider.overrideWithValue(FakeSessionApi()),
            clockProvider.overrideWithValue(() => _now),
            emailInboxProvider.overrideWithValue(_InboxStub()),
            listingsRepositoryProvider.overrideWithValue(
              FakeListingsRepository(
                range: const PriceRange(lowCents: 38000, highCents: 52000),
              ),
            ),
            photoPickerProvider.overrideWithValue(_FilePicker()),
            statusRepositoryProvider.overrideWithValue(
              FakeStatusRepository([const ApiOnline(version: 'v1')]),
            ),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore(tokens)),
            initialSessionTokensProvider.overrideWithValue(tokens),
          ],
          child: const MusubiApp(),
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    if (wait) {
      await settle();
    } else {
      await tester.pump(const Duration(milliseconds: 700));
      await _images();
      await tester.pump(const Duration(milliseconds: 700));
    }
  }

  Future<void> settle() async {
    await tester.pumpAndSettle();
    await _images();
    await tester.pumpAndSettle();
  }

  /// Las fotos se decodifican fuera del reloj falso de la prueba.
  Future<void> _images() async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        await precacheImage(image.image, element);
      }
    });
    await tester.pump();
  }

  Future<void> go(String location, {Object? extra}) async {
    container.read(routerProvider).go(location, extra: extra);
    await settle();
  }

  Future<void> tap(Finder finder) async {
    await tester.tap(finder.first, warnIfMissed: false);
    await settle();
  }

  Future<void> type(String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  Future<void> scroll(double offset) async {
    final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
    // Como el navegador: no pasa del final.
    state.position.jumpTo(
      offset.clamp(0, state.position.maxScrollExtent).toDouble(),
    );
    await tester.pump();
    await _images();
  }

  /// Caja de cada texto visible (en pt, como `getBoundingClientRect`).
  void printRects(String name) {
    for (final element in find.byType(RichText).evaluate()) {
      final box = element.renderObject! as RenderBox;
      if (!box.hasSize || !box.attached) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.bottom <= 0 || rect.top >= _height) continue;
      final text = (element.widget as RichText).text
          .toPlainText()
          .split('\n')
          .join(' ');
      // ignore: avoid_print, salida de la herramienta (no corre en la app).
      print(
        '$name | top ${rect.top.toStringAsFixed(3)} '
        'bottom ${rect.bottom.toStringAsFixed(3)} '
        'alto ${rect.height.toStringAsFixed(3)} '
        'x ${rect.left.toStringAsFixed(1)} | '
        '${text.characters.take(40)}',
      );
    }
  }

  Future<void> save(String name) async {
    if (_rects) printRects(name);
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }
}

typedef _Scene = Future<void> Function(_Shot shot);

/// Nombre → (con sesion, como llegar a la pantalla).
final Map<String, (bool, _Scene)> _scenes = {
  'inicio-visitante': (false, (s) async {}),
  'inicio-visitante-scroll1': (false, (s) => s.scroll(650)),
  'inicio-visitante-scroll2': (false, (s) => s.scroll(1300)),
  'inicio-visitante-scroll3': (false, (s) => s.scroll(5000)),
  'gate-guardar': (false, (s) => s.tap(find.byType(SaveButton))),
  'gate-campus': (false, (s) => s.tap(find.byKey(const Key('campus-chip')))),
  'gate-perfil': (false, (s) => s.tap(find.bySemanticsLabel('Perfil'))),
  'gate-mensajes': (false, (s) => s.tap(find.bySemanticsLabel('Mensajes'))),
  'gate-publicar': (false, (s) => s.tap(find.bySemanticsLabel('Publicar'))),
  'gate-yotengo': (
    false,
    (s) async {
      await s.scroll(1300);
      await s.tap(find.text('Yo tengo este producto'));
    },
  ),
  'filtro': (
    false,
    (s) async {
      await s.scroll(400);
      await s.tap(find.byKey(const Key('home-filter')));
    },
  ),
  'iniciar-sesion': (
    false,
    (s) async {
      await s.go(AppRoutes.signIn);
      await s.type('signin-email', 'ana.ramirez@uttt.edu.mx');
      await s.type('signin-password', 'musubi2025');
      FocusManager.instance.primaryFocus?.unfocus();
      await s.settle();
    },
  ),
  'iniciar-sesion-error': (
    false,
    (s) async {
      await s.go(AppRoutes.signIn);
      await s.type('signin-email', 'ana.ramirez@uttt.edu.mx');
      await s.type('signin-password', 'musubi2025');
      await s.tap(find.text('Iniciar sesión'));
      FocusManager.instance.primaryFocus?.unfocus();
      await s.settle();
    },
  ),
  'registro': (
    false,
    (s) async {
      await s.go(AppRoutes.signUp);
      await s.type('signup-email', 'ana.ramirez@uttt.edu.mx');
      await s.tester.pump(const Duration(milliseconds: 600));
      await s.settle();
      await s.type('signup-name', 'Ana Sofía Ramírez');
      await s.tap(find.byKey(const Key('signup-consent')));
      await s.type('signup-password', 'musubi2026');
      await s.settle();
    },
  ),
  'registro-error': (
    false,
    (s) async {
      await s.go(AppRoutes.signUp);
      await s.type('signup-email', 'ana.ramirez@gmail.com');
      await s.tester.pump(const Duration(milliseconds: 600));
      await s.settle();
      await s.type('signup-name', 'Ana Sofía Ramírez');
      await s.type('signup-password', 'musubi2026');
      await s.tap(find.byKey(const Key('signup-consent')));
      FocusManager.instance.primaryFocus?.unfocus();
      await s.settle();
    },
  ),
  'verificacion': (
    false,
    (s) async {
      await s.go(
        AppRoutes.verification,
        extra: Registration(
          email: _ana.email,
          codeExpiresAt: _now.add(const Duration(minutes: 10)),
          resendAvailableAt: _now.add(const Duration(seconds: 42)),
        ),
      );
      await s.type('verification-code', '4827');
      await s.settle();
    },
  ),
  'verificacion-lista': (
    false,
    (s) async {
      await s.go(AppRoutes.welcome, extra: _anaUser);
      await s.tester.pump(const Duration(seconds: 2));
    },
  ),
  'aviso-privacidad': (false, (s) => s.go(AppRoutes.privacy)),
  'inicio': (true, (s) async {}),
  'inicio-scroll': (true, (s) => s.scroll(5000)),
  'perfil': (true, (s) => s.tap(find.bySemanticsLabel('Perfil'))),
  'ajustes': (true, (s) => s.go(AppRoutes.settings)),
  'publicar': (true, (s) => s.tap(find.text('Publicar'))),
  'vender-1': (true, (s) => _sellTo(s, 1)),
  'vender-2': (true, (s) => _sellTo(s, 2)),
  'vender-3': (true, (s) => _sellTo(s, 3)),
  'vender-4': (true, (s) => _sellTo(s, 4)),
  'vender-listo': (true, (s) => _sellTo(s, 5)),
  'cerrar-sesion': (
    true,
    (s) async {
      await s.go(AppRoutes.settings);
      await s.tap(find.bySemanticsLabel('Cerrar sesión'));
    },
  ),
};

/// Publicar → Vender-1…4 → Vender-listo con los datos del prototipo.
Future<void> _sellTo(_Shot s, int step) async {
  final tester = s.tester;
  Future<void> quiet() async {
    // Sin el aviso breve en la captura (la maqueta no lo muestra).
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
        .removeCurrentSnackBar();
    await s.settle();
  }

  // Las fotos se leen fuera del reloj falso: si `Image.file` empieza a
  // leerlas dentro de la prueba, la lectura nunca termina.
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final path in _photoFiles) {
      await precacheImage(FileImage(File(path)), context);
    }
  });
  await s.tap(find.text('Publicar'));
  await s.tap(find.byKey(const Key('publish-sell')));
  await s.tap(find.byKey(const Key('sell-gallery')));
  await quiet();
  if (step < 2) return;
  await s.tap(find.text('Continuar'));
  await s.type('sell-title', 'Calculadora científica Casio fx-991ES Plus');
  await s.type(
    'sell-description',
    'La usé un semestre para Cálculo y Física. Funciona perfecto, incluye su '
        'tapa y pilas nuevas. Tiene un rayón pequeño en la parte de atrás, se '
        've en la foto 3.',
  );
  await s.settle();
  if (step < 3) return;
  await s.tap(find.text('Continuar'));
  await s.type('sell-price', '450');
  await s.tap(find.byKey(const Key('sell-category-calculadoras')));
  FocusManager.instance.primaryFocus?.unfocus();
  await s.settle();
  if (step < 4) return;
  await s.tap(find.text('Continuar'));
  if (step < 5) return;
  await s.tap(find.byKey(const Key('sell-publish')));
}

/// Escenas que necesitan otro catalogo (cargando o sin red).
final Map<String, (bool, CatalogRepository)> _states = {
  'inicio-cargando': (true, FakeCatalogRepository.pending()),
  'inicio-error': (
    true,
    FakeCatalogRepository([
      const ApiFailure(code: ApiFailure.networkOffline, message: 'Sin red.'),
    ]),
  ),
  'inicio-visitante-vacio': (false, FakeCatalogRepository()),
};

Future<void> _loadFonts() async {
  final loader = FontLoader(MusubiType.family);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
  }
  await loader.load();
}

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(_width * 3.0, _height * 3.0)
    ..devicePixelRatio = 3
    ..padding = const FakeViewPadding(top: 54 * 3, bottom: 24 * 3)
    ..viewPadding = const FakeViewPadding(top: 54 * 3, bottom: 24 * 3);
  if (_dark) {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
  }
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

bool _wanted(String name) => _only.isEmpty || _only.split(',').contains(name);

void main() {
  setUpAll(() async {
    await _loadFonts();
    final bytes = (await rootBundle.load('assets/products/casio.webp')).buffer
        .asUint8List();
    final dir = Directory.systemTemp.createTempSync('musubi-fotos-');
    for (var i = 1; i <= 3; i++) {
      _photoFiles.add(
        (File('${dir.path}/foto-$i.webp')..writeAsBytesSync(bytes)).path,
      );
    }
  });

  for (final MapEntry(key: name, value: (member, scene)) in _scenes.entries) {
    if (!_wanted(name)) continue;
    testWidgets(name, (tester) async {
      _phone(tester);
      debugDisableShadows = false;
      try {
        final shot = _Shot(tester, member: member);
        await shot.open();
        await scene(shot);
        await shot.save(name + (_dark ? '-dark' : ''));
      } finally {
        debugDisableShadows = true;
      }
    });
  }

  for (final MapEntry(key: name, value: (member, catalog)) in _states.entries) {
    if (!_wanted(name)) continue;
    testWidgets(name, (tester) async {
      _phone(tester);
      debugDisableShadows = false;
      try {
        final shot = _Shot(tester, member: member, catalog: catalog);
        await shot.open(wait: false);
        await shot.save(name + (_dark ? '-dark' : ''));
      } finally {
        debugDisableShadows = true;
      }
    });
  }
}
