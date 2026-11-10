import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/fake_wanted.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime(2026, 11, 9, 12);

/// App completa con el router real, la sesion abierta y `Mis-solicitudes`
/// con solicitudes falsas (HU-14).
class ManageHarness {
  new(this.tester, {required List<WantedRequest> mine})
    : wanted = FakeWantedRepository(mine: mine);

  final WidgetTester tester;
  final FakeWantedRepository wanted;

  Future<void> open() async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = chatTokens(_now.toUtc());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([const HomeFeed()]),
          ),
          listingsRepositoryProvider.overrideWithValue(
            FakeListingsRepository(
              range: const PriceRange(lowCents: 38000, highCents: 58000),
            ),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          wantedRepositoryProvider.overrideWithValue(wanted),
        ],
        child: const MusubiApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(MusubiApp)))
        .read(routerProvider)
        .go(AppRoutes.myWanted);
    await tester.pumpAndSettle();
  }

  /// Toca y espera las animaciones y los 240 ms de la siguiente hoja.
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  Future<void> manage() =>
      tap(find.byKey(const Key('my-wanted-change-button')));
}

void main() {
  testWidgets(
    '"Cambiar" en una activa abre "Tu solicitud"; con otra, "Ver otra"',
    (tester) async {
      final h = ManageHarness(tester, mine: [sampleWanted()]);
      await h.open();

      // Una sola solicitud: "Cambiar" ya no elige otra, la gestiona.
      await h.manage();
      expect(find.byKey(const Key('my-wanted-manage')), findsOneWidget);
      expect(find.text('Editar solicitud'), findsOneWidget);
      expect(find.text('Ya lo conseguí'), findsOneWidget);
      expect(find.text('Cancelar solicitud'), findsOneWidget);
      expect(find.text('Ver otra solicitud'), findsNothing);
    },
  );

  testWidgets('con dos activas, "Ver otra solicitud" abre la lista', (
    tester,
  ) async {
    final h = ManageHarness(
      tester,
      mine: [
        sampleWanted(),
        sampleWanted(id: 'w2', title: 'Bata de laboratorio'),
      ],
    );
    await h.open();

    await h.manage();
    await h.tap(find.text('Ver otra solicitud'));
    expect(find.byKey(const Key('my-wanted-change')), findsOneWidget);
    await h.tap(find.text('Bata de laboratorio').last);

    expect(
      find.descendant(
        of: find.byKey(const Key('my-wanted-card')),
        matching: find.text('Bata de laboratorio'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Ya lo conseguí" pide confirmar, la cierra y pasa a Cerradas', (
    tester,
  ) async {
    final h = ManageHarness(tester, mine: [sampleWanted()]);
    await h.open();

    await h.manage();
    await h.tap(find.text('Ya lo conseguí'));
    expect(find.text('¿Ya conseguiste lo que buscabas?'), findsOneWidget);
    await h.tap(find.byKey(const Key('my-wanted-close-confirm')));

    expect(h.wanted.statusChanges, [('close', 'w1')]);
    expect(find.text('¡Qué bien! Cerramos tu solicitud.'), findsOneWidget);
    expect(find.text('Activas (0)'), findsOneWidget);
    expect(find.text('Cerradas (1)'), findsOneWidget);

    await h.tap(find.byKey(const Key('my-wanted-tab-closed')));
    expect(find.text('Cerrada'), findsOneWidget);
    // Una cerrada ya no se gestiona (RN-11).
    expect(find.byKey(const Key('my-wanted-change-button')), findsNothing);
  });

  testWidgets('"Cancelar solicitud": "No, mantenerla" no cambia nada', (
    tester,
  ) async {
    final h = ManageHarness(tester, mine: [sampleWanted()]);
    await h.open();

    await h.manage();
    await h.tap(find.text('Cancelar solicitud'));
    expect(find.text('¿Cancelar tu solicitud?'), findsOneWidget);
    await h.tap(find.text('No, mantenerla'));
    expect(h.wanted.statusChanges, isEmpty);
    expect(find.text('Activas (1)'), findsOneWidget);

    await h.manage();
    await h.tap(find.text('Cancelar solicitud'));
    await h.tap(find.byKey(const Key('my-wanted-cancel-confirm')));

    expect(h.wanted.statusChanges, [('cancel', 'w1')]);
    expect(find.text('Cancelamos tu solicitud.'), findsOneWidget);
    await h.tap(find.byKey(const Key('my-wanted-tab-closed')));
    expect(find.text('Cancelada'), findsOneWidget);
  });

  testWidgets('si la API no deja, el aviso dice por que', (tester) async {
    final h = ManageHarness(tester, mine: [sampleWanted()]);
    h.wanted.manageFailure = const ApiFailure(
      code: 'wanted.not_active',
      message: 'Esta solicitud ya no está activa, así que no se puede cambiar.',
    );
    await h.open();

    await h.manage();
    await h.tap(find.text('Ya lo conseguí'));
    await h.tap(find.byKey(const Key('my-wanted-close-confirm')));

    expect(
      find.text(
        'Esta solicitud ya no está activa, así que no se puede cambiar.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    '"Editar solicitud": Necesidad-1…3 con sus datos y "Guardar cambios"',
    (tester) async {
      final h = ManageHarness(
        tester,
        mine: [sampleWanted(neededBy: DateTime(2026, 11, 13))],
      );
      await h.open();

      await h.manage();
      await h.tap(find.text('Editar solicitud'));

      expect(find.text('Editar solicitud'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const Key('need-title')),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'Calculadora Casio fx-991ES Plus',
      );
      // Sin "Así funciona": ya la publico.
      expect(find.text('Así funciona'), findsNothing);
      await h.tap(find.byKey(const Key('need-continue')));
      await h.tap(find.byKey(const Key('need-details-continue')));

      expect(find.text('Guardar cambios'), findsOneWidget);
      // La fecha que tenia (el viernes) queda elegida en su opcion rapida.
      expect(find.text('Vie 13 nov'), findsOneWidget);
      expect(find.text('Elegir fecha'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('need-budget')), '700');
      await tester.pump();
      await h.tap(find.byKey(const Key('need-publish')));

      final (id, sent) = h.wanted.updates.single;
      expect(id, 'w1');
      expect(
        (sent.title, sent.category),
        ('Calculadora Casio fx-991ES Plus', 'calculadoras'),
      );
      expect(
        (sent.budgetCents, sent.neededBy),
        (70000, DateTime(2026, 11, 13)),
      );
      // De vuelta en `Mis-solicitudes`, con el cambio.
      expect(find.text('Mis solicitudes'), findsOneWidget);
      expect(
        find.text('Guardamos los cambios de tu solicitud.'),
        findsOneWidget,
      );
      expect(find.text(r'Hasta $700', findRichText: true), findsOneWidget);
    },
  );

  testWidgets('"Guardar" de arriba tambien guarda; la X no', (tester) async {
    final h = ManageHarness(tester, mine: [sampleWanted()]);
    await h.open();

    await h.manage();
    await h.tap(find.text('Editar solicitud'));
    await h.tap(find.bySemanticsLabel('Cerrar').first);
    expect(h.wanted.updates, isEmpty);
    expect(find.text('Mis solicitudes'), findsOneWidget);

    await h.manage();
    await h.tap(find.text('Editar solicitud'));
    await tester.enterText(
      find.byKey(const Key('need-title')),
      'Calculadora graficadora',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await h.tap(find.bySemanticsLabel('Guardar borrador'));

    expect(h.wanted.updates.single.$2.title, 'Calculadora graficadora');
    expect(find.text('Calculadora graficadora'), findsOneWidget);
  });

  testWidgets('con ofertas, el producto y la categoria quedan fijos (HU-14)', (
    tester,
  ) async {
    final h = ManageHarness(tester, mine: [sampleWanted(offers: 2)]);
    await h.open();

    await h.manage();
    await h.tap(find.text('Editar solicitud'));

    expect(find.byKey(const Key('need-locked')), findsOneWidget);
    final field = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('need-title')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.readOnly || !field.focusNode.canRequestFocus, isTrue);
    // Solo queda la categoria elegida.
    expect(find.byKey(const Key('need-category-otro')), findsNothing);
  });

  testWidgets('una cerrada muestra sus ofertas sin "Rechazar" ni "Aceptar"', (
    tester,
  ) async {
    final h = ManageHarness(
      tester,
      mine: [sampleWanted(status: WantedStatus.closed, offers: 1)],
    );
    h.wanted.received['w1'] = [
      ReceivedOffer(
        id: 'o1',
        kind: OfferKind.direct,
        title: 'Casio fx-991ES Plus con tapa',
        priceCents: 50000,
        condition: 'used',
        offerer: const Offerer(id: 'u-diego', name: 'Diego Hernández'),
        createdAt: DateTime.utc(2026, 11, 9, 16),
      ),
    ];
    await h.open();
    await h.tap(find.byKey(const Key('my-wanted-tab-closed')));

    expect(find.byKey(const ValueKey('offer-chat-o1')), findsOneWidget);
    expect(find.byKey(const ValueKey('offer-reject-o1')), findsNothing);
    expect(find.byKey(const ValueKey('offer-accept-o1')), findsNothing);
  });
}
