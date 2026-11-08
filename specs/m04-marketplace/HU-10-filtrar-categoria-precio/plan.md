# plan.md — HU-10 Filtrar por categoría, precio y estado (app)

1. **Componentes:**
   - `lib/features/marketplace/domain/search_filter.dart`: `SearchFilter` y `ProductConditionFilter`.
   - `lib/features/marketplace/domain/catalog_repository.dart`: `search` con filtro y `categories()`.
   - `lib/features/marketplace/data/http_catalog_repository.dart`: parámetros nuevos y `categories()`.
   - `lib/features/marketplace/data/demo_catalog_repository.dart`: filtros locales.
   - `lib/features/marketplace/presentation/search_providers.dart`: estado con filtro, `applyFilter` y vista previa.
   - `lib/features/marketplace/presentation/search_filter_sheet.dart`: hoja de filtros.
   - `lib/features/marketplace/presentation/search_screen.dart`: botón y globo.
   - `lib/features/marketplace/presentation/home_providers.dart`: `categoriesProvider`.
   - `lib/core/widgets/musubi_text_field.dart`: `prefixText` opcional.
   - Pruebas: `test/helpers/fake_catalog_repository.dart`, `http_catalog_repository_test`, `demo_catalog_repository_test`, `search_providers_test`, `search_screen_test`, `search_filter_sheet_test`.

2. **Decisiones:**
   - **`SearchFilter` separado de `CatalogFilter`:** Inicio sigue con su hoja y la búsqueda tiene su propio estado.
   - **Precio en pesos en la UI y centavos en la API:** sin flotantes y alineado con `priceCents`.
   - **La API filtra; la app no:** coincidencias, `total` y cursor salen del back. La vista previa reutiliza la misma consulta.
   - **Sin “Ocultar agotados” en la búsqueda:** con `q` la API ya excluye agotados (HU-09).
   - **Sin “Más relevantes”:** Jira no lo pide y la API ordena por fecha; `NOTE (HU-10)`.
   - **Categorías por `categoriesProvider`:** la hoja no depende de `homeFeed`.
   - **La X del campo no borra los filtros:** el globo sigue visible; `Limpiar` es la acción explícita.

3. **Excepciones al stack:** ninguna.

4. **Guardarraíles:**
   - Validación local de precio (0 a 999,999 pesos; mínimo ≤ máximo) y validación del back.
   - El repositorio traduce `DioException` a `ApiFailure`; la UI no importa Dio.
   - Ninguna excepción de red llega a la UI.
   - Los filtros se descartan al salir; no se persisten.
   - La categoría y el estado se envían solo si están definidos.

5. **Validación:**
   - `flutter test test/features/marketplace/http_catalog_repository_test.dart`
   - `flutter test test/features/marketplace/demo_catalog_repository_test.dart`
   - `flutter test test/features/marketplace/search_providers_test.dart`
   - `flutter test test/features/marketplace/search_screen_test.dart`
   - `flutter test test/features/marketplace/search_filter_sheet_test.dart`
   - `flutter test`
   - `dart format`, `flutter analyze`, `pwsh scripts/critic-guardrails.ps1`.
   - Revisión con `security-reviewer` y `traceability-clerk`.

6. **Secuencia:** contrato y dominio → data HTTP/demo/fake → estado y vista previa → hoja → botón y pantalla → pruebas → documentación y verificación.
