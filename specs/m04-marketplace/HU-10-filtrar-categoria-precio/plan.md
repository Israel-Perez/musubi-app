# plan.md — HU-10 Filtrar por categoría, precio y estado (app)

1. **Componentes:**
   - `lib/features/marketplace/domain/search_filter.dart`: `SearchFilter` (categorías múltiples) y `ProductConditionFilter`.
   - `lib/features/marketplace/domain/search_sort.dart`: `SearchSort`.
   - `lib/features/marketplace/domain/catalog_repository.dart`: `search({query, filter, sort, page})` y `categories()`.
   - `lib/features/marketplace/data/http_catalog_repository.dart`: parámetros nuevos (incluidos `sort` y `page`) y `categories()`.
   - `lib/features/marketplace/data/demo_catalog_repository.dart`: filtros, orden y sin texto.
   - `lib/features/marketplace/presentation/search_providers.dart`: `SearchState` (filtro, orden, página), `applyFilter`, `setSort`, `goToPage`, `clear`, `searchHistoryProvider` y vista previa.
   - `lib/features/marketplace/presentation/search_filter_sheet.dart`: hoja de filtros con histograma reactivo, slider 0–$2,000+, interruptor de agotados y toast.
   - `lib/features/marketplace/presentation/search_screen.dart`: lista todo al entrar, botón y globo, cabecera con píldora, orden, historial y paginación.
   - `lib/features/marketplace/presentation/home_screen.dart`: el botón `Filtrar` navega a `/buscar?filtros=1`.
   - `lib/features/marketplace/presentation/home_providers.dart`: `categoriesProvider`.
   - `lib/core/widgets/musubi_text_field.dart`: `prefixText` opcional.
   - Pruebas: `test/helpers/fake_catalog_repository.dart`, `http_catalog_repository_test`, `demo_catalog_repository_test`, `search_providers_test`, `search_screen_test`, `search_filter_sheet_test`, `home_screen_test`.

2. **Decisiones:**
   - **Un solo lugar para los filtros:** Inicio delega en la hoja de `/buscar`; `CatalogFilter` y `filter_sheet.dart` se retiran.
   - **Precio en pesos en la UI y centavos en la API:** sin flotantes y alineado con `priceCents`.
   - **La API filtra y pagina; la app no:** coincidencias, `total` y páginas salen del back. La vista previa reutiliza la misma consulta.
   - **Categorías múltiples:** los chips se acumulan y se envían como `category=slug1,slug2`.
   - **“Ocultar agotados” en la búsqueda:** `hideSoldOut=false` incluye los agotados aunque haya `q`.
   - **Orden en la app:** `relevant`, `recent`, `priceAsc` y `priceDesc`; `relevant` comparte el orden de `recent` hasta que exista puntaje (`NOTE (HU-09)`).
   - **Paginación por `page`:** 20 por página; buscar, filtrar u ordenar vuelven a la página 1.
   - **Historial de la sesión:** máximo 5, en memoria (RNF-07).
   - **La X del campo no borra los filtros:** el globo sigue visible; `Limpiar` es la acción explícita.

3. **Excepciones al stack:** ninguna.

4. **Guardarraíles:**
   - Validación local de precio (0 a $999,999; mínimo ≤ máximo) y validación del back (`invalid_price_range`, `invalid_sort`, `invalid_page`).
   - El repositorio traduce `DioException` a `ApiFailure`; la UI no importa Dio.
   - Ninguna excepción de red llega a la UI.
   - Los filtros y el historial se descartan al salir; no se persisten.
   - La categoría, el orden y el estado se envían solo cuando existen.
   - El descarte de respuestas atrasadas se conserva al cambiar texto, filtro, orden o página.

5. **Validación:**
   - `flutter test test/features/marketplace/http_catalog_repository_test.dart`
   - `flutter test test/features/marketplace/demo_catalog_repository_test.dart`
   - `flutter test test/features/marketplace/search_providers_test.dart`
   - `flutter test test/features/marketplace/search_screen_test.dart`
   - `flutter test test/features/marketplace/search_filter_sheet_test.dart`
   - `flutter test test/features/marketplace/home_screen_test.dart`
   - `flutter test`
   - `dart format`, `flutter analyze`, `pwsh scripts/critic-guardrails.ps1`.
   - Revisión con `security-reviewer` y `traceability-clerk`.

6. **Secuencia:** contrato y dominio → data HTTP/demo/fake → estado, orden, historial y vista previa → hoja → pantalla, cabecera y paginación → Inicio → pruebas → documentación y verificación.
