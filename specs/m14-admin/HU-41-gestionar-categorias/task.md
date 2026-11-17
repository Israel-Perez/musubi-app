# HU-41 — Gestionar categorías (tareas)

## T1 — Detallar la spec
- **Qué:** enlazar las filas `GET`/`POST /admin/categories` y `PATCH /admin/categories/{slug}` y completar `plan.md`.
- **Estado:** ✅ Hecho (16-Nov-2026).

## T2 — Dominio y datos
- **Qué:** `AdminCategory` y `HttpAdminRepository.categories`, `createCategory` y `updateCategory`, con su prueba.
- **Estado:** ✅ Hecho.

## T3 — Pantallas
- **Qué:** "Categorías" en `Ajustes` → "Administración", `AdminCategoriesScreen` y `CategorySheet`, con widget tests (9).
- **Estado:** ✅ Hecho. Sin maqueta: se armó con las piezas de "Administración".

## T4 — Evidencia y documentación
- **Qué:** `docs/trazabilidad.md`, `docs/versionado.md` (fila compartida `0.5.0-alpha.39`), `AGENTS.md` y `Memoria.md`.
- **Estado:** ✅ Hecho. Falta la prueba en el celular con la API `0.5.0-alpha.39` desplegada.
