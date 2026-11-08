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
3. La categoría es de selección única; tocar la elegida la quita. Los chips salen de `GET /api/v1/categories`.
4. El precio se elige con el control deslizante de dos pulgares y se puede escribir en pesos (`Mínimo` y `Máximo`); la app lo convierte a centavos. Los límites son inclusivos, vacío significa sin límite y el máximo es $999,999.
5. Si el mínimo es mayor que el máximo, la hoja muestra el mensaje en español y no aplica ni llama a la API.
6. El estado es `Todos`, `Nuevo` o `Usado`; se envía como `condition` (`null`, `new`, `used`).
7. `Ocultar agotados` (encendido por defecto) se envía como `hideSoldOut`; apagado muestra también los agotados.
8. El globo cuenta categoría + rango de precio + estado + agotados visibles (máximo 4).
9. Aplicar los filtros relanza la búsqueda con el texto actual; sin texto, muestra el catálogo filtrado. Conserva el descarte de respuestas atrasadas y no pierde las tarjetas mientras llega la nueva.
10. `Cargar más` conserva los filtros y el cursor; el `total` y la paginación los decide la API.
11. El CTA dice `Ver N resultados` con una vista previa (300 ms de retardo), también sin texto si hay filtros. Si la vista previa falla, dice `Ver resultados`; sin texto ni filtros, no consulta.
12. Al salir de `/buscar` se limpia todo (`autoDispose`). La X del campo borra el texto y conserva los filtros (vuelve a mostrar el catálogo filtrado); `Limpiar` de la hoja borra los filtros.
13. Las categorías se acomodan en fila, con varias por renglón, como la maqueta.
14. Sin regresiones: formato, análisis, pruebas y critic en verde.

## Diseño

- `domain/search_filter.dart`: `SearchFilter` y `ProductConditionFilter` (`all`, `newItem`, `used`), con `count`, `isEmpty`, `==`/`hashCode` y `apiValue`.
- `domain/catalog_repository.dart`: `search({query, filter, cursor})` y `categories()`.
- `data/http_catalog_repository.dart`: envía `category`, `minPriceCents`, `maxPriceCents`, `condition`, `hideSoldOut`, `q`, `cursor` y `limit`; `categories()` lee fila 72.
- `data/demo_catalog_repository.dart`: búsqueda local con categoría, precio inclusivo, condición y agotados; sin texto devuelve el catálogo filtrado.
- `presentation/search_providers.dart`: `SearchState.filter` y `hasCriteria`, `search(query, {filter})`, `applyFilter(filter)`, `clear()` y `searchPreviewProvider` (retardo de 300 ms en la hoja).
- `presentation/search_filter_sheet.dart`: `showSearchFilterSheet`, `MusubiPanel`, chips en fila, histograma decorativo, `RangeSlider` de dos pulgares, precio, segmented y `Ocultar agotados`; `Limpiar` y `Ver N resultados`.
- `presentation/search_screen.dart`: botón con globo, apertura de la hoja y paso del filtro a `search`/`loadMore`.
- `presentation/home_providers.dart`: `categoriesProvider` (`FutureProvider.autoDispose`).
- `core/widgets/musubi_text_field.dart`: `prefixText` opcional para el `$` de los precios.

Decisiones:

- **`SearchFilter` separado de `CatalogFilter`.** Inicio conserva su hoja de categoría + agotados; la búsqueda no cambia su comportamiento.
- **“Ocultar agotados” sí va en la búsqueda.** La maqueta lo trae y la API lo acepta: `hideSoldOut=false` incluye los agotados aunque haya `q`. Apagado, el globo lo cuenta como filtro activo.
- **Explorar con filtros y sin texto.** Antes la hoja solo guardaba el filtro y la pantalla no consultaba; ahora `applyFilter` pide el catálogo filtrado, que es lo que espera quien elige una categoría.
- **Sin selector de orden.** Jira no lo pide y la API ordena por fecha; “Más relevantes” de la maqueta queda como `NOTE (HU-10)`.
- **Precio en pesos en la UI y centavos en el contrato.** Evita decimales flotantes y coincide con `priceCents` de la API.
- **La hoja no filtra en el cliente.** La API decide coincidencias, `total` y cursor; la vista previa usa la misma consulta.
- **Los filtros viven en el estado de la búsqueda.** Al salir se descartan con el provider; la X no los borra para que el globo siga visible.

