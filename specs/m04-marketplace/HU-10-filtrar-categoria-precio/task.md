# HU-10 — Filtrar por categoría, precio y estado (tareas, app)

## T1 — Detallar la spec
- **Qué:** resolver decisiones, enlazar la fila 73 y completar `plan.md`.
- **Verificar:** revisión contra `specs/_template.md` y `musubi-api:HU-10`.
- **Estado:** ✅ Hecho (07-Nov-2026).

## T2 — Dominio y datos
- **Crear:** `SearchFilter` (categorías múltiples), `ProductConditionFilter`, `SearchSort`, `categories()` y `search({query, filter, sort, page})`.
- **Modificar:** repositorio HTTP, demo y fake.
- **Verificar:** `http_catalog_repository_test.dart`, `demo_catalog_repository_test.dart`.
- **Estado:** ✅ Hecho (08-Nov-2026).

## T3 — Estado
- **Crear:** `SearchState` (filtro, orden, página), `applyFilter`, `setSort`, `goToPage`, `clear`, `searchHistoryProvider` y `searchPreviewProvider`.
- **Verificar:** `search_providers_test.dart`.
- **Estado:** ✅ Hecho (08-Nov-2026).

## T4 — Hoja, pantalla e Inicio
- **Crear:** `search_filter_sheet.dart` (chips en fila, histograma reactivo, slider 0–$2,000+, agotados y toast).
- **Modificar:** `search_screen.dart` (lista al entrar, globo, cabecera, orden, historial y paginación), `home_screen.dart` (hoja `Filtrar` de Inicio con globo) y `musubi_text_field.dart` (`prefixText`).
- **Verificar:** `search_filter_sheet_test.dart`, `search_screen_test.dart`, `home_screen_test.dart`.
- **Estado:** ✅ Hecho (08-Nov-2026).

## T5 — Evidencia y documentación
- **Modificar:** `docs/trazabilidad.md` y `Memoria.md`.
- **Verificar:** `dart format`, `flutter analyze`, `flutter test` y critic.
- **Estado:** ✅ Hecho (08-Nov-2026).

## Pendientes con dueño
- `NOTE (HU-09)`: `relevant` ordena como `recent` hasta que la API calcule puntaje.
- El historial de búsquedas vive solo en la sesión; no se persiste (RNF-07). HU-53 no agrega almacenamiento local.
- `NOTE (HU-12)`: las acciones del estado vacío (guardar búsqueda) no están en esta HU.
