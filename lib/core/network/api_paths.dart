/// Rutas de musubi-api que consume la app.
///
/// El contrato canonico vive en `musubi-api/docs/endpoints.md`: cada
/// constante cita su fila y aqui nunca se duplican DTOs ni codigos
/// (skill `api-contract`).
abstract final class ApiPaths {
  /// `GET /api/v1/ping` — fila "Plataforma" de musubi-api `docs/endpoints.md`
  /// (spec `musubi-api:01-03`). Respuesta: `{ status: "pong", version: "v1" }`.
  static const ping = '/api/v1/ping';

  /// `POST /api/v1/auth/campus` — fila "M-01" (spec `musubi-api:HU-01`).
  static const authCampus = '/api/v1/auth/campus';

  /// `POST /api/v1/auth/register` — fila "M-01" (spec `musubi-api:HU-01`).
  static const authRegister = '/api/v1/auth/register';

  /// `POST /api/v1/auth/verification/resend` — fila "M-01"
  /// (spec `musubi-api:HU-03`).
  static const authResend = '/api/v1/auth/verification/resend';

  /// `POST /api/v1/auth/verification/confirm` — fila "M-01"
  /// (spec `musubi-api:HU-03`).
  static const authConfirm = '/api/v1/auth/verification/confirm';

  /// `POST /api/v1/auth/login` — fila "M-01" (spec `musubi-api:HU-02`).
  static const authLogin = '/api/v1/auth/login';

  /// `POST /api/v1/auth/refresh` — fila "M-01" (spec `musubi-api:HU-02`,
  /// contrato de 02-03).
  static const authRefresh = '/api/v1/auth/refresh';

  /// `POST /api/v1/auth/logout` — fila "M-01" (spec `musubi-api:HU-02`).
  static const authLogout = '/api/v1/auth/logout';

  /// `POST /api/v1/auth/password/forgot` — fila "M-01"
  /// (spec `musubi-api:HU-56`).
  static const authPasswordForgot = '/api/v1/auth/password/forgot';

  /// `POST /api/v1/auth/password/reset` — fila "M-01"
  /// (spec `musubi-api:HU-56`).
  static const authPasswordReset = '/api/v1/auth/password/reset';

  /// `GET /api/v1/categories` — fila "M-03" (spec `musubi-api:HU-06`).
  static const categories = '/api/v1/categories';

  /// `GET /api/v1/products` — fila 73 (vitrina publica, HU-48; busqueda,
  /// HU-09, spec `musubi-api:HU-09`) y `POST` (publicar, HU-06).
  static const products = '/api/v1/products';

  /// `POST /api/v1/products/photos` — fila "M-03" (spec `musubi-api:HU-06`).
  static const productPhotos = '/api/v1/products/photos';

  /// `GET /api/v1/products/mine` — fila "M-03" (spec `musubi-api:HU-06`).
  static const myProducts = '/api/v1/products/mine';

  /// `GET /api/v1/favorites` — fila 79 (spec `musubi-api:HU-53`): solo los
  /// favoritos del token, del mas reciente al mas viejo, maximo 200.
  static const favorites = '/api/v1/favorites';

  /// `PUT` y `DELETE /api/v1/favorites/{productId}` — filas 80 y 81
  /// (spec `musubi-api:HU-53`): idempotentes.
  static String favorite(String productId) =>
      '$favorites/${Uri.encodeComponent(productId)}';

  /// `POST /api/v1/account/delete` — fila "M-01" (spec `musubi-api:HU-46`).
  /// Con sesion; pide la contrasena actual.
  static const accountDelete = '/api/v1/account/delete';

  /// `GET /api/v1/products/price-range` — fila "M-03"
  /// (spec `musubi-api:HU-06`).
  static const priceRange = '/api/v1/products/price-range';

  /// `POST /api/v1/auth/password/change` — fila "M-01"
  /// (spec `musubi-api:HU-04`). Con sesion; devuelve una sesion nueva.
  static const authPasswordChange = '/api/v1/auth/password/change';

  /// `GET` y `PUT /api/v1/profiles/me` — filas "M-02"
  /// (spec `musubi-api:HU-04`).
  static const myProfile = '/api/v1/profiles/me';

  /// `PUT /api/v1/profiles/me/visibility` — fila "M-02"
  /// (spec `musubi-api:HU-04`).
  static const myProfileVisibility = '/api/v1/profiles/me/visibility';

  /// `PUT` y `DELETE /api/v1/profiles/me/photo` — filas "M-02"
  /// (spec `musubi-api:HU-04`).
  static const myProfilePhoto = '/api/v1/profiles/me/photo';

  /// `GET /api/v1/careers` — fila "M-02" (spec `musubi-api:HU-04`).
  static const careers = '/api/v1/careers';

  /// `GET /api/v1/conversations` (bandeja, HU-22) y `POST` (iniciar desde una
  /// publicacion, HU-20) — filas "M-07" (specs `musubi-api:HU-20`, `HU-22`).
  static const conversations = '/api/v1/conversations';

