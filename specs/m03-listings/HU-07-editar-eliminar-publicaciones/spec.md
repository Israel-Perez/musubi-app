# HU-07 — Editar o eliminar mis publicaciones (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-07 / SCRUM-24 / Sprint 4 (9 – 20 nov 2026) / M-03 / [musubi-api:HU-07](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-07-editar-eliminar-publicaciones)

## Contexto
Jira (SCRUM-24): Como **vendedor**, quiero **editar o eliminar mis publicaciones**, para **que la información siempre sea correcta**.

- **Maqueta `Mis-productos`:** al tocar una publicación se abre un menú con "Ver publicación", "Editar", "Marcar como vendido" y "Eliminar".
  - "Editar" reutiliza `Vender-2…4` con el título "Editar publicación". No muestra `Vender-1` (las fotos) y al guardar avisa "Guardamos los cambios de tu publicación".
  - "Eliminar" pide confirmación: "¿Eliminar la publicación?" / "Ya no aparecerá en Musubi. Esta acción no se puede deshacer." Al confirmar avisa "Eliminaste la publicación".
  - "Marcar como vendido" es de HU-08 (PR apilado encima de este).
- **Decisiones de la usuaria (10-Nov-2026):**
  - "Pausar publicación" / "Reactivar" entran en el menú aunque la maqueta no los tenga (la API ya los tiene; lineamiento 4: se puede agregar);
  - al editar, `Vender-4` muestra las piezas sin dejar cambiarlas ("Reponer" es de HU-50);
  - HU-07 y HU-08 van en dos PR apilados.
- Trazabilidad: RF-08, RF-09 · CU-05 · RN-07 · RNF-03.

**Depende de:** `02-01`, `02-04` (piezas de la maqueta), `HU-06` (flujo de Vender) y las filas de `musubi-api:HU-07`, ya en producción de código (PR #60).

## Requisitos
1. **Menú de cada publicación** en `Mis-productos`: "Ver publicación", "Editar", "Pausar publicación" o "Reactivar", y "Eliminar" (en rojo).
2. **Editar** abre `Vender-2…4` en modo edición con los datos de la publicación: nombre, descripción, precio, categoría, estado y detalle. Las piezas se ven sin poder cambiarse y la portada es la de la publicación. "Guardar" (arriba) y "Guardar cambios" (en `Vender-4`) mandan `PUT`; al salir bien, vuelve a `Mis-productos` con el aviso. La X vuelve a `Mis-productos` sin guardar.
3. **Errores con el mensaje de la API** (RNF-18), por `code`:
   - validación (`listings.invalid_*`);
   - moderación (`moderation.*`);
   - `listings.product_not_found` (ya no existe): avisa y refresca la lista.
4. **Pausar / Reactivar:** la publicación pausada sigue en "Activos" con la marca "Pausada" y sale de la vitrina (lo hace la API).
5. **Eliminar** con el diálogo de la maqueta. Si tiene pedidos abiertos, la API responde `409 listings.product_has_orders` (RN-07, HU-23) y se muestra su mensaje.
6. **Solo el dueño (RNF-03):** la app solo ofrece el menú en `Mis-productos`; la API responde 404 a cualquier otra persona.
7. **Coincidencias al editar (RF-08):** las hace la API cuando exista HU-18. En la app no hay nada que hacer: `NOTE (musubi-api:HU-18)`.

RNF que aplican: RNF-03, RNF-18 (mensajes en español).

## Diseño
- **Dominio** (`lib/features/listings/domain/`):
  - `OwnListing` agrega `description`, `condition` y `usedDetail` (para editar);
  - `ListingUpdate` (cuerpo del `PUT`);
  - `ListingsRepository` agrega `update`, `pause`, `resume` y `delete`.
- **Datos:** `HttpListingsRepository` con las 4 rutas; `ApiPaths.productPause` y `ApiPaths.productResume` (`PUT` y `DELETE` usan `ApiPaths.product`).
- **Presentación:**
  - `SellDraft` agrega `editingId` y `coverUrl`;
  - `sellEditDraftProvider` es un borrador aparte, como `needEditDraftProvider` de HU-14, para no pisar un borrador de venta guardado;
  - `sell_edit.dart` (título, salir y guardar);
  - `SellDetailsScreen`, `SellPriceScreen` y `SellConditionScreen` aceptan `editing`;
  - rutas `/editar-publicacion`, `/editar-publicacion/precio` y `/editar-publicacion/estado`;
  - `MyProductsScreen` con el menú, el diálogo y la marca "Pausada".

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), sección M-03, enlazadas desde `api_paths.dart`:
- `PUT /api/v1/products/{id}`;
- `POST /api/v1/products/{id}/pause` y `/resume`;
- `DELETE /api/v1/products/{id}`.

Errores del catálogo [`docs/errores.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/errores.md): `listings.product_not_found`, `listings.product_has_orders`, `listings.invalid_*` y `moderation.*`.

## Tests
- `test/features/listings/http_listings_repository_test.dart`: rutas, cuerpo del `PUT`, mapeo de la respuesta y errores en español.
- `test/features/listings/sell_draft_test.dart`: cargar una publicación para editar y guardar (el borrador de venta no se toca).
- `test/features/listings/my_products_manage_test.dart`:
  - el menú;
  - editar y guardar (vuelve con el aviso);
  - pausar y reactivar;
  - eliminar con confirmación;
  - `409 listings.product_has_orders`;
  - las piezas sin poder cambiarse al editar.
- `tool/screenshots_test.dart`: el menú y "Editar publicación" en claro y oscuro.

## Criterios
- [x] Menú, editar, pausar/reactivar y eliminar: `my_products_manage_test.dart` (7) en verde.
- [x] Rutas y errores: `http_listings_repository_test.dart` (+4) en verde.
- [x] `dart format` sin cambios · `flutter analyze --fatal-infos --fatal-warnings` 0 · `flutter test` 524/524 · critic PASS (Flutter 3.47.7).

## Límites
- **Fotos:** no se editan (la maqueta no muestra `Vender-1` al editar; decisión D4 del back).
- **Piezas:** "Reponer" es de HU-50.
- `NOTE (musubi-api:HU-18)`: volver a buscar coincidencias al editar.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 10-Nov-2026
- **Detalle:** detallada desde la maqueta (`Mis-productos`, `Vender-2…4`) y las filas de `musubi-api:HU-07`. Decisiones de la usuaria del 10-Nov-2026: Pausar en el menú, piezas visibles sin editar y dos PR apilados.