## Contratos

- Fila canónica: [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) → `GET /api/v1/products`, fila 73. Se enlaza, no se copia.
- Parámetros de esta HU: `category`, `minPriceCents`, `maxPriceCents`, `condition`, `hideSoldOut`, sumados a `q`, `cursor` y `limit`.
- Errores: `listings.invalid_price_range`, `listings.invalid_condition`, `listings.invalid_query`, `listings.invalid_cursor`, red y `5xx`; la app decide por `code`.
- La forma de `ProductPage` no cambia. No hay fixture nuevo.

## Tests

- `test/features/marketplace/http_catalog_repository_test.dart`: los parámetros van solo cuando existen; `400` de rango y condición llegan como `ApiFailure` con su `code`; `categories()` lee la fila 72.
- `test/features/marketplace/demo_catalog_repository_test.dart`: precio inclusivo, categoría, condición y combinación con `q`.
- `test/features/marketplace/search_providers_test.dart`: `applyFilter` relanza con el `q` actual y explora sin texto; `loadMore` conserva el filtro; `clear` conserva el filtro; la vista previa pide el `total`.
- `test/features/marketplace/search_screen_test.dart`: botón y globo; abrir la hoja; aplicar categoría/precio/estado; filtrar sin texto muestra publicaciones; `Limpiar`; mínimo > máximo; CTA con conteo; al reabrir no conserva filtros.
- `test/features/marketplace/search_filter_sheet_test.dart`: estados de la hoja, chips en fila, control deslizante, interruptor de agotados y validación.
- `test/helpers/fake_catalog_repository.dart`: registra filtros y responde `categories()`.

## Criterios

- [ ] Tocar el botón abre `Filtros` con las categorías de la API (`search_filter_sheet_test`).
- [ ] Elegir `Calculadoras`, mínimo `300` y máximo `700` envía `category=calculadoras`, `minPriceCents=30000`, `maxPriceCents=70000` (`http_catalog_repository_test`, `search_screen_test`).
- [ ] Elegir `Usado` envía `condition=used`; `Todos` no envía el parámetro (`http_catalog_repository_test`).
- [ ] Mínimo `800` y máximo `300` muestran el error y no llaman a la API (`search_filter_sheet_test`).
- [ ] Aplicar filtros conserva el `q` actual y una respuesta atrasada no pisa la nueva (`search_providers_test`).
- [ ] `Cargar más` envía el mismo filtro (`search_providers_test`).
- [ ] Al salir y reabrir `/buscar` no quedan filtros (`search_screen_test`).
- [ ] Elegir una categoría sin texto muestra sus publicaciones (`search_screen_test`, `search_providers_test`).
- [ ] Apagar `Ocultar agotados` aplica `hideSoldOut=false` (`search_filter_sheet_test`, `http_catalog_repository_test`).
- [ ] Las categorías van en fila, no una por renglón (`search_filter_sheet_test`).
- [ ] `dart format --output=none --set-exit-if-changed .` sin cambios.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` sin observaciones.
- [ ] `flutter test` al 100 %.
- [ ] `pwsh scripts/critic-guardrails.ps1` → PASS.

## Límites

- **“Más relevantes”:** no se muestra; el orden lo decide la API por fecha (`NOTE (HU-10)`).
- **Productos agotados en la base de muestra:** no se pueden publicar con la API (stock mínimo 1); el interruptor se prueba con pruebas, no con datos sembrados.
- **Histograma de precio:** es decorativo (`aria-hidden` en la maqueta); no representa los datos de la consulta.
- **Filtros de condición y precio en Inicio:** fuera de esta HU; Inicio conserva categoría + agotados.
- **Acciones del vacío:** HU-12/HU-13.
- **Historial o guardado de filtros:** no se persiste.

## Aprobación y Control de Cambios

- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 08-Nov-2026
- **Detalle:** alcance aprobado por el usuario: API + app con categoría, precio, estado y agotados. Se difiere “Más relevantes”.
