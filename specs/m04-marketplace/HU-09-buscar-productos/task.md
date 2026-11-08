# HU-09 — Buscar productos por palabra clave (tareas, app)

## T1 — Detallar la spec
- **Qué:** resolver las decisiones, enlazar la fila 73 del contrato y completar `plan.md`.
- **Verificar:** revisión contra `specs/_template.md` y la spec de la contraparte.
- **Estado:** ✅ Hecho (07-Nov-2026).

## T2 — Dominio y datos
- **Crear:** `ProductPage` y `search` en el repositorio, implementación HTTP y demo.
- **Modificar:** `api_paths.dart` (comentario de `products`) y el fake de pruebas.
- **Verificar:** pruebas de `http_catalog_repository_test.dart` y `demo_catalog_repository_test.dart`.
- **Estado:** ✅ Hecho (07-Nov-2026).

## T3 — Estado
- **Crear:** `search_providers.dart` con `SearchState` y `SearchController`.
- **Verificar:** `search_providers_test.dart` (primera página, cargar más, error y limpiar).
- **Estado:** ✅ Hecho (07-Nov-2026).

## T4 — Pantalla y ruta
- **Crear:** `search_screen.dart` con el campo, el contador, el mosaico, los estados y "Cargar más".
- **Modificar:** `router.dart` para que `/buscar` use la pantalla.
- **Verificar:** `search_screen_test.dart` y `navigation_test.dart`.
- **Estado:** ✅ Hecho (07-Nov-2026).

## T4.1 — Buscar al escribir (07-Nov-2026)
- **Qué:** retardo de 300 ms en el campo, consulta inmediata al enviar, respuestas atrasadas descartadas y prefijo en la búsqueda de muestra.
- **Modificar:** `search_screen.dart`, `search_providers.dart`, `demo_catalog_repository.dart`.
- **Verificar:** `search_screen_test.dart`, `search_providers_test.dart`, `demo_catalog_repository_test.dart`.
- **Estado:** ✅ Hecho (07-Nov-2026).

## T5 — Evidencia y documentación
- **Modificar:** `docs/trazabilidad.md` (fila HU-09) y `Memoria.md`.
- **Verificar:** `dart format`, `flutter analyze`, `flutter test` y `critic`.
- **Estado:** ✅ Hecho (07-Nov-2026): 325/325 pruebas, analyze 0 y critic PASS.

## Pendientes con dueño
- `NOTE (HU-10)`: filtros de categoría/precio/condición en la búsqueda.
- `NOTE (HU-12)`: guardar búsqueda y "avísame" en el estado vacío.
- `NOTE (HU-53)`: guardar un producto desde la búsqueda (favoritos); no el historial, que RNF-07 prohíbe.
- `NOTE (HU-09)`: orden por relevancia y coincidencia parcial viven en la API.
