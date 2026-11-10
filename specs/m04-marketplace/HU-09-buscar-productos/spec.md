# HU-09 — Buscar productos por palabra clave (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-09 / SCRUM-26 / S2 / M-04 / [musubi-api:HU-09](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-09-buscar-productos)

## Contexto

Jira (SCRUM-26): como **comprador**, quiero **buscar productos por nombre o palabra clave**, para **encontrar rápido lo que necesito**.

- Maqueta: `Busqueda` y `Busqueda-vacia` (sección 3 del índice). `Busqueda-filtros` es de HU-10.
- Trazabilidad: RF-12 · CU-06 · RNF-09 · RNF-07.
- Origen: Propuesta inicial §11.
- La API ya implementó la búsqueda sobre `GET /api/v1/products?q=` (07-Nov-2026). La app consume esa fila; no hay fake ni `NOTE (musubi-api:HU-09)`.

**Depende de:** `02-01`, `02-04` (piezas de la maqueta), `HU-06`, `HU-48` (vitrina) y `HU-11` (detalle).

## Requisitos

1. `/buscar` abre una pantalla con el campo de búsqueda enfocado, el botón de regreso y el botón de borrar cuando hay texto.
2. Mientras se escribe, tras **300 ms** sin una tecla nueva, se consulta `GET /api/v1/products?q=<texto>&limit=20` con `dioProvider` (sesión opcional). Enviar con el teclado fuerza la consulta inmediata.
3. La consulta se recorta antes de enviarse. Si queda vacía, vuelve a listar todo el catálogo (HU-10).
4. La app **no filtra ni ordena en el cliente**: la API decide disponibilidad, coincidencia por prefijo de palabra, orden por fecha y `total`.
5. Con resultados se muestra "N resultados en UTTT" (`1 resultado` en singular) y un mosaico de dos columnas con las tarjetas de la vitrina.
6. Cada tarjeta abre el detalle de la publicación (HU-11) y conserva el corazón de guardar; para un visitante, guardar abre la hoja "Crea tu cuenta" (HU-48). Con sesión, el corazón llama a `PUT`/`DELETE /favorites` en HU-53 (`NOTE (HU-53)`).
7. `200` con `items: []` muestra el estado vacío con el texto buscado: "Sin resultados para «q»" y una invitación a probar otras palabras.
8. `400 listings.invalid_query`, `5xx` o un fallo de red muestran el mensaje en español y "Reintentar"; ninguna excepción de red llega a la UI.
9. Los resultados se paginan por número de página, 20 por página (HU-10); un error al cambiar de página muestra el mensaje y "Reintentar".
10. `q` no se guarda, registra ni manda a analítica (RNF-07).
11. La primera búsqueda muestra un indicador de carga inmediato; las siguientes conservan las tarjetas anteriores mientras llega la nueva respuesta, y una respuesta atrasada se descarta. Los objetivos táctiles miden al menos 44 (RNF-12 y accesibilidad).
12. Sin regresiones: formato, análisis, pruebas y critic en verde.

RNF que aplican: RNF-07 (búsqueda privada), RNF-09 (respuesta aceptable), RNF-12 (carga) y RNF-18 (mensajes en español).

## Diseño

- `domain/home_feed.dart`: `ProductPage { items, total, nextCursor }`, la página del catálogo que la API ya devuelve.
- `domain/catalog_repository.dart`: `search({query, filter, sort, page})` (HU-10). Lanza `ApiFailure`, nunca `DioException`.
- `data/http_catalog_repository.dart`: implementación sobre `ApiPaths.products`; usa `productFromJson` y el `limit` de búsqueda.
- `data/demo_catalog_repository.dart`: búsqueda local sobre los datos de muestra, para `DEMO_CATALOG` y pruebas; aproxima el prefijo de palabra y el orden por fecha.
- `presentation/search_providers.dart`:
  - `SearchState { query, filter, sort, items, total, page }`;
  - `SearchController extends AsyncNotifier<SearchState>` con `search`, `goToPage` y `clear` (HU-10);
  - cada `search` lleva un número de petición: una respuesta que llega después de otra búsqueda se ignora;
  - `searchControllerProvider` sin el reintento automático de Riverpod 3: la pantalla trae "Reintentar".
- `presentation/search_screen.dart`: campo compacto de la maqueta con búsqueda al escribir (retardo de 300 ms), cabecera con píldora `UTTT`, `RecentTile`, estados cargando, vacío y error, y paginación por página (HU-10).
- `app/router.dart`: `/buscar` deja de ser `UpcomingSection` y pasa a `SearchScreen`.
- `core/network/api_paths.dart`: el comentario de `products` cita también HU-09.

Decisiones:

- **Buscar mientras se escribe, con retardo.** 300 ms sin teclas evitan una petición por carácter; enviar con el teclado consulta de inmediato. La API ya coincide por prefijo de palabra.
- **Conservar las tarjetas anteriores y descartar respuestas viejas.** Al escribir rápido, la respuesta de una consulta anterior no puede pisar la nueva; solo la primera búsqueda muestra la pantalla de carga.
- **Una sola pantalla y un estado propio.** No se reutiliza el filtro de Inicio: la búsqueda tiene su propio texto y su propia paginación.
- **Los filtros llegan con HU-10.** `Busqueda-filtros`, el orden y el historial son de HU-10; esta HU entrega la búsqueda por texto y su paginación.

