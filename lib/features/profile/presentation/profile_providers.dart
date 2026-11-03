import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/profile/data/http_profile_repository.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/domain/profile_repository.dart';

/// Mi perfil (HU-04), con sesion. En pruebas, un fake.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => HttpProfileRepository(
    ref.watch(dioProvider),
    ref.watch(appConfigProvider).apiBaseUrl,
  ),
);

/// Mi perfil, compartido por `Perfil`, `Ajustes` y `Privacidad`: un cambio se
/// ve al instante en las tres sin recargar.
final myProfileProvider = AsyncNotifierProvider<MyProfileController, MyProfile>(
  MyProfileController.new,
  // El error se ve al instante: la pantalla trae "Reintentar".
  retry: (_, _) => null,
);

/// Carga y cambios de mi perfil. Cada cambio guarda en la API y publica lo
/// que respondio (la fuente de verdad es el servidor).
class MyProfileController extends AsyncNotifier<MyProfile> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<MyProfile> build() {
    // Otra cuenta, otro perfil. Al renovar los tokens (cada 15 min) el correo
    // no cambia y no se vuelve a pedir.
    ref.watch(
      sessionControllerProvider.select(
        (s) => s is SignedIn ? s.tokens.profile?.email ?? '' : null,
      ),
    );
    return ref.read(profileRepositoryProvider).me();
  }

  /// "Datos personales". Lanza `ApiFailure` si la API lo rechaza.
  Future<void> save({required String? career, required int? term}) async {
    state = AsyncData(await _repository.update(career: career, term: term));
  }

  /// "Quien te ve": cambia al instante y, si la API falla, regresa al estado
  /// anterior y lanza el `ApiFailure`.
  Future<void> setVisibility(ProfileVisibility visibility) async {
    final previous = state.value;
    if (previous == null) return;
    state = AsyncData(previous.copyWith(visibility: visibility));
    try {
      state = AsyncData(await _repository.setVisibility(visibility));
    } on Object {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> uploadPhoto(String filePath) async {
    state = AsyncData(await _repository.uploadPhoto(filePath));
  }

  Future<void> removePhoto() async {
    await _repository.removePhoto();
    state = AsyncData(await _repository.me());
  }
}

/// Carreras del campus para "Datos personales".
final FutureProvider<CareersCatalog> careersProvider =
    FutureProvider.autoDispose<CareersCatalog>(
      (ref) => ref.watch(profileRepositoryProvider).careers(),
      retry: (_, _) => null,
    );
