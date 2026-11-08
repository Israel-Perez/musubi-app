# HU-10 — Filtrar por categoría, precio y estado (tareas, app)

## T1 — Detallar la spec
- **Qué:** resolver decisiones, enlazar la fila 73 y completar `plan.md`.
- **Verificar:** revisión contra `specs/_template.md` y `musubi-api:HU-10`.
- **Estado:** ✅ Hecho (07-Nov-2026).

## T2 — Dominio y datos
- **Crear:** `SearchFilter`, `ProductConditionFilter`, `categories()` y los parámetros de `search`.
- **Modificar:** repositorio HTTP, demo y fake.
- **Verificar:** `http_catalog_repository_test.dart`, `demo_catalog_repository_test.dart`.
- **Estado:** ✅ Hecho (08-Nov-2026).

## T3 — Estado
- **Crear:** `SearchState.filter`, `applyFilter` y `searchPreviewProvider`.
- **Verificar:** `search_providers_test.dart`.
- **Estado:** ✅ Hecho (08-Nov-2026).

## T4 — Hoja y pantalla
- **Crear:** `search_filter_sheet.dart`.
- **Modificar:** `search_screen.dart` (botón, globo, paso del filtro) y `musubi_text_field.dart` (`prefixText`).
- **Verificar:** `search_filter_sheet_test.dart`, `search_screen_test.dart`.
- **Estado:** ✅ Hecho (08-Nov-2026).

## T5 — Evidencia y documentación
- **Modificar:** `docs/trazabilidad.md` y `Memoria.md`.
- **Verificar:** `dart format`, `flutter analyze`, `flutter test` y critic.
- **Estado:** ✅ Hecho (08-Nov-2026).

## Pendientes con dueño
- `NOTE (HU-10)`: selector “Más relevantes” cuando la API tenga orden por relevancia.
- `NOTE (HU-09)`: con `q` la API excluye agotados; “Ocultar agotados” sigue solo en Inicio.
