@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/domain/theme_preference.dart';
import 'package:musubi_app/features/profile/presentation/interests_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/profile/presentation/theme_preference_providers.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import 'support/live_api.dart';

/// Pantallas `Perfil`, `Editar-perfil`, `Privacidad`, `Perfil-vendedor`,
/// `Intereses` y `Ajustes` (tema y recomendaciones) contra la API real
/// (HU-04, HU-05, HU-66, 01-03).
void main() {
  group('Perfil contra la API real', skip: liveSkip, () {
    test('la app ve la API en linea (ping)', () async {
      final visitor = LiveSession.visitor();
      addTearDown(visitor.dispose);

      expect(
        await visitor.read(statusRepositoryProvider).check(),
        isA<ApiOnline>(),
      );
    });

    test(
      'editar mi perfil: carrera, cuatrimestre, foto y privacidad',
      () async {
        final ana = await liveUser();
        addTearDown(ana.dispose);
        final profiles = ana.read(profileRepositoryProvider);

        final catalog = await profiles.careers();
        final career = catalog.careers.first;
        final updated = await profiles.update(career: career.slug, term: 3);
        final withPhoto = await profiles.uploadPhoto(livePhoto().path);
        await profiles.removePhoto();
        final hidden = await profiles.setVisibility(
          const ProfileVisibility(career: false),
        );
        final me = await profiles.me();

        expect(catalog.careers, isNotEmpty);
        expect((updated.career?.slug, updated.term), (career.slug, 3));
        expect(withPhoto.photoUrl, isNotNull);
        expect(me.photoUrl, isNull);
        expect(hidden.visibility.career, isFalse);
        expect(me.email, ana.email);
      },
    );

    test('el perfil publico de otra persona respeta su privacidad', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      await valeria
          .read(profileRepositoryProvider)
          .setVisibility(const ProfileVisibility(sales: false));

      final public = await ana
          .read(profileRepositoryProvider)
          .publicProfile(valeria.user.id);

      expect(public.fullName, 'Valeria Integración');
      expect(public.sales, isNull);
    });

    test('mis intereses se guardan y se leen', () async {
      final ana = await liveUser();
      addTearDown(ana.dispose);
      final interests = ana.read(interestsRepositoryProvider);

      final saved = await interests.save(['calculadoras', 'laboratorio']);

      expect(saved, containsAll(['calculadoras', 'laboratorio']));
      expect(await interests.get(), containsAll(saved));
    });

    test('tema y recomendaciones se guardan en la cuenta', () async {
      final ana = await liveUser();
      addTearDown(ana.dispose);
      final preferences = ana.read(themePreferenceRepositoryProvider);

      await preferences.setTheme(ThemePreference.dark);
      await preferences.setRecommendations(
        enabled: false,
        theme: ThemePreference.dark,
      );

      expect(await preferences.getTheme(), ThemePreference.dark);
      expect(await preferences.getRecommendations(), isFalse);
    });
  });
}
