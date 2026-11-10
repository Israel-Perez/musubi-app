# HU-10 — Filtrar por categoría, precio y estado (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-10 / SCRUM-27 / S2 / M-04 / [musubi-api:HU-10](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-10-filtrar-categoria-precio)

## Contexto

Jira (SCRUM-27): como **comprador**, quiero **filtrar los resultados por categoría y precio**, para **descartar lo que no me sirve**.

- Maqueta: `Busqueda` y `Busqueda-filtros` (sección 3 del índice). `Busqueda-vacia` es de HU-12.
- Trazabilidad: RF-13 · CU-06 · RNF-12 · RNF-17 · RNF-18 · RNF-27.
- La API implementa los filtros en `GET /api/v1/products` (fila 73) en el mismo PR (`musubi-api:HU-10`).

**Depende de:** `02-01`, `02-04`, `HU-09` y `musubi-api:HU-10`.

## Requisitos

1. `/buscar` muestra un botón de filtros (`slidersHorizontal`) a la derecha del campo, con globo cuando hay filtros activos.
2. El botón abre la hoja `Busqueda-filtros`: título, X, categorías, rango de precio, estado y acciones.
3. Las categorías son de selección múltiple; tocar una elegida la quita. Los chips salen de `GET /api/v1/categories` y se envían repitiendo `category` (HU-10).
4. El precio se elige con el control deslizante de dos pulgares (tope $2,000+, que significa sin límite superior) y se puede escribir en pesos (`Mínimo` y `Máximo`); la app lo convierte a centavos. Los límites son inclusivos y vacío significa sin límite.
5. El histograma de precio cambia de color según el rango elegido.
6. Si el mínimo es mayor que el máximo, la hoja muestra el mensaje en español y no aplica ni llama a la API.
7. El estado es `Todos`, `Nuevo` o `Usado`; se envía como `condition` (`null`, `new`, `used`).
8. `Ocultar agotados` (encendido por defecto) se envía como `hideSoldOut`; apagado muestra también los agotados.
9. El globo cuenta categoría + rango de precio + estado + agotados visibles (máximo 4).
10. Al entrar a `/buscar` se listan todas las publicaciones (sin texto ni filtros) y se conserva el descarte de respuestas atrasadas.
11. Aplicar los filtros relanza la búsqueda con el texto actual; sin texto, muestra el catálogo filtrado.
12. Los resultados se paginan por número de página (`page`, 20 por página) con flechas y números; `Limpiar`, un filtro o un orden vuelven a la página 1. `total` y páginas los decide la API.
13. El CTA dice `Ver N resultados` con una vista previa (300 ms de retardo), también sin texto si hay filtros. Si la vista previa falla, dice `Ver resultados`; sin texto ni filtros, no consulta.
14. La cabecera de resultados dice `N resultados en` con la píldora `UTTT`, como la maqueta, y a la derecha el orden actual (`Más relevantes`).
15. El orden se elige en una hoja `Ordenar por` con `Más relevantes`, `Más recientes`, `Menor precio` y `Mayor precio`; al cambiarlo se relanza la búsqueda con el texto y los filtros actuales.
16. `/buscar` guarda hasta 5 búsquedas de la sesión (sin persistirlas, RNF-07): chips tocables y `Limpiar` a la derecha, visibles arriba de los resultados.
17. Inicio conserva su propia hoja `Filtrar` (categoría y "Ocultar agotados", con el globo del conteo), como la maqueta; la búsqueda tiene la suya con precio, estado y orden.
18. `Limpiar` en la hoja avisa con un toast `Filtros borrados`.
19. Al salir de `/buscar` se limpia todo (`autoDispose`). La X del campo borra el texto y conserva los filtros (vuelve a mostrar el catálogo filtrado); `Limpiar` de la hoja borra los filtros.
20. Las categorías se acomodan en fila, con varias por renglón, como la maqueta.
21. Sin regresiones: formato, análisis, pruebas y critic en verde.

## Diseño

