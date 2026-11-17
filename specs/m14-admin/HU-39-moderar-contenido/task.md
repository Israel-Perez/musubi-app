# HU-39 — Revisar reportes y moderar contenido (tareas, app)

## T1 — Detallar la spec
- **Qué:** decisiones, pantallas y contratos (`plan.md`).
- **Estado:** ✅ Hecho (16-Nov-2026).

## T2 — Datos y estado
- **Qué:** `admin_models.dart`, `AdminRepository`, `HttpAdminRepository`, `admin_providers.dart`, `SessionTokens.isAdmin` y `ApiPaths` "M-14".
- **Pruebas:** `test/features/admin/http_admin_repository_test.dart`.
- **Estado:** ✅ Hecho.

## T3 — Pantallas
- **Qué:** `AdminScreen`, `showAdminReportSheet`, la fila "Administración" de `Ajustes` y las rutas.
- **Pruebas:** `test/features/admin/admin_flow_test.dart`.
- **Estado:** ✅ Hecho.

## T4 — Documentación
- **Qué:** `docs/trazabilidad.md`, `docs/versionado.md` (fila compartida `0.5.0-alpha.38`), `AGENTS.md` y `Memoria.md` (T59).
- **Estado:** ✅ Hecho.

## T5 — Celular
- **Qué:** probar con una cuenta en `Admin:Emails` contra la API `0.5.0-alpha.38` desplegada.
- **Estado:** ⏳ Pendiente.
