# plan.md — HU-09 Buscar productos por palabra clave (app)

1. **Componentes:**
   - `lib/features/marketplace/domain/home_feed.dart`: `ProductPage`.
   - `lib/features/marketplace/domain/catalog_repository.dart`: `search`.
   - `lib/features/marketplace/data/http_catalog_repository.dart` y `demo_catalog_repository.dart`: implementación.
   - `lib/features/marketplace/presentation/search_providers.dart`: `SearchState` y `SearchController`.
   - `lib/features/marketplace/presentation/search_screen.dart`: pantalla.
   - `lib/app/router.dart` y `lib/core/network/api_paths.dart`.
   - `test/helpers/fake_catalog_repository.dart` y pruebas de data, estado y pantalla.

2. **Decisiones:**
   - **Buscar mientras se escribe con 300 ms de retardo:** evita una petición por carácter y aprovecha la coincidencia por prefijo de la API; enviar consulta de inmediato.
   - **Descartar respuestas atrasadas:** cada `search` lleva un número de petición y solo la última puede cambiar el estado.
   - **Paginación con cursor y "Cargar más":** no se pierde ningún resultado y la API ya devuelve `nextCursor`.
   - **Estado en un `AsyncNotifier`:** la pantalla distingue cargando, datos, vacío y error sin mezclar banderas; `loadMore` conserva las tarjetas si falla.
   - **Sin filtros en esta HU:** `Busqueda-filtros` es de HU-10 y su contador actual cuenta la vitrina, no la búsqueda.
   - **Sin historial local:** RNF-07 prohíbe persistir `q`; el historial queda para HU-53.
   - **Se reutilizan `RecentTile` y `ProductPhoto`:** el mosaico y las tarjetas ya son las de la maqueta; `RecentTile` muestra el título en dos líneas como `Busqueda`.

3. **Guardarraíles:**
   - El repositorio traduce `DioException` a `ApiFailure`; la UI nunca importa Dio.
   - `q` se recorta y se limita a 80 en el campo; el texto no se guarda ni se registra.
   - Cada prueba de data usa `FakeHttpAdapter`; ninguna prueba toca la red.
   - `NOTE (HU-12)` y `NOTE (HU-53)` en la pantalla para lo diferido.

4. **Validación:**
   - `flutter test test/features/marketplace/http_catalog_repository_test.dart`
   - `flutter test test/features/marketplace/search_providers_test.dart`
   - `flutter test test/features/marketplace/search_screen_test.dart`
   - `flutter test`
   - `dart format` y `flutter analyze` sin cambios.
   - Revisión del diff con `security-reviewer` y de la trazabilidad con `traceability-clerk`.

5. **Secuencia:** contrato y dominio → data + demo → fake → estado → pantalla y ruta → pruebas → documentación y verificación.
