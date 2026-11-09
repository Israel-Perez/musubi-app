import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';

/// Solicitudes de compra (HU-13), con sesion. Lanza `ApiFailure` (nunca
/// `DioException`).
abstract interface class WantedRepository {
  /// "Publicar solicitud".
  Future<WantedRequest> publish(NewWanted request);

  /// "Mis solicitudes", de la mas nueva a la mas vieja.
  Future<List<WantedRequest>> mine();
}
