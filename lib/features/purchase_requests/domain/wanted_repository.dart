import 'package:musubi_app/features/purchase_requests/domain/wanted_board.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';

/// Solicitudes de compra (HU-13, HU-15). Lanza `ApiFailure` (nunca
/// `DioException`).
abstract interface class WantedRepository {
  /// Tablero "Se busca" del campus (HU-15). Tambien sin sesion (HU-48): la
  /// API manda entonces solo el nombre corto de quien busca.
  Future<WantedPage> board({
    WantedBoardFilter filter = const WantedBoardFilter(),
    String? cursor,
    int? limit,
  });

  /// "Publicar solicitud".
  Future<WantedRequest> publish(NewWanted request);

  /// "Mis solicitudes", de la mas nueva a la mas vieja.
  Future<List<WantedRequest>> mine();
}
