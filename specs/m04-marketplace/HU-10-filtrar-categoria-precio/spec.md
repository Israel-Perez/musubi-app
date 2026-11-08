# HU-10 — Filtrar por categoría y precio (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-10 / SCRUM-27 / S2 / M-04 / [musubi-api:HU-10 (rama de #50)](https://github.com/Israel-Perez/musubi-api/tree/feature/SCRUM-27-filtrar-categoria-precio/specs/m04-marketplace/HU-10-filtrar-categoria-precio)

## Contexto

Jira (SCRUM-27): como **comprador**, quiero **filtrar los resultados por categoría y precio**, para **descartar lo que no me sirve**.

- Maqueta: `Busqueda-filtros` y `Busqueda` (sección 3 del índice); el vacío con filtros reusa la forma visual de `Busqueda-vacia` sin sus acciones (HU-12/HU-13).
- Trazabilidad: RF-13 · CU-06 · RNF-07 (lado API; el front lo refleja) · RNF-09 · RNF-27 · L-04.
- Origen: Propuesta inicial §11.
- La API ya implementa el filtro sobre `GET /api/v1/products` (fila 73 de `musubi-api/docs/endpoints.md`, PR `musubi-api#50`, apilado sobre `#49` de HU-09). La app consume esa fila; no hay fake ni `NOTE (musubi-api:HU-10)`.

**Depende de:** `02-01`, `02-04` (piezas de la maqueta), `HU-06` (categorías), `HU-09` (búsqueda), `HU-11` (detalle) y `HU-48` (vitrina). Depende de `musubi-api:HU-10` y, por el orden de merge, de `musubi-api:HU-09`.

## Requisitos

1. `/buscar` muestra el botón "Filtros" de 48 × 48 junto al campo, con globo del número de filtros activos (categoría, rango de precio, estado y "Ocultar agotados"). Sin filtros es gris; con filtros usa el fondo rojo claro de la maqueta. El área táctil mide al menos 44 (RNF-27) y el lector anuncia "Filtros" sin filtros, o "Filtros, 1 activo" / "Filtros, N activos" con filtros (RNF-18, L-04).
2. El botón abre la hoja `Busqueda-filtros`: título "Filtros", X que cierra **sin aplicar**, categorías, "Rango de precio" (Mínimo y Máximo), "Estado" como control segmentado (Todos / Nuevo / Usado), "Ocultar agotados", "Limpiar" y "Ver N resultados".
3. Las categorías se leen de `GET /api/v1/categories` (fila 72) y se muestran como pastillas de la maqueta. Se elige **una** categoría; "Todo" la quita. La selección se marca con fondo, borde y palomita, no solo con color, y se anuncia como seleccionada (accesibilidad).
4. El rango de precio se captura en **pesos enteros** con prefijo `$` y solo dígitos, y se envía en **centavos** (`× 100`). Ambos extremos son inclusivos y pueden venir solos. Cada valor va de `$0` a `$999,999`; el mínimo no puede ser mayor que el máximo. Un rango inválido muestra el texto en español y **no llama a la API**.
5. "Estado" envía `condition=new` o `condition=used`; "Todos" lo quita. El control es el segmentado de la maqueta, de 44 de alto, con cada opción anunciada como seleccionada.
6. Los filtros se combinan con `q` (HU-09), `category`, `hideSoldOut`, `cursor` y `limit` en la misma petición. La app **no filtra ni ordena en el cliente**: envía los parámetros de la fila 73 y pinta la respuesta.
7. Aplicar el borrador reinicia el cursor, conserva el texto actual y consulta de inmediato, sin esperar el retardo de 300 ms. Con el texto vacío y al menos un filtro activo, la búsqueda sí consulta y muestra el catálogo filtrado.
8. "Cargar más" repite los filtros aplicados y conserva las tarjetas si la página falla.
9. El CTA muestra "Ver N resultados" con el `total` real de `/products` para el texto actual y el borrador. Mientras llega la cuenta muestra "Ver resultados"; si la cuenta falla, el botón sigue aplicando el filtro.
10. Sin resultados y con filtros activos, el vacío usa el copy de `Busqueda-vacia`: "Sin resultados para «texto»" (o "Sin resultados" si no hay texto), "Prueba quitando algún filtro o busca con otras palabras." y "Quitar filtros". Sin filtros conserva el vacío de HU-09. Las acciones de `Busqueda-vacia` (guardar búsqueda, avisar, pedir, "Ver opciones") no entran aquí: son HU-12 y HU-13.
11. El ícono de filtros junto al buscador de Inicio (maqueta `Inicio`) abre `/buscar` con la hoja `Busqueda-filtros` ya abierta, sin texto ni filtros aplicados. Conserva su área táctil de al menos 44 (hoy mide 52 × 52) y se anuncia "Filtros".
12. `400 listings.invalid_price_range`, `400 listings.invalid_condition`, `5xx` o un fallo de red muestran el mensaje en español y "Reintentar"; ninguna excepción de red llega a la UI.
13. Los filtros y el texto viven solo en memoria: al salir de `/buscar` se descartan y no se guardan en el dispositivo (RNF-07). Reabrir la pantalla empieza limpio.
14. Sin regresiones: la hoja "Filtrar" de Inicio sigue igual y sus pruebas pasan; el único cambio en Inicio es abrir `/buscar` con la hoja pedida.
15. Mientras llegan las categorías, la hoja muestra un indicador; si `/categories` falla, muestra un mensaje en español con "Reintentar" y el resto de los filtros sigue usable.

