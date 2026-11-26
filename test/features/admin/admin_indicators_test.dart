import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/presentation/admin_providers.dart';

import '../../helpers/fake_admin.dart';
import '../profile/profile_flow_test.dart' show ProfileHarness;

/// HU-42: "Indicadores de uso" en `Ajustes` → "Administración", solo con el
/// rol `admin`. Conteos del campus por área, de la última semana o del último
/// mes; sin datos, una raya.
void main() {
  Future<(ProfileHarness, FakeAdminRepository)> openIndicators(
    WidgetTester tester, {
    FakeAdminRepository? admin,
    String location = AppRoutes.adminIndicators,
  }) async {
    final repository = admin ?? FakeAdminRepository();
    final h = ProfileHarness(
      tester,
      tokens: adminTokens(),
      overrides: [adminRepositoryProvider.overrideWithValue(repository)],
    );
    await h.open(location);
    return (h, repository);
  }

  Finder inCard(String key, String text) => find.descendant(
    of: find.byKey(Key('indicator-$key')),
    matching: find.text(text),
  );

  testWidgets('Ajustes: sin el rol no hay "Indicadores de uso"', (
    tester,
  ) async {
    await ProfileHarness(tester).open(AppRoutes.settings);

    expect(find.byKey(const Key('settings-admin-indicators')), findsNothing);
  });

  testWidgets('con el rol: las áreas, los valores con su unidad y el '
      'desglose', (tester) async {
    final (h, admin) = await openIndicators(
      tester,
      location: AppRoutes.settings,
    );

    await h.tapKey('settings-admin-indicators');

    expect(find.text('Indicadores de uso'), findsOneWidget);
    expect(find.text('ADOPCIÓN'), findsOneWidget);
    expect(inCard('users_registered', '1,250'), findsOneWidget);
    expect(inCard('products_created', 'Calculadoras · 3'), findsOneWidget);
    expect(inCard('direct_offers', '25 %'), findsOneWidget);
    expect(admin.indicatorPeriods, [IndicatorPeriod.week]);
    await tester.scrollUntilVisible(
      find.byKey(const Key('indicator-rating_average')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('indicators-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(inCard('rating_average', '4.7 ★'), findsOneWidget);
    expect(inCard('time_to_offer', '5.3 h'), findsOneWidget);
  });

  testWidgets('sin datos un porcentaje es una raya y lo explica', (
    tester,
  ) async {
    await openIndicators(tester);

    expect(inCard('ai_precision', '—'), findsOneWidget);
    expect(
      inCard(
        'ai_precision',
        'Aún no hay datos para calcularlo. 0 de 0 acuerdos',
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Último mes" pide el otro periodo', (tester) async {
    final (h, admin) = await openIndicators(tester);

    await h.tapKey('indicators-month');

    expect(admin.indicatorPeriods, [
      IndicatorPeriod.week,
      IndicatorPeriod.month,
    ]);
  });

  testWidgets('un error se explica y se reintenta', (tester) async {
    final admin = FakeAdminRepository()
      ..indicatorsFailure = const ApiFailure(
        code: 'auth.forbidden',
        message: 'No tienes permiso para hacer esto.',
        status: 403,
      );
    final (h, _) = await openIndicators(tester, admin: admin);

    expect(find.text('No tienes permiso para hacer esto.'), findsOneWidget);
    admin.indicatorsFailure = null;
    await h.tapText('Reintentar');

    expect(find.text('ADOPCIÓN'), findsOneWidget);
  });
}
