/// Rutas de musubi-api que consume la app.
///
/// El contrato canonico vive en `musubi-api/docs/endpoints.md`: cada
/// constante cita su fila y aqui nunca se duplican DTOs ni codigos
/// (skill `api-contract`).
abstract final class ApiPaths {
  /// `GET /api/v1/ping` — fila "Plataforma" de musubi-api `docs/endpoints.md`
  /// (spec `musubi-api:01-03`). Respuesta: `{ status: "pong", version: "v1" }`.
  static const ping = '/api/v1/ping';
}
