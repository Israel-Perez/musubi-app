import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/app_version.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/domain/favorite_models.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/profile/domain/theme_preference.dart';
import 'package:musubi_app/features/profile/presentation/theme_preference_providers.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../../helpers/fake_account_repository.dart';
import '../../helpers/fake_chat.dart' show jwtFor;
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_status_repository.dart';
import '../../helpers/fake_theme_preference_repository.dart';
import '../../helpers/in_memory_token_store.dart';

/// App completa con el router real y la sesion abierta (HU-04).
class ProfileHarness {
  new(this.tester, {MyProfile? initial, SessionTokens? tokens})
    : profile = FakeProfileRepository(initial: initial),
      _tokens = tokens ?? testTokens(),
      store = InMemoryTokenStore(tokens ?? testTokens());

  final WidgetTester tester;
  final FakeProfileRepository profile;
  final account = FakeAccountRepository();
  final picker = FakePhotoPicker();
  final favorites = FakeFavoritesRepository();
  final theme = FakeThemePreferenceRepository();
  final SessionTokens _tokens;
  final InMemoryTokenStore store;
  late ProviderContainer container;

  Future<void> open(String location) async {
    // Telefono de la maqueta: 390 x 844.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(profile),
          themePreferenceRepositoryProvider.overrideWithValue(theme),
          accountRepositoryProvider.overrideWithValue(account),
          listingsRepositoryProvider.overrideWithValue(
            FakeListingsRepository(),
          ),
          favoritesRepositoryProvider.overrideWithValue(favorites),
          photoPickerProvider.overrideWithValue(picker),
          statusRepositoryProvider.overrideWithValue(
            FakeStatusRepository([const ApiOnline(version: 'v1')]),
          ),
          tokenStoreProvider.overrideWithValue(store),
          initialSessionTokensProvider.overrideWithValue(_tokens),
        ],
        child: const MusubiApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(String key) => tap(find.byKey(Key(key)));

  Future<void> tapText(String text) => tap(find.text(text).last);

  /// Elige una opcion de una lista: se marca y se cierra 160 ms despues.
  Future<void> pick(String label) async {
    await tapText(label);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }
}

MyProfile profileWith({Career? career, int? term}) {
  final base = FakeProfileRepository.sample;
  return MyProfile(
    id: base.id,
    fullName: base.fullName,
    email: base.email,
    emailVerifiedAt: base.emailVerifiedAt,
    campusShortName: base.campusShortName,
    campusName: base.campusName,
    academicTerm: base.academicTerm,
    career: career,
    term: term,
  );
}

// HU-04: maquetas Perfil, Ajustes (y sus hojas) y Privacidad.
SessionTokens jwtProfileSession() => SessionTokens(
  accessToken: jwtFor('profile-user'),
  accessExpiresAt: DateTime.utc(2026, 11, 9, 12, 15),
  refreshToken: 'refresh-profile',
  profile: const SessionProfile(
    fullName: 'Ana Sofía Ramírez',
    email: 'ana.ramirez@uttt.edu.mx',
    campus: 'UTTT',
  ),
);

