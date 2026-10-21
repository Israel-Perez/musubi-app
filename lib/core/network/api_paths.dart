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
}
