# HU-39 — Revisar reportes y moderar contenido (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-39 / SCRUM-62 / Sprint 5 / M-14 / [musubi-api:HU-39](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-39-moderar-contenido)

## Contexto
Jira (SCRUM-62): Como **administrador**, quiero **revisar los reportes**, para **retirar contenido falso o inapropiado**.

- Maqueta: sin pantalla propia. Se arma con piezas de la maqueta (lineamiento 4: se agrega, no se quita): las pestañas de `Notificaciones`, las tarjetas y grupos de `Ajustes` y las hojas `UI.sheet` de `reportSheet`.
- Trazabilidad: RF-54 · CU-24 · RNF-03, RNF-04. Va con HU-40 en el mismo PR.
- **Depende de:** `HU-28` (los reportes), `02-03` (sesión), `02-04` (piezas de la maqueta).

## Requisitos
1. "Administración" aparece en `Ajustes` solo si la sesión tiene el rol `admin` (el `role` del access token; la API vuelve a revisarlo en cada acción).
2. "Abiertos" y "Revisados" listan los reportes del campus con el motivo, lo reportado, el detalle y la fecha.
3. Al tocar un reporte, la hoja muestra lo reportado, quién reportó, el detalle, la persona responsable con sus reportes procedentes (y "considera suspender" con 3 o más) y, si sigue abierto, una nota interna opcional y dos acciones:
   - "Retirar publicación" (pide confirmación), "Es procedente" o "Marcar como atendido", según lo reportado;
   - "Descartar".
4. Al moderar se cierra la hoja, sale un aviso y las bandejas se vuelven a pedir. Un error de la API (por ejemplo, otro administrador ya lo revisó) se muestra en la hoja.
5. Desde la persona responsable se abre su cuenta (HU-40).

## Diseño
- `lib/features/admin/`:
  - `domain/`: `admin_models.dart` y `AdminRepository`.
  - `data/`: `HttpAdminRepository`.
  - `presentation/`: `admin_providers.dart` (con `isAdminProvider`), `AdminScreen`, `admin_report_sheet.dart`, `AdminAccountScreen` (HU-40) y `admin_widgets.dart`.
- `SessionTokens.isAdmin` / `rolesOf` leen el `role` del JWT, igual que `userId` lee el `sub`: no se guarda nada nuevo y se actualiza con cada renovación.
- Rutas `AppRoutes.settingsAdmin` (`/ajustes/administracion`) y `AppRoutes.adminAccount(id)`, con sesión.

## Contratos
Filas "M-14" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`GET /admin/reports`, `POST /admin/reports/{id}/resolution`), enlazadas desde `ApiPaths.adminReports` y `adminReportResolution`. Formas de `admin-report-page.json`.

## Tests
- `test/features/admin/http_admin_repository_test.dart`: lectura de la bandeja (forma del fixture), la acción con la nota sin espacios (y sin nota si va vacía), errores con su código y el rol leído del token.
- `test/features/admin/admin_flow_test.dart`:
  - Sin el rol no hay "Administración"; con el rol abre la bandeja.
  - "Retirar publicación" confirma, cierra y pasa a "Revisados"; "Descartar".
  - Un reporte ya revisado; vacío y "Reintentar".

## Criterios
- [x] El administrador ve los reportes con su motivo y el elemento reportado: `admin_flow_test` ("con el rol abre la bandeja").
- [x] Puede retirar el contenido reportado o descartar el reporte: `admin_flow_test` ("Retirar publicación" y "Descartar").
- [x] Solo el administrador ve la moderación (RNF-03): "sin el rol no hay Administración"; la API responde 403 a cualquier otra cuenta (`musubi-api:HU-39`).
- [x] Las acciones quedan registradas (RNF-04): en la API (`moderationLog`); la app muestra la revisión y el historial de la cuenta.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 800/800 (13 nuevas: 8 de flujo y 5 del repositorio, con HU-51 incluida) · critic PASS (16-Nov-2026).

## Límites
- La bandeja muestra los 50 reportes más recientes (límite de la API).
- La app muestra "Administración" cuando el token ya trae el rol: después de que se lo den, la persona tiene que volver a iniciar sesión o esperar la siguiente renovación (15 minutos).
- No hay capturas de maqueta para estas pantallas.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 revisor distinto del autor)
- **Fecha:** 16-Nov-2026
- **Detalle:** la spec ligera del 29-Oct-2026 se detalló con HU-40. Necesita la API `0.5.0-alpha.38`.
