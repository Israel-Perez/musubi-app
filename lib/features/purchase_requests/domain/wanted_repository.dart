import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
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

  /// Mi oferta a una solicitud (HU-16), o `null` si aun no ofrezco.
  Future<WantedOffer?> myOffer(String requestId);

  /// "Enviar oferta" (HU-16): la crea o la reemplaza (RN-14).
  Future<WantedOffer> sendOffer(String requestId, NewOffer offer);

  /// "Compara las ofertas" (HU-17): las de mi solicitud.
  Future<List<ReceivedOffer>> receivedOffers(String requestId);

  /// "Rechazar" (HU-17).
  Future<void> rejectOffer(String requestId, String offerId);

  /// "Aceptar oferta" (HU-17): devuelve la conversacion con quien ofrece.
  Future<String> acceptOffer(String requestId, String offerId);

  /// "Abrir chat" (HU-17): la conversacion con quien ofrece, sin decidir.
  Future<String> offerChat(String requestId, String offerId);
}
