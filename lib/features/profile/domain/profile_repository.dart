import 'package:musubi_app/features/profile/domain/profile_models.dart';

/// Mi perfil (HU-04, filas "M-02" de `musubi-api/docs/endpoints.md`). Lanza
/// `ApiFailure`: la pantalla decide por el `code` (`profiles.*`).
abstract interface class ProfileRepository {
  Future<MyProfile> me();

  /// "Datos personales": carrera y periodo; `null` los borra.
  Future<MyProfile> update({required String? career, required int? term});

  Future<MyProfile> setVisibility(ProfileVisibility visibility);

  /// Sube o reemplaza la foto (la API la deja cuadrada de 512 px).
  Future<MyProfile> uploadPhoto(String filePath);

  Future<void> removePhoto();

  Future<CareersCatalog> careers();
}