- `domain/search_filter.dart`: `SearchFilter` (con `categories`, `minCents`, `maxCents`, `condition`, `hideSoldOut`), con `count`, `isEmpty` y `==`/`hashCode`; `ProductConditionFilter` (`all`, `newItem`, `used`) aporta la etiqueta y el `apiValue`.
- `domain/search_sort.dart`: `SearchSort` (`relevance`, `newest`, `priceAsc`, `priceDesc`) con su etiqueta y `apiValue`.
- `domain/catalog_repository.dart`: `search({query, filter, sort, page})` y `categories()`.
- `data/http_catalog_repository.dart`: envía `category` (varias separadas por coma), `minPriceCents`, `maxPriceCents`, `condition`, `hideSoldOut`, `sort`, `q`, `limit` y `page`; `categories()` lee fila 72.
- `data/demo_catalog_repository.dart`: búsqueda local con categoría, precio inclusivo, condición y agotados; sin texto devuelve el catálogo filtrado.
- `presentation/search_providers.dart`: `SearchState.filter`, `sort`, `page` y `pageCount`, `search(query, {filter, sort, page})`, `applyFilter(filter)`, `setSort(sort)`, `goToPage(page)`, `clear()`, `searchHistoryProvider` (5, en memoria) y `searchPreviewProvider` (retardo de 300 ms en la hoja).
- `presentation/search_filter_sheet.dart`: `showSearchFilterSheet`, `MusubiPanel`, chips en fila, histograma que sigue el rango, `RangeSlider` de dos pulgares (0 a $2,000+), precio, segmented y `Ocultar agotados`; `Limpiar` (con toast) y `Ver N resultados`.
- `presentation/search_screen.dart`: lista todo al entrar, botón con globo, apertura de la hoja, cabecera con píldora `UTTT`, hoja `Ordenar por`, historial de la sesión y paginación por página debajo de la cuadrícula.
- `presentation/home_screen.dart`: la hoja `Filtrar` de Recién publicados (categoría + "Ocultar agotados", globo del conteo) y su hoja `filter_sheet.dart`; el filtro viaja a `homeFeed`.
- `presentation/home_providers.dart`: `categoriesProvider` (`FutureProvider.autoDispose`).
- `core/widgets/musubi_text_field.dart`: `prefixText` opcional para el `$` de los precios.

Decisiones:

- **Dos hojas, dos propósitos.** Inicio filtra la vitrina (categoría y agotados, lineamiento 4 y maqueta); la búsqueda filtra resultados (categorías múltiples, precio, estado y orden). Comparten el botón y el lenguaje visual, no el estado.
- **Historial solo de la sesión.** RNF-07 prohíbe persistir el texto de búsqueda; se guardan hasta 5 en memoria y se borran al cerrar la app.
- **`relevance` comparte el orden de `newest`.** La API todavía no calcula puntaje; el orden existe y se documenta (`NOTE (HU-09)`).
- **“Ocultar agotados” sí va en la búsqueda.** La maqueta lo trae y la API lo acepta: `hideSoldOut=false` incluye los agotados aunque haya `q`. Apagado, el globo lo cuenta como filtro activo.
- **Explorar con filtros y sin texto.** Antes la hoja solo guardaba el filtro y la pantalla no consultaba; ahora `applyFilter` pide el catálogo filtrado, que es lo que espera quien elige una categoría.
- **Precio en pesos en la UI y centavos en el contrato.** Evita decimales flotantes y coincide con `priceCents` de la API.
- **La hoja no filtra en el cliente.** La API decide coincidencias, `total` y páginas; la vista previa usa la misma consulta.
- **Los filtros viven en el estado de la búsqueda.** Al salir se descartan con el provider; la X no los borra para que el globo siga visible.

## Contratos

- Fila canónica: [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) → `GET /api/v1/products`, fila 73. Se enlaza, no se copia.
- Parámetros de esta HU: `category`, `minPriceCents`, `maxPriceCents`, `condition`, `hideSoldOut`, `sort`, sumados a `q`, `limit` y `page`.
- Errores: `listings.invalid_price_range`, `listings.invalid_condition`, `listings.invalid_query`, `listings.invalid_sort`, `listings.invalid_page`, red y `5xx`; la app decide por `code`.
- La forma de `ProductPage` no cambia. No hay fixture nuevo.

## Tests

