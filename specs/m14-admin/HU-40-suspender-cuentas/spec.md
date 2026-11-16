# HU-40 — Suspender y reactivar cuentas (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-40 / SCRUM-63 / Sprint 5 / M-14 / [musubi-api:HU-40](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-40-suspender-cuentas)

## Contexto
Jira (SCRUM-63): Como **administrador**, quiero **suspender cuentas que incumplan las reglas**, para **proteger a la comunidad**.

- Maqueta: sin pantalla propia (lineamiento 4). Trazabilidad: RF-55 · CU-25 · RN-27 · RNF-04.
- Va con HU-39: el diseño y las decisiones están en [`../HU-39-moderar-contenido/plan.md`](../HU-39-moderar-contenido/plan.md).
- **Depende de:** `HU-39` (la bandeja y la hoja del reporte), `HU-02` (la cuenta suspendida ya veía "Tu cuenta está suspendida" al iniciar sesión).

## Requisitos
1. La pantalla "Cuenta" (desde la persona responsable de un reporte o desde "Suspendidas") muestra:
   - el nombre, el estado y si es administradora;
   - los reportes procedentes y la fecha de alta;
   - el historial de moderación, con quién, cuándo y el motivo.
2. Con 3 reportes procedentes o más se ve "Se sugiere suspenderla" (RN-27); la decisión es del administrador.
3. "Suspender cuenta" abre una hoja con el motivo, obligatorio y de hasta 500 caracteres. Sin motivo no se envía.
4. "Reactivar cuenta" pide confirmación y avisa que sus publicaciones siguen pausadas.
5. Una cuenta de administración no muestra "Suspender".
6. "Suspendidas" lista las cuentas suspendidas del campus.

## Diseño
`AdminAccountScreen` y `SuspendAccountSheet` en `lib/features/admin/presentation/admin_account_screen.dart`; la pestaña "Suspendidas" en `AdminScreen`; `adminAccountProvider` y `suspendedAccountsProvider`.

## Contratos
Filas "M-14" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`GET /admin/accounts/suspended`, `GET /admin/accounts/{id}`, `POST`/`DELETE /admin/accounts/{id}/suspension`), enlazadas desde `ApiPaths.adminSuspendedAccounts`, `adminAccount` y `adminSuspension`. Formas de `admin-account.json` y `admin-account-page.json`.

## Tests
- `test/features/admin/http_admin_repository_test.dart`: suspender (motivo sin espacios), reactivar (`DELETE`), el historial y las suspendidas.
- `test/features/admin/admin_flow_test.dart`: la sugerencia de RN-27, el motivo obligatorio, suspender, "Suspendidas" y "Reactivar" con confirmación.

## Criterios
- [x] El administrador puede suspender y reactivar cuentas: `admin_flow_test` ("el motivo es obligatorio", "Reactivar confirma").
- [x] Con 3 reportes procedentes se sugiere suspender (RN-27): `admin_flow_test` (`admin-suggestion`).
- [x] Las suspensiones quedan registradas (RNF-04): el historial de "Cuenta"; la bitácora vive en la API.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 800/800 (13 nuevas: 8 de flujo y 5 del repositorio, con HU-51 incluida) · critic PASS (16-Nov-2026).

## Límites
- La suspensión no tiene fecha de fin y a la persona suspendida no se le avisa: lo ve al iniciar sesión.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 revisor distinto del autor)
- **Fecha:** 16-Nov-2026
- **Detalle:** RN-27 como sugerencia con 3 procedentes (decisión para revisar). Necesita la API `0.5.0-alpha.38`.