  /// `GET /api/v1/conversations/{id}` — fila "M-07" (spec `musubi-api:HU-20`).
  static String conversation(String id) =>
      '$conversations/${Uri.encodeComponent(id)}';

  /// `GET` y `POST /api/v1/conversations/{id}/messages` — filas "M-07"
  /// (spec `musubi-api:HU-20`).
  static String conversationMessages(String id) =>
      '${conversation(id)}/messages';

  /// `POST /api/v1/conversations/{id}/read` — fila "M-07"
  /// (spec `musubi-api:HU-22`).
  static String conversationRead(String id) => '${conversation(id)}/read';

  /// `WS /hubs/chat` — fila "M-07" (spec `musubi-api:HU-20`): solo
  /// WebSockets, sin negociar, con el token en `?access_token=`.
  static const chatHub = '/hubs/chat';

  /// `GET /api/v1/products/{id}` — fila "M-03" (spec `musubi-api:HU-11`):
  /// publico; el vendedor solo viene con sesion.
  static String product(String id) => '$products/${Uri.encodeComponent(id)}';

  /// `GET /api/v1/profiles/{id}` — fila "M-02" (spec `musubi-api:HU-04`;
  /// HU-05 lo amplia): perfil publico, con sesion.
  static String publicProfile(String id) =>
      '/api/v1/profiles/${Uri.encodeComponent(id)}';

  /// `POST /api/v1/wanted` — fila "M-05" (spec `musubi-api:HU-13`); con
  /// `GET`, el tablero "Se busca" (spec `musubi-api:HU-15`).
  static const wanted = '/api/v1/wanted';

  /// `GET` y `PUT /api/v1/wanted/{requestId}/offers/mine` — filas "M-05"
  /// (spec `musubi-api:HU-16`).
  static String myOffer(String requestId) => '$wanted/$requestId/offers/mine';

  /// `GET /api/v1/wanted/{requestId}/offers` — fila "M-05" (spec
  /// `musubi-api:HU-17`).
  static String receivedOffers(String requestId) => '$wanted/$requestId/offers';

  /// `POST /api/v1/wanted/{requestId}/offers/{offerId}/reject`, `accept` y
  /// `chat` — filas "M-05" (spec `musubi-api:HU-17`).
  static String offerAction(String requestId, String offerId, String action) =>
      '$wanted/$requestId/offers/$offerId/$action';

  /// `PUT /api/v1/wanted/{id}` — fila "M-05" (spec `musubi-api:HU-14`).
  static String wantedById(String id) => '$wanted/$id';

  /// `POST /api/v1/wanted/{id}/close` y `cancel` — filas "M-05" (spec
  /// `musubi-api:HU-14`).
  static String wantedAction(String id, String action) => '$wanted/$id/$action';

  /// `GET /api/v1/wanted/mine` — fila "M-05" (spec `musubi-api:HU-13`).
  static const myWanted = '$wanted/mine';

  /// `POST /api/v1/orders` y `GET /api/v1/orders?conversationId=` — filas
  /// "M-08" (spec `musubi-api:HU-23`).
  static const orders = '/api/v1/orders';

  /// `GET /api/v1/orders/meeting-points` — fila "M-08"
  /// (spec `musubi-api:HU-23`).
  static const meetingPoints = '$orders/meeting-points';

  /// `GET /api/v1/orders/{id}` — fila "M-08" (spec `musubi-api:HU-23`).
  static String order(String id) => '$orders/$id';

  /// `PUT /api/v1/orders/{id}/payment` — fila "M-08"
  /// (spec `musubi-api:HU-23`).
  static String orderPayment(String id) => '$orders/$id/payment';

  /// `POST /api/v1/agreements` y `GET /api/v1/agreements?conversationId=` —
  /// filas "M-10" (specs `musubi-api:HU-32`, `HU-33` y `HU-34`).
  static const agreements = '/api/v1/agreements';

  /// `PUT` y `DELETE /api/v1/agreements/{id}` — filas "M-10"
  /// (spec `musubi-api:HU-34`).
  static String agreement(String id) => '$agreements/$id';

  /// `POST /api/v1/agreements/{id}/confirm` — fila "M-10"
  /// (spec `musubi-api:HU-34`).
  static String agreementConfirm(String id) => '$agreements/$id/confirm';

  /// `POST /api/v1/reports` — fila "M-13" (spec `musubi-api:HU-28`).
  static const reports = '/api/v1/reports';

  /// `GET` y `POST /api/v1/blocks` — filas "M-13" (spec `musubi-api:HU-57`).
  static const blocks = '/api/v1/blocks';

  /// `DELETE /api/v1/blocks/{userId}` — fila "M-13"
  /// (spec `musubi-api:HU-57`).
  static String block(String userId) =>
      '$blocks/${Uri.encodeComponent(userId)}';
}
