import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../../helpers/fake_account_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_reputation.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/fake_status_repository.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 8, 12);

const _photo = 'https://api.musubi.example/media/avatars/v/a.webp';

/// App completa con el router real, la sesion abierta, el chat y los reportes
/// y bloqueos falsos (HU-28, HU-57).
class ReputationHarness {
  new(
    this.tester, {
    FakeChatRepository? chat,
    FakeReputationRepository? reputation,
  }) : chat = chat ?? FakeChatRepository(),
       reputation = reputation ?? FakeReputationRepository();

  final WidgetTester tester;
  final FakeChatRepository chat;
  final FakeReputationRepository reputation;

  Future<void> open(String location) async {
    // Telefono de la maqueta: 390 x 844.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = chatTokens(_now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([const HomeFeed()]),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
          listingsRepositoryProvider.overrideWithValue(
            FakeListingsRepository(),
          ),
          statusRepositoryProvider.overrideWithValue(
            FakeStatusRepository([const ApiOnline(version: 'v1')]),
          ),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(chat),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          reputationRepositoryProvider.overrideWithValue(reputation),
        ],
        child: const MusubiApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(MusubiApp)))
        .read(routerProvider)
        .go(location);
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Elige una opcion de una lista: se marca y se cierra 160 ms despues, y la
  /// maqueta abre lo siguiente 240 ms despues.
  Future<void> pick(String label) async {
    await tap(find.text(label).last);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  Future<void> openMore() => tap(find.bySemanticsLabel('Más opciones'));
}