void main() {
  group('Perfil', () {
    testWidgets('sin carrera: nombre, campus, "Verificada" y todo en cero', (
      tester,
    ) async {
      await ProfileHarness(tester).open(AppRoutes.profile);

      expect(find.text('Ana Sofía Ramírez'), findsOneWidget);
      expect(find.byKey(const Key('profile-subtitle')), findsOneWidget);
      expect(find.text('UTTT'), findsOneWidget);
      expect(find.text('Verificada'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Sin calificaciones'), findsOneWidget);
      expect(find.text('Ventas'), findsOneWidget);
      expect(find.text('Compras'), findsOneWidget);
      expect(find.text('0 activas'), findsOneWidget);
      expect(find.text('Tus datos'), findsOneWidget);
      expect(find.text('Muy pronto'), findsNothing);
    });

    testWidgets('con carrera: "UTTT · Ing. Mecatrónica · 8º cuatrimestre"', (
      tester,
    ) async {
      await ProfileHarness(
        tester,
        initial: profileWith(
          career: FakeProfileRepository.mechatronics,
          term: 8,
        ),
      ).open(AppRoutes.profile);

      expect(
        find.text('UTTT · Ing. Mecatrónica · 8º cuatrimestre'),
        findsOneWidget,
      );
    });

    testWidgets('si falla la carga: "Reintentar" vuelve a pedirlo', (
      tester,
    ) async {
      final h = ProfileHarness(tester)..profile.failLoad = true;
      await h.open(AppRoutes.profile);

      expect(find.text('Algo salió mal'), findsOneWidget);
      // Mientras tanto el nombre viene de la sesion... o de "Tu cuenta".
      h.profile.failLoad = false;
      await h.tapText('Reintentar');

      expect(find.text('Sin calificaciones'), findsOneWidget);
      expect(h.profile.loads, 2);
    });

    testWidgets('mosaicos: "Favoritos" muestra el conteo y abre la lista', (
      tester,
    ) async {
      final h = ProfileHarness(tester, tokens: jwtProfileSession());
      h.favorites.favorites = Favorites(
        items: [
          FavoriteItem(
            productId: 'p1',
            savedAt: DateTime.utc(2026, 11, 9, 12),
            status: FavoriteStatus.available,
          ),
          FavoriteItem(
            productId: 'p2',
            savedAt: DateTime.utc(2026, 11, 9, 11),
            status: FavoriteStatus.available,
          ),
        ],
      );
      await h.open(AppRoutes.profile);

      expect(find.text('2 guardados'), findsOneWidget);

      await h.tapKey('tile-favorites');

      expect(find.text('Todos (2)'), findsOneWidget);
    });

    testWidgets('mosaicos: "Privacidad" abre la pantalla', (tester) async {
      final h = ProfileHarness(tester);
      await h.open(AppRoutes.profile);

      await h.tapKey('tile-privacy');

      expect(find.text('Tu perfil solo lo ve tu campus'), findsOneWidget);
    });
  });

  group('Ajustes', () {
    testWidgets('la tarjeta de la cuenta, las filas y la version', (
      tester,
    ) async {
      await ProfileHarness(tester).open(AppRoutes.settings);

      expect(find.text('ana.ramirez@uttt.edu.mx'), findsOneWidget);
      expect(find.text('Verificado'), findsOneWidget);
      expect(find.text('Cambiar contraseña'), findsOneWidget);
      expect(find.text('Quién te ve'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Como el sistema'), findsOneWidget);
      expect(find.text('Musubi $appVersion'), findsOneWidget);
    });

    testWidgets('cambiar a modo noche actualiza el tema y lo persiste', (
      tester,
    ) async {
      final h = ProfileHarness(tester);
      await h.open(AppRoutes.settings);

      await h.tapKey('settings-theme');
      expect(find.byKey(const Key('theme-preference-sheet')), findsOneWidget);
      await h.pick('Modo noche');

      expect(h.theme.preference, ThemePreference.dark);
      expect(h.container.read(themePreferenceProvider).value, ThemePreference.dark);
      expect(find.text('Modo noche'), findsOneWidget);
    });

    testWidgets('si falla al guardar, restaura el modo anterior y deja reintentar', (
      tester,
    ) async {
      final h = ProfileHarness(tester)..theme.failSave = true;
      await h.open(AppRoutes.settings);
      await h.tapKey('settings-theme');
      await h.pick('Modo noche');

      expect(h.container.read(themePreferenceProvider).value, ThemePreference.system);
      expect(find.text('No hay conexión. Revisa tu internet e inténtalo de nuevo.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('"Correo institucional": correo, Verificado y desde cuando', (
      tester,
    ) async {
      final h = ProfileHarness(tester);
      await h.open(AppRoutes.settings);

      await h.tapKey('settings-email');

      expect(find.byKey(const Key('email-sheet')), findsOneWidget);
      expect(find.text('ana.ramirez@uttt.edu.mx'), findsNWidgets(2));
      expect(find.text('oct 2026'), findsOneWidget);
      expect(find.textContaining('No se puede cambiar'), findsOneWidget);
      await h.tapText('Entendido');
      expect(find.byKey(const Key('email-sheet')), findsNothing);
    });
  });

  group('Datos personales', () {
    testWidgets('elegir carrera y cuatrimestre, guardar y verlo en Perfil', (
      tester,
    ) async {
      final h = ProfileHarness(tester);
      await h.open(AppRoutes.settings);
      await h.tapKey('settings-account');
      expect(find.byKey(const Key('personal-data-sheet')), findsOneWidget);
      expect(
        find.text('Viene de tu correo institucional verificado.'),
        findsOneWidget,
      );

      await h.tapKey('personal-data-career');
      expect(find.text('INGENIERÍA'), findsOneWidget);
      await h.pick('Ingeniería en Mecatrónica');
      await h.tapKey('personal-data-term');
      expect(find.text('6º cuatrimestre'), findsNothing);
      await h.pick('8º cuatrimestre');
      await h.tapKey('personal-data-save');

      expect(find.text('Guardamos tus datos'), findsOneWidget);
      expect(h.profile.profile.term, 8);
      h.container.read(routerProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(
        find.text('UTTT · Ing. Mecatrónica · 8º cuatrimestre'),
        findsOneWidget,
      );
    });

    testWidgets('el buscador filtra la lista de carreras', (tester) async {
      final h = ProfileHarness(tester);
      await h.open(AppRoutes.settings);
      await h.tapKey('settings-account');
      await h.tapKey('personal-data-career');

      await tester.enterText(find.byKey(const Key('career-search')), 'conta');
      await tester.pump();

      expect(find.text('Licenciatura en Contaduría'), findsOneWidget);
      expect(find.text('Ingeniería en Mecatrónica'), findsNothing);
      expect(find.text('Sin carrera'), findsNothing);
    });

    testWidgets('cambiar a una carrera donde el periodo no cabe lo borra', (
      tester,
    ) async {
      final h = ProfileHarness(
        tester,
        initial: profileWith(
          career: FakeProfileRepository.mechatronics,
          term: 8,
        ),
      );
      await h.open(AppRoutes.settings);
      await h.tapKey('settings-account');

      await h.tapKey('personal-data-career');
      await h.pick(FakeProfileRepository.software.name);

      expect(find.text('Elige tu cuatrimestre'), findsOneWidget);
      expect(find.textContaining('no corresponde a esta carrera'), findsOne);
      await h.tapKey('personal-data-save');
      expect(h.profile.profile.term, isNull);
      expect(h.profile.profile.career, FakeProfileRepository.software);
    });

    testWidgets('foto: subir desde la camara y quitarla', (tester) async {
      final h = ProfileHarness(tester);
      await h.open(AppRoutes.settings);
      await h.tapKey('settings-account');

      await h.tapKey('personal-data-photo');
      expect(find.text('Quitar foto'), findsNothing);
      await h.pick('Tomar foto');

      expect(h.profile.uploads, ['fotos/camara-1.jpg']);
      expect(find.text('Actualizamos tu foto'), findsOneWidget);
      expect(h.container.read(myProfileProvider).value?.photoUrl, isNotNull);

      await h.tapKey('personal-data-photo');
      await h.pick('Quitar foto');

      expect(find.text('Quitamos tu foto'), findsOneWidget);
      expect(h.container.read(myProfileProvider).value?.photoUrl, isNull);
    });

    testWidgets('sin camara: avisa en espanol', (tester) async {
      final h = ProfileHarness(tester)..picker.cameraFails = true;
      await h.open(AppRoutes.settings);
      await h.tapKey('settings-account');

      await h.tapKey('personal-data-photo');
      await h.pick('Tomar foto');

      expect(find.text('No pudimos abrir la cámara.'), findsOneWidget);
      expect(h.profile.uploads, isEmpty);
    });
  });

  group('Cambiar contraseña', () {
    Future<ProfileHarness> openSheet(WidgetTester tester) async {
      final h = ProfileHarness(tester);
      await h.open(AppRoutes.settings);
      await h.tapKey('settings-password');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('change-password-sheet')), findsOneWidget);
      return h;
    }

    Future<void> submit(
      ProfileHarness h, {
      required String current,
      required String next,
    }) async {
      await h.tester.enterText(
        find.byKey(const Key('change-password-current')),
        current,
      );
      await h.tester.enterText(
        find.byKey(const Key('change-password-new')),
        next,
      );
      await h.tapKey('change-password-submit');
    }

    testWidgets('la nueva corta: "Necesita al menos 8 caracteres."', (
      tester,
    ) async {
      final h = await openSheet(tester);

      await submit(h, current: FakeAccountRepository.password, next: 'corta');

      expect(find.text('Necesita al menos 8 caracteres.'), findsOneWidget);
      expect(h.account.newPassword, isNull);
    });

    testWidgets('la actual equivocada: marca su campo', (tester) async {
      final h = await openSheet(tester);

      await submit(h, current: 'otra-clave-1', next: 'musubi2027');

      expect(find.text('La contraseña no es correcta.'), findsOneWidget);
      expect(find.byKey(const Key('change-password-sheet')), findsOneWidget);
    });

    testWidgets('al guardar reemplaza la sesion sin pedir el login', (
      tester,
    ) async {
      final h = await openSheet(tester);

      await submit(
        h,
        current: FakeAccountRepository.password,
        next: 'musubi2027',
      );

      expect(h.account.newPassword, 'musubi2027');
      expect(h.store.saved?.accessToken, 'access-nuevo');
      expect(h.container.read(sessionControllerProvider), isA<SignedIn>());
      expect(find.text('Actualizamos tu contraseña'), findsOneWidget);
      expect(find.byKey(const Key('change-password-sheet')), findsNothing);
    });
  });

  group('Privacidad: Quién te ve', () {
    testWidgets('apagar "Mostrar mi carrera" avisa y la quita del Perfil', (
      tester,
    ) async {
      final h = ProfileHarness(
        tester,
        initial: profileWith(
          career: FakeProfileRepository.mechatronics,
          term: 8,
        ),
      );
      await h.open(AppRoutes.accountPrivacy);

      await h.tapKey('visibility-career');

      expect(find.text('Ocultamos tu carrera'), findsOneWidget);
      expect(h.profile.profile.visibility.career, isFalse);
      h.container.read(routerProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(find.text('UTTT'), findsOneWidget);
    });

    testWidgets('"en línea" empieza apagado y se puede encender', (
      tester,
    ) async {
      final h = ProfileHarness(tester);
      await h.open(AppRoutes.accountPrivacy);

      await h.tapKey('visibility-online');

      expect(find.text('Ahora se ve cuando estás en línea'), findsOneWidget);
      expect(h.profile.profile.visibility.online, isTrue);
    });

    testWidgets('si falla, el interruptor regresa y lo explica', (
      tester,
    ) async {
      final h = ProfileHarness(tester)..profile.failVisibility = true;
      await h.open(AppRoutes.accountPrivacy);

      await h.tapKey('visibility-sales');

      expect(find.textContaining('No pudimos guardar el cambio'), findsOne);
      expect(
        h.container.read(myProfileProvider).value?.visibility.sales,
        isTrue,
      );
    });
  });
}
