# HU-10 — Filtrar por categoría y precio (tareas, app)

## T1 — Detallar la spec
- **Qué:** completar `spec.md` y `plan.md` con requisitos, contrato, pruebas y límites; dejar `task.md` operativo.
- **Verificar:** revisión contra `specs/_template.md`, la maqueta `Busqueda-filtros` (`docs/maqueta/musubi-prototipo.html`), la fila 73 de `musubi-api/docs/endpoints.md` y la spec de la contraparte.
- **Estado:** ✅ Hecho (07-Nov-2026; revisada contra la maqueta).

## T2 — Dominio y datos
- **Modificar:** `CatalogFilter` (`minPriceCents`, `maxPriceCents`, `condition`, `count`, `==`), `CatalogRepository.search` con `filter` y nuevo `categories()`.
- **Modificar:** `http_catalog_repository.dart` (parámetros y `categories()`) y `demo_catalog_repository.dart` (rango, estado, categoría, agotados y `categories()`).
- **Modificar:** `api_paths.dart` (comentarios de `products` y `categories`).
- **Verificar:** `http_catalog_repository_test.dart` y `demo_catalog_repository_test.dart`.
- **Estado:** ⏳ Pendiente.

## T3 — Estado y preview
- **Modificar:** `search_providers.dart` (`SearchState.filter`, `applyFilter`, `loadMore` con filtro, consulta sin texto, `searchCategoriesProvider`, `searchFilterPreviewProvider`).
- **Modificar:** `test/helpers/fake_catalog_repository.dart` (filtro registrado y `categories()`).
- **Verificar:** `search_providers_test.dart`.
- **Estado:** ⏳ Pendiente.

## T4 — Hoja y botón
- **Crear:** `search_filter_sheet.dart` (`Busqueda-filtros` con `showMusubiPanel`) y `filter_button.dart` extraído de `home_screen.dart`.
- **Modificar:** `home_screen.dart` para usar el botón extraído con `Key('home-filter')`.
- **Verificar:** `search_filter_sheet_test.dart` y `home_screen_test.dart`.
- **Estado:** ⏳ Pendiente.

## T5 — Pantalla
- **Modificar:** `search_screen.dart` (botón con globo, `openFilters`, apertura de la hoja, vacío con filtros, "Reintentar" con filtros).
- **Modificar:** `home_screen.dart` (el ícono de filtros del buscador abre `/buscar` con `extra: true` y se retira su `NOTE (HU-10)`) y `router.dart` (pasar `extra` a `SearchScreen`).
- **Verificar:** `search_screen_test.dart` y `navigation_test.dart`.
- **Estado:** ⏳ Pendiente.

## T6 — Evidencia y documentación
- **Modificar:** `docs/trazabilidad.md` (fila HU-10) y `Memoria.md`; capturas de `Busqueda-filtros` en `tool/screenshots_test.dart` si cambia la lista de escenas.
- **Verificar:** `dart format`, `flutter analyze`, `flutter test`, `critic` y prueba en el celular.
- **Estado:** ⏳ Pendiente.

## Pendientes con dueño
- `NOTE (HU-12)`: guardar búsqueda, "avísame" y "Ver opciones" en el estado vacío.
- `NOTE (HU-13)`: "Pídelo a tu campus" desde el vacío.
- `NOTE (HU-53)`: almacenamiento local de productos; los filtros no se guardan por RNF-07.
- `NOTE (HU-10)`: los de `search_screen.dart` y `home_screen.dart` los resuelve esta spec; se retiran en T5/T4.
