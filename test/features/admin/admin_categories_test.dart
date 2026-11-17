import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/admin/presentation/admin_providers.dart';

import '../../helpers/fake_admin.dart';
import '../profile/profile_flow_test.dart' show ProfileHarness;

/// HU-41: "Categorías" en `Ajustes` → "Administración", solo con el rol
/// `admin`.
void main() {
  Future<(ProfileHarness, FakeAdminRepository)> openCategories(
    WidgetTester tester, {
    FakeAdminRepository? admin,
    String location = AppRoutes.adminCategories,
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

  Finder pillOf(String slug, String label) => find.descendant(
    of: find.byKey(Key('admin-category-$slug')),
    matching: find.text(label),
  );

  testWidgets('Ajustes: sin el rol no hay "Categorías"', (tester) async {
    await ProfileHarness(tester).open(AppRoutes.settings);

    expect(find.byKey(const Key('settings-admin-categories')), findsNothing);
  });

  testWidgets('Ajustes: con el rol muestra todas, también las desactivadas', (
    tester,
  ) async {
    final (h, _) = await openCategories(tester, location: AppRoutes.settings);

    await h.tapKey('settings-admin-categories');

    expect(find.text('Calculadoras'), findsOneWidget);
    expect(find.text('Electrónica'), findsOneWidget);
    expect(pillOf('calculadoras', 'Activa'), findsOneWidget);
    expect(pillOf('dibujo', 'Desactivada'), findsOneWidget);
  });

  testWidgets('"Agregar categoría" la manda sin espacios y la muestra', (
    tester,
  ) async {
    final (h, admin) = await openCategories(tester);

    await h.tapKey('admin-category-add');
    await tester.enterText(
      find.byKey(const Key('admin-category-name')),
      '  Mochilas ',
    );
    await h.tapKey('admin-category-save');

    expect(admin.categoryChanges.single, ('new', 'Mochilas', null));
    expect(find.text('Agregamos la categoría'), findsOneWidget);
    expect(pillOf('mochilas', 'Activa'), findsOneWidget);
  });

  testWidgets('un nombre de menos de 2 letras no se manda', (tester) async {
    final (h, admin) = await openCategories(tester);

    await h.tapKey('admin-category-add');
    await tester.enterText(find.byKey(const Key('admin-category-name')), 'x');
    await h.tapKey('admin-category-save');

    expect(
      find.text('Escribe un nombre de 2 a 40 caracteres.'),
      findsOneWidget,
    );
    expect(admin.categoryChanges, isEmpty);
  });

  testWidgets('renombrar manda solo el nombre', (tester) async {
    final (h, admin) = await openCategories(tester);

    await h.tapKey('admin-category-libros');
    expect(find.text('Editar categoría'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('admin-category-name')),
      'Libros y apuntes',
    );
    await h.tapKey('admin-category-save');

    expect(admin.categoryChanges.single, ('libros', 'Libros y apuntes', null));
    expect(find.text('Guardamos el nombre'), findsOneWidget);
    expect(find.text('Libros y apuntes'), findsOneWidget);
  });

  testWidgets('desactivar pide confirmación; activar no', (tester) async {
    final (h, admin) = await openCategories(tester);

    await h.tapKey('admin-category-laptops');
    await h.tapKey('admin-category-toggle');
    expect(find.text('¿Desactivar Laptops?'), findsOneWidget);
    await h.tapKey('admin-category-deactivate-confirm');

    expect(admin.categoryChanges.single, ('laptops', null, false));
    expect(find.text('Desactivamos la categoría'), findsOneWidget);
    expect(pillOf('laptops', 'Desactivada'), findsOneWidget);

    await h.tapKey('admin-category-dibujo');
    expect(find.text('Activar categoría'), findsOneWidget);
    await h.tapKey('admin-category-toggle');

    expect(admin.categoryChanges.last, ('dibujo', null, true));
    expect(pillOf('dibujo', 'Activa'), findsOneWidget);
  });

  testWidgets('el error de la API se queda en la hoja', (tester) async {
    final admin = FakeAdminRepository()
      ..failCategory = const ApiFailure(
        code: 'admin.category_exists',
        message:
            'Ya hay una categoría con ese nombre. Revisa también las '
            'desactivadas.',
      );
    final (h, _) = await openCategories(tester, admin: admin);

    await h.tapKey('admin-category-add');
    await tester.enterText(
      find.byKey(const Key('admin-category-name')),
      'Dibujo',
    );
    await h.tapKey('admin-category-save');

    expect(
      find.text(
        'Ya hay una categoría con ese nombre. Revisa también las desactivadas.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('admin-category-sheet')), findsOneWidget);
  });

  testWidgets('sin conexión ofrece reintentar', (tester) async {
    final admin = FakeAdminRepository()..failLoad = true;
    final (h, _) = await openCategories(tester, admin: admin);

    expect(
      find.text('No hay conexión. Revisa tu internet e inténtalo de nuevo.'),
      findsOneWidget,
    );

    admin.failLoad = false;
    await h.tapText('Reintentar');

    expect(find.text('Calculadoras'), findsOneWidget);
  });
}