RNF que aplican: RNF-07 (regla de la API; el front no persiste), RNF-09 (resultados con indicador de carga), RNF-27 (toques de 44 y sin overflow), RNF-18 (mensajes en español) y L-04 (fidelidad a la maqueta).

## Diseño

- `domain/home_feed.dart`: `CatalogFilter` gana `minPriceCents`, `maxPriceCents` y `condition` (`new`/`used`), conserva `category` y `hideSoldOut`, y su `count` cuenta los cuatro bloques activos. `==` y `hashCode` incluyen los campos nuevos.
- `domain/catalog_repository.dart`:
  - `search({required String query, String? cursor, CatalogFilter filter = const CatalogFilter()})`;
  - `categories()`, para la hoja cuando `/buscar` se abre sin pasar por Inicio.
- `data/http_catalog_repository.dart`: manda `category`, `minPriceCents`, `maxPriceCents`, `condition` y `hideSoldOut` solo cuando están activos; reusa `ProductPage` y `productFromJson`. `categories()` sobre `ApiPaths.categories`. Extrae el mapeo de categorías que hoy vive en `homeFeed`.
- `data/demo_catalog_repository.dart`: aplica rango inclusivo, estado, categoría y agotados sobre los datos de muestra, en las mismas condiciones que la API; `categories()` devuelve el catálogo ficticio.
- `presentation/search_providers.dart`:
  - `SearchState` gana `filter` (y ajusta `empty`/`hasQuery` a "hay texto **o** filtros");
  - `SearchController.search` acepta el filtro; `applyFilter(CatalogFilter)` re-consulta el texto actual reiniciando el cursor; `loadMore` repite `state.filter`; `clear` sigue limpiando todo;
  - `searchCategoriesProvider`: `FutureProvider.autoDispose` sobre `categories()`, para la hoja;
  - `searchFilterPreviewProvider`: `FutureProvider.autoDispose.family<int, SearchPreview>` con `SearchPreview { query, filter }`, devuelve el `total`.
