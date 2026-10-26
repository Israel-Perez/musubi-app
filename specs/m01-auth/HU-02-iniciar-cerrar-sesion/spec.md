# HU-02 — Iniciar y cerrar sesión (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-02 / SCRUM-20 / S2 / M-01 / [musubi-api:HU-02](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-02-iniciar-cerrar-sesion)

## Contexto
Pantallas `Iniciar-sesion` e `Iniciar-sesion-error` de la maqueta, más el botón "Cerrar sesión" con su confirmación (pantalla `Ajustes`). La sesión no caduca mientras se use la app (L-16g): el `AuthInterceptor` de 02-01 la renueva con el refresh token. **Depende de**: `02-01`, `HU-01` y `HU-03`.

## Requisitos
1. **Iniciar sesión:**
   - textos: "Hola de nuevo", "Entra con tu correo institucional.", "¿Olvidaste tu contraseña?" y "¿Eres nuevo en Musubi? Crea tu cuenta";
   - el botón se activa con correo y contraseña;
   - al entrar, la guardia del router lleva a `?desde=` (solo rutas internas conocidas) o a Inicio.
2. **Errores:**
   - credenciales incorrectas → aviso "No pudimos iniciar sesión" con el mensaje de la API y la pista "Revisa mayúsculas, minúsculas y números." en la contraseña;
   - sin red o cuenta suspendida → el mismo aviso con su mensaje; el formulario se conserva.
3. **Cuenta sin verificar** (`auth.email_not_verified`): se pide un código nuevo y se abre `Verificacion` con ese correo. Si ya se pidió uno hace menos de 60 s, sirve el que llegó.
4. **Renovación:** `sessionRefresherProvider` usa `POST /api/v1/auth/refresh`. Un 400/401 termina la sesión (pasa a visitante); sin red o con un 5xx la sesión se conserva y la petición falla normal.
5. **Cerrar sesión (L-10):**
   - confirmación "¿Cerrar sesión?" con el texto de la maqueta;
   - se revoca la sesión en la API y se borran los tokens del dispositivo; sin red se cierra igual en el dispositivo;
   - vuelve a Inicio con el aviso "Cerraste sesión. ¡Vuelve pronto!".
6. Si se llegó a "Iniciar sesión" por la guardia, una X lleva a Inicio.

## Diseño
- `lib/core/session/session_api.dart`: `SessionApi` (`refresh`, `revoke`), `HttpSessionApi` sobre `publicDioProvider` y `sessionApiProvider`.
- `SessionController.logOut` (revoca y borra). `signOut` queda como el fin local que usa el interceptor.
- `SessionTokens.fromApi` lee la `SessionResponse` y lo comparten el repositorio y la renovación.
- `AuthRepository.signIn`. Pantallas `sign_in_screen.dart` y `sign_out_button.dart`.
- `lib/features/profile/presentation/profile_screen.dart`: Perfil provisional con "Cerrar sesión" (`NOTE (HU-04)` para el perfil; `NOTE (HU-54)` para mover el botón a `Ajustes`, como en la maqueta).

## Contratos
Filas `POST /api/v1/auth/login`, `POST /api/v1/auth/refresh` y `POST /api/v1/auth/logout` de `musubi-api/docs/endpoints.md` (constantes en `lib/core/network/api_paths.dart`).

## Tests
- `test/features/auth/presentation/session_flow_test.dart` (8 de esta HU):
  - entra y vuelve a la sección que pidió la sesión;
  - credenciales incorrectas;
  - cuenta sin verificar → verificación;
  - sin red;
  - botón habilitado solo con los dos campos;
  - la X lleva a Inicio;
  - cerrar sesión (confirmar y cancelar).
- `test/core/session/session_api_test.dart` (8): refresh (rota, 401, sin red, 500), revoke (204, sin red) y `logOut` (con y sin red).
- `test/features/auth/data/http_auth_repository_test.dart`: login (forma de sesión y error tipado).
- Self-tests (21-Oct-2026):
  - si el refresh devuelve `null` ante cualquier error, fallan los casos "sin red" y "500";
  - si `logOut` no revoca, falla "confirma, revoca en la API y vuelve a Inicio".

## Criterios
- `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 124/124 · critic PASS · Semgrep 0 · APK de debug OK.

## Límites
- Si no hay red al cerrar sesión, el refresh token sigue vivo en el servidor hasta que vence (60 días), pero ya no existe en el dispositivo.
- El perfil real llega con HU-04.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 21-Oct-2026
- **Detalle:** Sprint movido de S1 a S2 (sprint activo en Jira).
