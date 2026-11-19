# 02-10 — Cierre de brechas de la evaluación (app)

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) / SCRUM-120, SCRUM-121 (suite en el teléfono) / S5 / Plataforma / [musubi-api:02-10](https://github.com/Israel-Perez/musubi-api/tree/main/specs/phase-02-architecture/02-10-cierre-evaluacion)

## Contexto
El documento "Prompts para evaluar v1" (16-Nov-2026) pregunta qué pantallas que consumen endpoints no tienen pruebas de integración o de seguridad. En la revisión del 17-Nov-2026 la app tenía:

- 813 pruebas unitarias y de widget, todas con repositorios falsos;
- una sola prueba de integración (el arranque), que no corría en el CI ni llamaba a la API;
- 5 pruebas de seguridad (la configuración de Android).

**Depende de:** `musubi-api:02-10` (revocación del access token) y `02-05` (CI).

## Requisitos
1. **Integración contra la API real.** Cada flujo de pantallas que consume endpoints tiene pruebas con los proveedores reales de la app: repositorios HTTP, Dio, `AuthInterceptor` y sesión. Corren contra musubi-api en Development (en memoria): cuentas reales con el código que la API escribe en su log, fotos, chat en tiempo real por el hub y acuerdo con IA simulada.
2. **Guard de cobertura.** `tool/check_integration_coverage.dart` revisa que cada fila de `musubi-api/docs/endpoints.md` que consume `musubi-app` se haya llamado en alguna prueba. Una HU nueva que agrega una llamada sin su prueba rompe el CI. Las excepciones se documentan con su motivo.
3. **Seguridad de la sesión en el teléfono** (`test/security/session_security_test.dart`):
   - solo los archivos de sesión tocan los tokens;
   - nada los guarda fuera del almacén seguro ni registra peticiones;
   - un error nunca muestra el token;
   - el token solo viaja al esquema y host de la API;
   - prod y staging usan HTTPS.
4. **Seguridad contra la API** (`test/integration/security_flow_test.dart`):
   - un access token copiado antes del logout ya no sirve;
   - un token alterado se rechaza y la sesión termina;
   - un visitante no entra a lo privado;
   - nadie lee el pedido o el apartado de otra persona (404).
6. **Suite en un teléfono físico** ("Auditoría de evaluación v2", sección 3). `scripts/run_device_tests.ps1` hace todo con el teléfono conectado por USB:
   - levanta la API en la PC y la expone con `adb reverse`;
   - sirve los códigos de verificación (`tool/device_code_server.dart`);
   - corre `integration_test/app_test.dart`, con 8 pruebas de pantallas reales: cuenta, sesión persistente, cerrar sesión, eliminar cuenta, buscar y chatear, apartar, publicar con foto y moderación.
5. **El logout manda el access token** a `POST /auth/logout` para que la API lo revoque de inmediato (antes solo mandaba el refresh token).

## Diseño
- `test/integration/support/live_api.dart`:
  - `LiveSession`: un `ProviderContainer` con la configuración `dev` hacia la API local y un almacén en memoria;
  - `liveUser()` y `liveAdmin()`: registro, código del log y verificación;
  - `livePhoto()`: un PNG de 400 × 300.
  - Un interceptor anota cada `VERBO /ruta`, un archivo por proceso.
- `test/integration/support/live_flows.dart`: publicar, abrir el chat y hacer un pedido.
- Sin `MUSUBI_API_URL` las pruebas se saltan: `flutter test` no depende de la API.
- `scripts/run_integration_tests.ps1` levanta la API, corre la suite y el guard. El job `integration` del CI lo usa, con la rama de musubi-api del mismo nombre si existe (si no, `main`).
- La llave de pagos se genera al vuelo (32 bytes aleatorios); no es un secreto.

## Contratos
- Sin rutas nuevas. `HttpSessionApi.revoke(refreshToken, accessToken:)` agrega `Authorization: Bearer` solo en esa petición: es el cliente sin interceptor y va siempre a la API.

## Tests
- `test/integration/`:
  - `session_flow_test.dart` (7);
  - `profile_flow_test.dart` (5);
  - `sell_flow_test.dart` (4);
  - `marketplace_flow_test.dart` (6);
  - `chat_flow_test.dart` (5);
  - `orders_flow_test.dart` (6);
  - `wanted_flow_test.dart` (2);
  - `community_flow_test.dart` (2);
  - `admin_flow_test.dart` (4);
  - `security_flow_test.dart` (4).
- `test/integration/device_flows_test.dart` (8): los flujos del teléfono en la VM.
- `integration_test/app_test.dart` (8, en el teléfono): `flows/start_flow.dart`, `account_flow.dart`, `explore_flow.dart` y `sell_flow.dart`.
- `test/security/session_security_test.dart` (9).
- `test/core/session/session_api_test.dart`: el logout manda el access token.

## Criterios
- [x] 53 pruebas de integración en verde contra la API (45 de datos + 8 de pantallas).
- [ ] La suite del teléfono, corrida en un teléfono físico (pendiente de conectar uno).
- [x] `check_integration_coverage`: OK, con 121 filas llamadas y 1 excepción documentada (`POST /notifications/devices/remove`).
- [x] `flutter analyze` sin observaciones, `dart format` sin cambios y critic PASS.

## Límites
- El CI no tiene teléfono: corre los flujos de pantallas en la VM (`device_flows_test.dart`). La suite en el teléfono se corre a mano con `run_device_tests.ps1`.
- `POST /notifications/devices/remove`: al cerrar sesión la app da de baja el teléfono en FCM, y la API borra el token en el siguiente envío (HU-31).

## Aprobación y Control de Cambios
- **Estado:** Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 17-Nov-2026
- **Detalle:** cierra los puntos 1 y 3 de la revisión contra "Prompts para evaluar v1"; el 2 (logout) junto con `musubi-api:02-10`.