- `presentation/search_filter_sheet.dart`: `showSearchFilterSheet(context)` con `showMusubiPanel` + `MusubiPanel` (título y X, como las hojas con acciones de la casa), `Key('search-filter-sheet')`, categorías desde `searchCategoriesProvider`, dos `MusubiTextField` numéricos (`FilteringTextInputFormatter.digitsOnly`) que convierten pesos a centavos, control segmentado de estado (`Key('search-condition')`, patrón de `_Segments` en `inbox_screen.dart`), `MusubiSwitch`, "Limpiar" y CTA con `searchFilterPreviewProvider` en `MusubiPanel.actions`.
- `presentation/filter_button.dart`: se extrae el botón con globo que hoy es `_FilterButton` en `home_screen.dart`. Acepta `key`, `count`, `onTap`, `active`, `size` y `semanticLabel`; Inicio conserva 44/"Filtrar" y su look actual (`Key('home-filter')`), y la búsqueda usa 48/"Filtros", fondo rojo claro con `count > 0` (`Key('search-filter')`).
- `presentation/search_screen.dart`: botón de filtros en la fila superior, apertura de la hoja, vacío con filtros y "Reintentar" con el texto y los filtros aplicados. Recibe `openFilters` (desde `GoRouterState.extra == true`) y abre la hoja en el primer frame.
- `app/router.dart`: la ruta de `/buscar` pasa `openFilters` desde `state.extra`; `home_screen.dart` conserva su ícono de filtros junto al buscador y lo abre con `extra: true`.
- `core/network/api_paths.dart`: los comentarios de `products` y `categories` citan también HU-10.

Decisiones:

- **Un solo filtro de búsqueda, separado del de Inicio.** `catalogFilterProvider` sigue gobernando "Recién publicados"; la búsqueda usa el filtro dentro de `SearchState`, que es `autoDispose` y muere al salir (RNF-07).
- **Una categoría.** La fila 73 acepta un `category`; la maqueta permite marcar varias pastillas. Varias categorías exigirían cambiar el contrato.
- **Categorías desde `/categories`, no desde `homeFeed`.** `/buscar` se abre directo; pedir la vitrina entera solo por el catálogo sería más caro y con más estados.
- **Precio en pesos y centavos en el borde.** La persona escribe pesos; la hoja convierte a centavos al armar el `CatalogFilter`, la misma unidad de `priceCents`. La validación en el cliente evita un viaje con `400`.
- **Filtros aplicados al confirmar, no en cada toque.** La hoja trabaja sobre un borrador; solo el CTA cambia la búsqueda, como la hoja de Inicio.
- **El preview usa `total`, no `items.length`.** Con `limit=20` una página no refleja el total real; `filterPreviewProvider` de Inicio mide otra cosa y no se reutiliza.
- **Filtrar sin texto es válido.** La API lo permite y evita una pantalla muerta; el vacío distingue "sin resultados" de "sin filtros".

## Contratos

