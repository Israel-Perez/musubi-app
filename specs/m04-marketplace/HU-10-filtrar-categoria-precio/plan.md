# plan.md — HU-10 Filtrar por categoría y precio (app)

1. **Componentes:**
   - `lib/features/marketplace/domain/home_feed.dart`: `CatalogFilter` con `minPriceCents`, `maxPriceCents` y `condition`; `count`, `==` y `hashCode`.
   - `lib/features/marketplace/domain/catalog_repository.dart`: `search` acepta `filter`; nuevo `categories()`.
   - `lib/features/marketplace/data/http_catalog_repository.dart`: parámetros del filtro y `categories()` sobre `ApiPaths.categories`.
   - `lib/features/marketplace/data/demo_catalog_repository.dart`: rango, estado, categoría y agotados sobre los datos de muestra; `categories()`.
   - `lib/features/marketplace/presentation/search_providers.dart`: `SearchState.filter`, `applyFilter`, `searchCategoriesProvider` y `searchFilterPreviewProvider`.
   - `lib/features/marketplace/presentation/search_filter_sheet.dart`: hoja `Busqueda-filtros`.
   - `lib/features/marketplace/presentation/filter_button.dart`: botón con globo extraído de `home_screen.dart`.
   - `lib/features/marketplace/presentation/search_screen.dart`: botón, hoja, vacío con filtros y reintento con filtros.
   - `lib/core/network/api_paths.dart`: comentarios de `products` y `categories`.
   - `test/helpers/fake_catalog_repository.dart` y pruebas de data, estado, hoja y pantalla.

2. **Decisiones:**
   - **Filtro dentro de `SearchState`, no en `catalogFilterProvider`:** el filtro de Inicio y el de la búsqueda son independientes y el de la búsqueda muere al salir (RNF-07). Evita limpiar el estado de Inicio al cerrar `/buscar`.
   - **Una categoría y pastillas de texto:** el contrato acepta un `category`; la maqueta marca una pastilla y no carga fotos en esta hoja.
   - **Categorías bajo demanda:** `categories()` reusa la fila 72 para que `/buscar` funcione abierto directo; el mapeo se extrae de `homeFeed` y no se duplica.
   - **Precio en pesos en la UI y centavos en el repositorio:** misma unidad que `priceCents`; la validación de rango ocurre antes de la petición y el `400` queda como defensa.
   - **Borrador en la hoja y aplicación al CTA:** igual que la hoja de Inicio; X no aplica y "Limpiar" solo reinicia el borrador.
   - **Preview por `total`:** el `items.length` de una página de 20 no sirve como cuenta; el preview se pide con el texto vigente y el borrador.
   - **Filtrar sin texto:** el controlador consulta si hay texto o filtros; el estado inicial solo aparece sin ambos.
   - **Botón reutilizado:** se extrae `_FilterButton` para no duplicar el globo ni la semántica; la clave cambia por pantalla.

3. **Guardarraíles:**
   - El repositorio traduce `DioException` a `ApiFailure`; la UI nunca importa Dio.
   - La app no filtra ni ordena en el cliente (RNF-09): envía parámetros y pinta la respuesta.
   - El rango se valida en el cliente (`0…999999` pesos y mínimo ≤ máximo) y se envía en centavos; los `400` se muestran en español.
   - `categories()` y los filtros no se guardan ni se registran (RNF-07).
   - Cada prueba de data usa `FakeHttpAdapter`; ninguna toca la red.
   - `NOTE (HU-12)`, `NOTE (HU-13)` y `NOTE (HU-53)` donde ya están, para lo diferido.

4. **Validación:**
   - `flutter test test/features/marketplace/http_catalog_repository_test.dart`
   - `flutter test test/features/marketplace/demo_catalog_repository_test.dart`
   - `flutter test test/features/marketplace/search_providers_test.dart`
   - `flutter test test/features/marketplace/search_filter_sheet_test.dart`
   - `flutter test test/features/marketplace/search_screen_test.dart`
   - `flutter test`
   - `dart format --output=none --set-exit-if-changed .` y `flutter analyze --fatal-infos --fatal-warnings` sin cambios.
   - `pwsh scripts/critic-guardrails.ps1` → PASS.
   - Revisión del diff con `security-reviewer` y de la trazabilidad con `traceability-clerk`.
   - Prueba manual en el celular: abrir `/buscar`, filtrar por categoría y precio, vacío con filtros y "Cargar más".

5. **Rama y secuencia:**
   - Rama `feature/SCRUM-27-filtrar-categoria-precio`, desde `feature/SCRUM-26-buscar-productos` mientras HU-09 (PR `musubi-app#32`) no se fusione.
   - PR en borrador con las specs; la implementación entra en el mismo PR cuando la rama de HU-09 esté en `main`.
   - Secuencia: contrato y dominio → data + demo + fake → estado y preview → hoja y botón → pantalla → pruebas → capturas, documentación y verificación.

6. **Excepciones al stack:** ninguna. Se usan `MusubiTextField`, `MusubiSwitch`, `Pressable`, `MusubiButton` y `showMusubiSheet` ya existentes.

7. **Riesgos:** el orden de merge `musubi-api#49` → `#50` y `musubi-app#32` → HU-10; si el contrato cambia (varias categorías u orden por precio), se ajusta esta spec antes de implementar.