## Contratos

- Fila canónica: [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) → `GET /api/v1/products`, fila 73. Se enlaza, no se copia.
- Parámetros usados por esta HU: `q`, `limit` y `page` (HU-10). La respuesta es `ProductPage`, la misma de la vitrina.
- Semántica de `q` y códigos de error: [`musubi-api:HU-09`](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-09-buscar-productos). La app solo distingue por `code` (`listings.invalid_query`, red, `5xx`).
- RNF-07: el texto buscado no se persiste ni se registra en la app.

## Tests

- `test/features/marketplace/http_catalog_repository_test.dart`:
  - `search` manda `q` recortado, `limit` y `page` (HU-10);
  - lee `items`, `total` y `nextCursor`;
  - `400 listings.invalid_query`, `5xx` y sin red llegan como `ApiFailure` con su `code`;
- `test/features/marketplace/search_providers_test.dart`:
  - la primera página llena el estado;
  - `goToPage` pide esa página y conserva el `total` (HU-10);
  - mientras llega la nueva búsqueda conserva las tarjetas anteriores;
  - una respuesta atrasada no pisa la búsqueda nueva;
  - un error deja el estado en `AsyncError` o conserva las tarjetas al paginar;
  - limpiar vuelve a listar el catálogo.
- `test/features/marketplace/search_screen_test.dart`:
  - al entrar lista todo el catálogo con el campo enfocado;
  - escribir busca tras 300 ms y reinicia el retardo con cada tecla;
  - borrar el texto vuelve a listar el catálogo;
  - al volver y reabrir la pantalla no conserva la búsqueda;
  - un 400 y un 5xx muestran su mensaje y "Reintentar";
  - cargando, resultados, vacío, error y "Reintentar";
  - enviar consulta, borrar y paginar;
  - el contador en singular y plural;
  - regresar, abrir el detalle y guardar como visitante (hoja de cuenta).
- `test/features/marketplace/demo_catalog_repository_test.dart`: la búsqueda de muestra excluye agotados, coincide por prefijo y no por infijo.
- `test/app/navigation_test.dart`: `/buscar` ya no muestra el texto provisional de `UpcomingSection`.

## Criterios

- [x] Escribir "calc" (sin enviar) llama a `GET /api/v1/products` con `q=calc` y `limit=20` tras 300 ms, y muestra las tarjetas (`search_screen_test`, `http_catalog_repository_test`).
- [x] Una respuesta atrasada no pisa los resultados de la consulta nueva (`search_providers_test`).
- [x] Al volver y reabrir `/buscar` no conserva texto ni resultados (`search_screen_test`).
- [x] Una página vacía muestra "Sin resultados para «…»" (`search_screen_test`).
- [x] `listings.invalid_query`, `5xx` y sin red muestran mensaje y "Reintentar" (`search_screen_test`, `http_catalog_repository_test`).
- [x] La paginación pide la página elegida y conserva el total (`search_providers_test`, `search_screen_test`; HU-10).
- [x] `q` no se guarda ni se registra (revisión de `search_screen.dart` y `search_providers.dart`; RNF-07).
- [x] `dart format --output=none --set-exit-if-changed .` sin cambios (07-Nov-2026).
- [x] `flutter analyze --fatal-infos --fatal-warnings` sin observaciones (07-Nov-2026).
- [x] `flutter test` al 100 % con el conteo real (07-Nov-2026: 325/325; 08-Nov-2026: 349/349).
- [x] `pwsh scripts/critic-guardrails.ps1` → PASS (07-Nov-2026: 21 archivos, 0 avisos).

## Límites

- **Filtros, orden e historial:** llegan con HU-10 (`Busqueda-filtros`).
- **Acciones del vacío (guardar búsqueda, avisarme, publicar necesidad):** HU-12 y HU-13. Aquí solo se garantiza el estado vacío correcto (`NOTE (HU-12)`).
- **Historial de búsquedas:** HU-10 muestra hasta 5 de la sesión; no se persiste (RNF-07). HU-53 decidió el 08-Nov-2026 no agregar almacenamiento local.
- **Orden:** el selector es de HU-10; `relevant` ordena como `recent` hasta que la API calcule puntaje (`NOTE (HU-09)`).
- **Coincidencia por prefijo:** `calc`, `calcula` y `CASI` encuentran la calculadora; `culadora` no, porque el prefijo debe iniciar la palabra. El infijo queda como `NOTE (HU-09)` en el back.
- **Agotados:** con `q` la API los oculta salvo `hideSoldOut=false` (HU-10); la app no los filtra en el cliente.
- **RNF-09:** el p95 se mide en la API; la app solo muestra la carga de inmediato.
- **Sesión:** la búsqueda es pública; guardar exige cuenta y abre la hoja de HU-48.

## Aprobación y Control de Cambios

- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 07-Nov-2026
- **Detalle:** se detalla al iniciar la HU. La API ya está implementada y verificada (07-Nov-2026). Se difieren los filtros a HU-10 y las acciones del vacío a HU-12/HU-13.
