import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/domain/profile_repository.dart';

/// Perfil en memoria (HU-04) con las reglas del back: la carrera es del
/// campus y el periodo cabe en ella.
class FakeProfileRepository implements ProfileRepository {
  new({MyProfile? initial}) : profile = initial ?? sample;

  static const term = AcademicTerm(unit: 'cuatrimestre', count: 11);

  static const software = Career(
    slug: 'tsu-ti-software',
    name:
        'TSU en Tecnologías de la Información, área Desarrollo de Software '
        'Multiplataforma',
    shortName: 'TSU Desarrollo de Software',
    firstTerm: 1,
    lastTerm: 6,
  );

  static const mechatronics = Career(
    slug: 'ing-mecatronica',
    name: 'Ingeniería en Mecatrónica',
    shortName: 'Ing. Mecatrónica',
    firstTerm: 7,
    lastTerm: 11,
    level: CareerLevel.engineering,
  );

  static const accounting = Career(
    slug: 'lic-contaduria',
    name: 'Licenciatura en Contaduría',
    shortName: 'Lic. Contaduría',
    firstTerm: 7,
    lastTerm: 11,
    level: CareerLevel.bachelor,
  );

  static final sample = MyProfile(
    id: '6716a0000000000000000001',
    fullName: 'Ana Sofía Ramírez',
    email: 'ana.ramirez@uttt.edu.mx',
    emailVerifiedAt: DateTime.utc(2026, 10, 21, 18),
    campusShortName: 'UTTT',
    campusName: 'Universidad Tecnológica de Tula-Tepeji',
    academicTerm: term,
  );

  MyProfile profile;

  /// Falla la carga de [me] (estado de error con "Reintentar").
  bool failLoad = false;

  /// Falla guardar la visibilidad (el interruptor regresa).
  bool failVisibility = false;

  /// Rutas de las fotos subidas.
  final uploads = <String>[];
  int loads = 0;

  static const _offline = ApiFailure(
    code: ApiFailure.networkOffline,
    message: 'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
  );

  @override
  Future<MyProfile> me() async {
    loads++;
    if (failLoad) throw _offline;
    return profile;
  }

  @override
  Future<MyProfile> update({
    required String? career,
    required int? term,
  }) async {
    final picked = career == null
        ? null
        : [
            software,
            mechatronics,
            accounting,
          ].firstWhere((c) => c.slug == career);
    return profile = _copy(career: picked, term: term);
  }

  @override
  Future<MyProfile> setVisibility(ProfileVisibility visibility) async {
    if (failVisibility) throw _offline;
    return profile = profile.copyWith(visibility: visibility);
  }

  @override
  Future<MyProfile> uploadPhoto(String filePath) async {
    uploads.add(filePath);
    return profile = _copy(
      career: profile.career,
      term: profile.term,
      photoUrl: 'https://api.musubi.example/media/avatars/x/foto.webp',
    );
  }

  @override
  Future<void> removePhoto() async {
    profile = _copy(career: profile.career, term: profile.term);
  }

  @override
  Future<CareersCatalog> careers() async => const CareersCatalog(
    academicTerm: term,
    careers: [software, mechatronics, accounting],
  );

  MyProfile _copy({
    required Career? career,
    required int? term,
    String? photoUrl,
  }) => MyProfile(
    id: profile.id,
    fullName: profile.fullName,
    email: profile.email,
    emailVerifiedAt: profile.emailVerifiedAt,
    campusShortName: profile.campusShortName,
    campusName: profile.campusName,
    academicTerm: profile.academicTerm,
    career: career,
    term: term,
    photoUrl: photoUrl,
    visibility: profile.visibility,
    stats: profile.stats,
  );
}