- Fila canónica: [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) → `GET /api/v1/products`, fila 73, con `?category=&q=&minPriceCents=&maxPriceCents=&condition=&hideSoldOut=&cursor=&limit=`. Se enlaza, no se copia.
- Categorías: misma tabla, `GET /api/v1/categories`, fila 72. Se enlaza la forma; no se copia el DTO.
- La app valida rango y estado antes de llamar; si la API responde con error, muestra su mensaje en español y "Reintentar". Catálogo de errores en [`musubi-api/docs/errores.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/errores.md).
- Semántica de los parámetros: [`musubi-api:HU-10`](https://github.com/Israel-Perez/musubi-api/tree/feature/SCRUM-27-filtrar-categoria-precio/specs/m04-marketplace/HU-10-filtrar-categoria-precio).
- Orden de dependencia: `musubi-api#49` (HU-09) antes de `musubi-api#50` (HU-10); la app no se fusiona antes que esas filas. Mientras `#50` siga en borrador, la fila 73 con los parámetros nuevos se lee en su rama.

## Tests

- `test/features/marketplace/http_catalog_repository_test.dart`:
  - `search` manda `q`, `category`, `minPriceCents`, `maxPriceCents`, `condition` y `hideSoldOut` juntos, y omite los inactivos;
  - `search` sin texto manda solo los filtros;
  - `400 listings.invalid_price_range`, `400 listings.invalid_condition`, `5xx` y sin red llegan como `ApiFailure` con su `code`;
  - `categories()` parsea `slug` y `name` y traduce el error de red.
- `test/features/marketplace/demo_catalog_repository_test.dart`:
  - rango inclusivo (extremos dentro, un centavo fuera) y un solo extremo;
  - estado `new`/`used`, categoría y agotados combinados con el texto;
  - sin texto y con filtro devuelve el catálogo filtrado.
- `test/features/marketplace/search_providers_test.dart`:
  - aplicar un filtro reinicia la página y conserva el texto;
  - "Cargar más" repite el filtro aplicado;
  - texto vacío con filtro consulta y llena el estado;
  - quitar los filtros vuelve al estado inicial;
  - una respuesta atrasada o un error conservan la regla de HU-09.
- `test/features/marketplace/search_filter_sheet_test.dart`:
  - una sola categoría seleccionada, "Todo" la quita y "Limpiar" reinicia el borrador;
  - cada pastilla y opción del control segmentado expone `Semantics(selected)`;
  - mínimo mayor que máximo y valor fuera de `$999,999` muestran error, no consultan el preview y no aplican;
  - el control segmentado marca una sola opción y Estado y "Ocultar agotados" viajan al filtro;
  - X cierra sin cambiar el filtro aplicado;
  - el CTA muestra el total del preview y aplica al confirmar;
  - si `/categories` falla, muestra mensaje y "Reintentar".
- `test/features/marketplace/search_screen_test.dart`:
  - botón con globo 0/1/N, fondo gris/rojo claro, anuncio "Filtros" o "Filtros, N activos" y hoja con el texto y el filtro vigentes;
  - aplicar filtro refresca resultados y contador sin perder el texto y sin esperar el retardo de 300 ms;
  - vacío con filtros muestra "Sin resultados para «texto»", el subtítulo de la maqueta y "Quitar filtros";
  - `5xx` y sin red muestran mensaje y "Reintentar";
  - filtrar sin texto muestra el catálogo filtrado;
  - al volver y reabrir no conserva texto ni filtros.
- `test/features/marketplace/home_screen_test.dart`: el ícono de filtros del buscador abre `/buscar` con la hoja `Busqueda-filtros` visible; el botón extraído sigue con `Key('home-filter')` y su globo.
- `test/helpers/fake_catalog_repository.dart`: `search` recibe y registra `filter`; `categories()` devuelve el catálogo de prueba.

## Criterios

- [ ] Tocar "Filtros", elegir "Libros" y aplicar llama a `GET /api/v1/products` con `category=libros` y el texto vigente (`search_filter_sheet_test`, `http_catalog_repository_test`).
- [ ] El ícono de filtros de Inicio abre `/buscar` con la hoja `Busqueda-filtros` visible (`home_screen_test`).
- [ ] Cada pastilla y cada opción del control segmentado se anuncia como seleccionada (`search_filter_sheet_test`).
- [ ] Con filtros activos el botón del encabezado se ve con fondo rojo claro y anuncia "Filtros, N activos"; sin filtros, gris y "Filtros" (`search_screen_test`).
- [ ] El estado es un control segmentado: "Usado" envía `condition=used`, "Todos" lo omite y una sola opción queda marcada (`search_filter_sheet_test`).
- [ ] "Ver N resultados" usa el `total` de la API con el borrador y el texto actual (`search_filter_sheet_test`).
- [ ] Escribir mínimo `600` y máximo `100` muestra el error en español y no llama a la API (`search_filter_sheet_test`).
- [ ] Un rango válido envía `minPriceCents` y `maxPriceCents` en centavos e incluye los extremos (`demo_catalog_repository_test`, `http_catalog_repository_test`).
- [ ] "Estado: Usado" envía `condition=used`; "Todos" lo omite (`search_filter_sheet_test`, `http_catalog_repository_test`).
- [ ] Los filtros se combinan con `q`, categoría, agotados y paginación (`search_providers_test`, `demo_catalog_repository_test`).
- [ ] "Cargar más" mantiene los filtros aplicados (`search_providers_test`).
- [ ] Sin texto y con filtro se consulta el catálogo filtrado (`search_providers_test`, `search_screen_test`).
- [ ] El vacío con filtros muestra "Sin resultados para «texto»", el subtítulo de la maqueta y permite quitarlos (`search_screen_test`).
- [ ] Si `/categories` falla, la hoja muestra mensaje y "Reintentar", y el resto de filtros sigue usable (`search_filter_sheet_test`).
- [ ] `listings.invalid_price_range`, `listings.invalid_condition`, `5xx` y sin red muestran mensaje y "Reintentar" (`search_screen_test`, `http_catalog_repository_test`).
- [ ] Al reabrir `/buscar` no hay texto ni filtros (`search_screen_test`).
- [ ] `dart format --output=none --set-exit-if-changed .` sin cambios.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` sin observaciones.
- [ ] `flutter test` al 100 % con el conteo real del cierre (sin inventarlo aquí).
- [ ] `pwsh scripts/critic-guardrails.ps1` → PASS.
- [ ] Prueba manual en el celular de la hoja `Busqueda-filtros` y del vacío con filtros.

## Límites

- **Una sola categoría:** la fila 73 acepta un `category`; varias exigen cambiar la API. La maqueta permite marcar más de una pastilla: se respeta el contrato y se documenta la diferencia.
- **Sin deslizante de precio:** la maqueta trae un control con dos pulgares además de los campos. Esta spec usa solo Mínimo y Máximo (mismo dato, menos código); si se pide igualar el gesto, se agrega después sin cambiar el contrato.
- **Control segmentado local:** se replica el patrón de `_Segments` de `inbox_screen.dart` dentro de la hoja. Si aparece un tercer control segmentado, se extrae a `lib/core/widgets/`.
- **Decisión (07-Nov-2026) — sin selector de orden:** "Más relevantes" de `Busqueda` no se implementa; requiere un parámetro de orden que la API no tiene. Se omite hasta que exista esa fila.
- **La hoja "Filtrar" de Inicio no cambia:** sigue con categoría y agotados; esta HU solo agrega la hoja de `/buscar` y el `extra` del ícono del buscador.
- **Acciones del vacío:** guardar búsqueda, "avísame" y "Ver opciones" son HU-12 (`NOTE (HU-12)`); "Pídelo a tu campus" queda fuera de esta HU (HU-13). Aquí solo se ofrece quitar filtros.
- **Decisión (07-Nov-2026) — búsquedas recientes:** no se implementan. RNF-07 es regla de persistencia del back; el front no las guarda. Si el PO las pide en memoria, se abre una spec de M-04.
- **Pastillas de filtros aplicados:** la maqueta deja un manejador `rmfilter` sin pastillas visibles en `Busqueda`; no se agregan.
- **Historial y filtros guardados:** no existen; RNF-07 prohíbe persistir la búsqueda. El almacenamiento local es HU-53 (`NOTE (HU-53)`).
- **Notas de código:** no quedan `NOTE (HU-10)`; se retiraron en T4 y T5.
- **Categorías sin foto en la hoja:** la maqueta usa pastillas de texto; no se cargan fotos.
- **Categoría desconocida:** la API devuelve página vacía, no `400`; la app solo envía slugs del catálogo.
- **RNF-09:** el p95 se mide en la API (spec de la contraparte); la app solo muestra la carga.
- **Sesión:** los filtros son públicos y no requieren cuenta.

## Aprobación y Control de Cambios

- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 07-Nov-2026
- **Detalle:** implementada y probada (07-Nov-2026): 345 pruebas en verde, `flutter analyze` sin observaciones y `critic` PASS. Faltan la revisión de un integrante y la prueba manual en el celular. Se acuerdan categoría única, precio en pesos convertido a centavos, condición `new`/`used`, filtros combinados con `q` y preview por `total`. Revisión contra la maqueta `Busqueda-filtros` (07-Nov-2026): botón de 48 con estado rojo claro, hoja con `showMusubiPanel`, estado segmentado, copy del vacío y RNF corregidos (RNF-27/L-04); se documentan las diferencias de la maqueta (varias categorías, deslizante de precio, búsquedas recientes y selector de orden). La contraparte está en la rama apilada de `musubi-api`.