void main() {
  group('chat (HU-57, HU-28)', () {
    testWidgets('Mas opciones tiene las cuatro de la maqueta', (tester) async {
      final h = ReputationHarness(tester);
      await h.open(AppRoutes.conversation('c1'));

      await h.openMore();

      expect(find.byKey(const Key('chat-more')), findsOneWidget);
      for (final label in [
        'Valeria Cruz',
        'Ver perfil',
        'Silenciar conversación',
        'Bloquear a Valeria',
        'Reportar',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
    });

    testWidgets(
      'Bloquear a Valeria confirma, bloquea y cambia la caja por el aviso',
      (tester) async {
        final h = ReputationHarness(tester);
        await h.open(AppRoutes.conversation('c1'));

        await h.openMore();
        await h.pick('Bloquear a Valeria');

        expect(find.text('¿Bloquear a Valeria?'), findsOneWidget);
        expect(
          find.text(
            'No podrá escribirte ni ver tus publicaciones. Puedes '
            'desbloquearlo en Ajustes.',
          ),
          findsOneWidget,
        );
        await h.tap(find.byKey(const Key('block-confirm')));

        expect(h.reputation.blockedIds, [valeria.id]);
        expect(find.byKey(const Key('chat-blocked')), findsOneWidget);
        expect(find.byKey(const Key('chat-input')), findsNothing);
        expect(find.text('Bloqueaste a Valeria'), findsOneWidget);
      },
    );

    testWidgets('cancelar el dialogo no bloquea', (tester) async {
      final h = ReputationHarness(tester);
      await h.open(AppRoutes.conversation('c1'));

      await h.openMore();
      await h.pick('Bloquear a Valeria');
      await h.tap(find.text('Cancelar'));

      expect(h.reputation.blockedIds, isEmpty);
      expect(find.byKey(const Key('chat-input')), findsOneWidget);
    });

    testWidgets('una conversacion con bloqueo muestra el aviso sin caja', (
      tester,
    ) async {
      final h = ReputationHarness(
        tester,
        chat: FakeChatRepository(
          conversationValue: sampleConversation.blocked(),
        ),
      );
      await h.open(AppRoutes.conversation('c1'));

      expect(
        find.text('No puedes responder a esta conversación.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chat-input')), findsNothing);
    });

    testWidgets('chat.blocked al enviar cambia la caja por el aviso', (
      tester,
    ) async {
      final h = ReputationHarness(
        tester,
        chat: FakeChatRepository(
          sendFailure: const ApiFailure(
            code: 'chat.blocked',
            message: 'No puedes escribirle a esta persona.',
            status: 403,
          ),
        ),
      );
      await h.open(AppRoutes.conversation('c1'));

      await tester.enterText(find.byKey(const Key('chat-input')), 'Hola');
      await h.tap(find.bySemanticsLabel('Enviar'));

      expect(find.text('No puedes escribirle a esta persona.'), findsOneWidget);
      expect(find.byKey(const Key('chat-blocked')), findsOneWidget);
    });

    testWidgets(
      'Reportar manda a la persona, la conversacion, el motivo y el detalle',
      (tester) async {
        final h = ReputationHarness(tester);
        await h.open(AppRoutes.conversation('c1'));

        await h.openMore();
        await h.pick('Reportar');

        expect(find.byKey(const Key('report-reasons')), findsOneWidget);
        for (final reason in ReportReason.values) {
          expect(find.text(reason.label), findsOneWidget, reason: reason.label);
        }
        expect(
          find.text(
            'Tu reporte es confidencial. El equipo de Musubi lo revisa en '
            'menos de 24 horas.',
          ),
          findsOneWidget,
        );

        await h.pick('Me pidió pagar fuera de Musubi');
        expect(find.byKey(const Key('report-details')), findsOneWidget);
        expect(find.text('Cuéntanos qué pasó'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('report-details-field')),
          'Me pidió depositarle antes de vernos.',
        );
        await h.tap(find.byKey(const Key('report-submit')));

        final sent = h.reputation.reports.single;
        final target = sent.target as UserReport;
        expect((target.userId, target.conversationId), (valeria.id, 'c1'));
        expect(sent.reason, ReportReason.offPlatform);
        expect(sent.details, 'Me pidió depositarle antes de vernos.');
        expect(find.byKey(const Key('report-details')), findsNothing);
        expect(
          find.text('Recibimos tu reporte. Te escribimos en menos de 24 h.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('la foto de la otra persona en el encabezado y la bandeja', (
      tester,
    ) async {
      const withPhoto = ChatCounterpart(
        id: '6716a0000000000000000001',
        name: 'Valeria Cruz',
        photoUrl: _photo,
      );
      final h = ReputationHarness(
        tester,
        chat: FakeChatRepository(
          conversationValue: Conversation(
            id: 'c1',
            role: ChatRole.buyer,
            counterpart: withPhoto,
            context: sampleConversation.context,
          ),
          inboxEntries: [
            InboxEntry(
              id: 'c1',
              role: ChatRole.buyer,
              counterpart: withPhoto,
              contextTitle: 'Calculadora Casio fx-991ES Plus',
              lastSenderId: withPhoto.id,
              lastText: 'Sí, sigue disponible',
              lastAt: _now,
              unread: 1,
            ),
          ],
        ),
      );

      await h.open(AppRoutes.conversation('c1'));
      final header = tester.widget<ProfileAvatar>(
        find.byType(ProfileAvatar).first,
      );
      await h.open(AppRoutes.messages);
      final row = tester.widget<ProfileAvatar>(
        find.byType(ProfileAvatar).first,
      );

      expect((header.photoUrl, header.initials), (_photo, 'VC'));
      expect((row.photoUrl, row.initials), (_photo, 'VC'));
    });
  });

  group('Ajustes y Privacidad', () {
    testWidgets('Reportar un problema manda un reporte general', (
      tester,
    ) async {
      final h = ReputationHarness(tester);
      await h.open(AppRoutes.settings);

      await h.tap(find.byKey(const Key('settings-report')));
      await h.pick('Otro problema');
      await h.tap(find.byKey(const Key('report-submit')));

      final sent = h.reputation.reports.single;
      expect(sent.target, isA<GeneralReport>());
      expect(sent.reason, ReportReason.other);
      expect(
        find.text('Recibimos tu reporte. Te escribimos en menos de 24 h.'),
        findsOneWidget,
      );
    });

    testWidgets('si el reporte falla, la hoja sigue abierta con el aviso', (
      tester,
    ) async {
      final h = ReputationHarness(
        tester,
        reputation: FakeReputationRepository(
          reportFailure: const ApiFailure(
            code: 'rate_limit.exceeded',
            message: 'Hiciste muchos intentos. Espera un momento.',
            status: 429,
          ),
        ),
      );
      await h.open(AppRoutes.settings);

      await h.tap(find.byKey(const Key('settings-report')));
      await h.pick('El pago no llegó o no coincide');
      await h.tap(find.byKey(const Key('report-submit')));

      expect(find.byKey(const Key('report-details')), findsOneWidget);
      expect(
        find.text('Hiciste muchos intentos. Espera un momento.'),
        findsOneWidget,
      );
    });

    testWidgets('Usuarios bloqueados muestra cuantos, lista y desbloquea', (
      tester,
    ) async {
      final h = ReputationHarness(
        tester,
        reputation: FakeReputationRepository(
          blockedUsers: [
            BlockedUser(id: 'u2', name: 'Diego Hernández', blockedAt: _now),
          ],
        ),
      );
      await h.open(AppRoutes.accountPrivacy);

      expect(find.text('Usuarios bloqueados'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      await h.tap(find.byKey(const Key('privacy-blocked')));

      expect(find.byKey(const Key('blocked-users')), findsOneWidget);
      expect(find.text('Diego Hernández'), findsOneWidget);
      await h.tap(find.byKey(const Key('unblock-u2')));

      expect(h.reputation.unblockedIds, ['u2']);
      expect(find.text('Desbloqueaste a Diego'), findsOneWidget);
      expect(
        find.text(
          'No has bloqueado a nadie. Si alguien te molesta, bloquéalo desde el '
          'chat.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin bloqueos la fila dice Ninguno', (tester) async {
      final h = ReputationHarness(tester);
      await h.open(AppRoutes.accountPrivacy);

      expect(find.text('Ninguno'), findsOneWidget);
    });
  });
}
