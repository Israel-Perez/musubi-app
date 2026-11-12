# HU-50 — Manejar la cantidad disponible de un producto (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-50 / SCRUM-67 / Sprint 4 (9 – 20 nov 2026) / M-03 / [musubi-api:HU-50](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-50-cantidad-disponible)

## Contexto
Jira (SCRUM-67): Como **vendedor**, quiero **indicar cuántas piezas tengo de un producto**, para **vender varias unidades con una sola publicación y que los compradores sepan cuántas quedan**.

- Maqueta: `Vender-4` ("Piezas disponibles"), `Producto` ("Quedan N", "Último", "Agotado") y `Mis-productos` (piezas en cada fila y "Reponer" en las agotadas: "Repusiste «…». Ya está disponible").
- **Decisión de la usuaria (12-Nov-2026):** "Cambiar piezas" en el menú, como pidió el PO, con el selector de `Vender-4` en una hoja, y además "Reponer" en las filas de Agotados, como la maqueta. Una sola petición por cambio.
- Desde HU-24 las piezas apartadas en un pedido aceptado ya no cuentan: la hoja dice "piezas disponibles".

**Depende de:** `HU-07`, `HU-08` y la fila de `musubi-api:HU-50`.

## Requisitos
1. **Al publicar se elige la cantidad** (`Vender-4`, 1 a 10). Ya existe (HU-06).
2. **El detalle dice "Quedan N", "Último" o "Agotado".** Ya existe (HU-11).
3. **Un pedido aparta piezas sin vender de más.** Lo hace la API (HU-24).
4. **"Ocultar agotados" en Filtrar.** Ya existe (HU-10).
5. **"Cambiar piezas" (nuevo):** opción del menú de una publicación no vendida, que muestra cuántas tiene ("2 piezas disponibles").
   - Abre una hoja con el selector de `Vender-4`, de 0 a 10, y "Guardar". Con 0 avisa que queda como agotada.
   - Al guardar, `PUT /products/{id}/stock` y se refrescan las pestañas.
6. **"Reponer" (nuevo):** el botón oscuro de la maqueta en cada fila de Agotados. La deja con 1 pieza y avisa "Repusiste «…». Ya está disponible".
7. **Una pausada sigue pausada** al cambiar sus piezas, y una vendida no ofrece "Cambiar piezas".

## Diseño
- `ListingsRepository.setStock` (`HttpListingsRepository` y el fake) y `ApiPaths.productStock`.
- `QuantityRow` sale de `sell_condition_screen.dart` a `quantity_row.dart`, con `min` (1 al publicar, 0 al cambiar), `note` y `margin`, para usar el mismo selector en las dos pantallas.
- `MyProductsScreen`: opción "Cambiar piezas" (`_StockPanel`), botón "Reponer" en la fila agotada y avisos.

## Contratos
Fila `PUT /api/v1/products/{id}/stock` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (M-03). Errores: `listings.invalid_stock`, `listings.product_sold` y `listings.product_not_found`.

## Tests
- `test/features/listings/http_listings_repository_test.dart` (+1): `PUT /stock` con `{ stock }`.
- `test/features/listings/my_products_manage_test.dart` (+3, y una vendida no ofrece "Cambiar piezas"):
  - cambiar a 0;
  - "Reponer";
  - una pausada sigue pausada.
- `tool/screenshots_test.dart`: `cambiar-piezas` y `mis-productos-agotados`.
- **Ya existentes:** `sell_flow_test.dart` (cantidad al publicar), `demo_catalog_repository_test.dart` ("Último" y "Quedan 2") y `widgets_test.dart` ("Ocultar agotados").

## Criterios
- [x] "Cambiar piezas" y "Reponer": `my_products_manage_test.dart` en verde. Mutación: sin "Reponer" en la fila agotada, en rojo.
- [x] `dart format` sin cambios · `flutter analyze --fatal-infos --fatal-warnings` 0 · `flutter test` 569/569 · critic PASS (Flutter 3.47.7).

## Límites
- `NOTE (musubi-api:HU-52)`: un apartado vencido regresa la pieza solo.
- Fijar el número puede pisar un apartado que entra en el mismo instante (decisión de la usuaria; ver la spec del back).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 12-Nov-2026
- **Detalle:** detallada desde Jira (SCRUM-67 y el comentario del PO), la maqueta y la fila de `musubi-api:HU-50`.