- `test/features/marketplace/http_catalog_repository_test.dart`: los parámetros van solo cuando existen; `400` de rango llegan como `ApiFailure` con su `code`; `categories()` lee la fila 72.
- `test/features/marketplace/demo_catalog_repository_test.dart`: precio inclusivo, categoría, condición y combinación con `q`.
- `test/features/marketplace/search_providers_test.dart`: `applyFilter` relanza con el `q` actual y explora sin texto; `goToPage` pide esa página y conserva filtro y orden; `clear` conserva el filtro y lista el catálogo.
- `test/features/marketplace/search_screen_test.dart`: lista todo al entrar; botón y globo; abrir la hoja; aplicar categoría/precio/estado; filtrar sin texto muestra publicaciones; cambiar el orden; paginación; historial (guarda el término) y su `Limpiar`; mínimo > máximo; CTA con conteo; al reabrir no conserva búsqueda ni filtros.
- `test/features/marketplace/home_screen_test.dart`: la hoja `Filtrar` de Inicio elige categoría, muestra el globo, oculta agotados y limpia.
- `test/features/marketplace/search_filter_sheet_test.dart`: estados de la hoja, chips en fila, control deslizante, histograma que recolorea con el rango, interruptor de agotados, toast y validación.
- `test/helpers/fake_catalog_repository.dart`: registra filtros y responde `categories()`.

## Criterios

- [ ] Tocar el botón abre `Filtros` con las categorías de la API (`search_filter_sheet_test`).
- [ ] Elegir `Calculadoras` y `Libros` repite `category=calculadoras&category=libros` (`http_catalog_repository_test`, `search_filter_sheet_test`).
- [ ] Elegir `Calculadoras`, mínimo `300` y máximo `700` envía `category=calculadoras`, `minPriceCents=30000`, `maxPriceCents=70000` (`http_catalog_repository_test`, `search_screen_test`).
- [ ] Elegir `Usado` envía `condition=used`; `Todos` no envía el parámetro (`http_catalog_repository_test`).
- [ ] Mínimo `800` y máximo `300` muestran el error y no llaman a la API (`search_filter_sheet_test`).
- [ ] Aplicar filtros conserva el `q` actual y una respuesta atrasada no pisa la nueva (`search_providers_test`).
- [ ] Al entrar a `/buscar` se listan todas las publicaciones (`search_screen_test`, `search_providers_test`).
- [ ] La paginación pide `page=1` al buscar y `page=2` al tocar `2`, conservando filtros y orden (`search_screen_test`, `search_providers_test`, `http_catalog_repository_test`).
- [ ] Al salir y reabrir `/buscar` no quedan filtros (`search_screen_test`).
- [ ] Elegir una categoría sin texto muestra sus publicaciones (`search_screen_test`, `search_providers_test`).
- [ ] Apagar `Ocultar agotados` aplica `hideSoldOut=false` (`search_filter_sheet_test`, `http_catalog_repository_test`).
- [ ] Las categorías van en fila, no una por renglón (`search_filter_sheet_test`).
- [ ] El control deslizante llega a $2,000+ y el histograma cambia de color con el rango (`search_filter_sheet_test`).
- [ ] Elegir `Menor precio` manda `sort=priceAsc` y la cabecera lo muestra (`search_screen_test`, `http_catalog_repository_test`).
- [ ] Buscar guarda el término en el historial y `Limpiar` lo vacía (`search_screen_test`).
- [ ] La hoja `Filtrar` de Inicio filtra la vitrina y muestra el globo del conteo (`home_screen_test`).
- [ ] `Limpiar` de la hoja avisa `Filtros borrados` (`search_filter_sheet_test`).
- [ ] `dart format --output=none --set-exit-if-changed .` sin cambios.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` sin observaciones.
- [ ] `flutter test` al 100 %.
- [ ] `pwsh scripts/critic-guardrails.ps1` → PASS.

## Límites

- **“Más relevantes”:** la API lo acepta pero ordena igual que `recent` hasta que exista puntaje (`NOTE (HU-09)`).
- **Historial:** no se persiste entre sesiones (RNF-07); HU-53 decidió el 08-Nov-2026 no agregar almacenamiento local.
- **Tamaño de página:** 20; el API acepta de 1 a 50 y el número de páginas sale del `total`.
- **Productos agotados en la base de muestra:** no se pueden publicar con la API (stock mínimo 1); el interruptor se prueba con pruebas, no con datos sembrados.
- **Histograma de precio:** las alturas son decorativas (`aria-hidden` en la maqueta); solo el color sigue el rango elegido.
- **Acciones del vacío:** HU-12/HU-13.
- **Filtros de Inicio:** solo categoría y agotados; precio y estado viven en la búsqueda.

## Aprobación y Control de Cambios

- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 08-Nov-2026
- **Detalle:** alcance aprobado por el usuario: API + app con categoría, precio, estado y agotados. Se difiere “Más relevantes”.
