import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';

import '../../helpers/fake_profile_repository.dart';

// HU-04: el periodo del campus, los rangos por carrera y la linea del perfil
// ("UTTT · Ing. en Sistemas · 6º semestre" en la maqueta).
void main() {
  const term = FakeProfileRepository.term;

  test('termLabel: "6º cuatrimestre"', () {
    expect(term.label(6), '6º cuatrimestre');
    expect(
      const AcademicTerm(unit: 'semestre', count: 12).label(3),
      '3º semestre',
    );
  });

  test('periodos: los de la carrera, o del 1 al tope del campus', () {
    const catalog = CareersCatalog(academicTerm: term, careers: []);

    expect(FakeProfileRepository.software.terms, [1, 2, 3, 4, 5, 6]);
    expect(FakeProfileRepository.mechatronics.terms, [7, 8, 9, 10, 11]);
    expect(catalog.termsFor(null), hasLength(11));
    expect(FakeProfileRepository.mechatronics.allows(6), isFalse);
  });

  test('linea del perfil: campus, carrera y periodo', () {
    final base = FakeProfileRepository.sample;
    final full = MyProfile(
      id: base.id,
      fullName: base.fullName,
      email: base.email,
      campusShortName: 'UTTT',
      campusName: base.campusName,
      academicTerm: term,
      career: FakeProfileRepository.mechatronics,
      term: 8,
    );

    expect(base.subtitle, 'UTTT');
    expect(full.subtitle, 'UTTT · Ing. Mecatrónica · 8º cuatrimestre');
    expect(
      full
          .copyWith(visibility: const ProfileVisibility(career: false))
          .subtitle,
      'UTTT',
    );
    expect(full.initials, 'AR');
  });

  test('visibilidad por defecto: carrera y ventas si, en linea no', () {
    const visibility = ProfileVisibility();

    expect(
      (visibility.career, visibility.sales, visibility.online),
      (true, true, false),
    );
  });

  test('"Desde": mes corto y anio', () {
    expect(monthYear(DateTime(2026, 10, 21)), 'oct 2026');
    expect(monthYear(DateTime(2025)), 'ene 2025');
  });
}
