# HU-08 — Consultar el estado de mis productos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-08 / SCRUM-25 / Sprint 4 (9 – 20 nov 2026) / M-03 / [musubi-api:HU-08](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-08-estado-mis-productos)

## Contexto
Jira (SCRUM-25): Como **vendedor**, quiero **consultar el estado de mis productos**, para **saber cuáles están disponibles, reservados o vendidos**.

- **Maqueta `Mis-productos`:**
  - pestañas "Activos (n)", "Vendidos (n)" y "Agotados (n)";
  - "Vendidos" con la tarjeta verde "N ventas · $total" y filas "$precio · 30 sep · Vendido";
  - en el menú, "Marcar como vendido" con el diálogo de `Producto`: "¿Marcar como vendido?" / "Ya no aparecerá en las búsquedas y se moverá a tus ventas." / "Sí, ya lo vendí", y luego "¡Felicidades por tu venta!".
- **Decisiones de la usuaria (09-Nov-2026, en el back):** manda la maqueta (Activos = disponibles y pausadas), "Marcar como vendido" es el estado `sold`, y las piezas (+/− y "Reponer") se quedan en HU-50.
- Este PR va apilado encima del de HU-07 (decisión de la usuaria del 10-Nov-2026).
- Trazabilidad: RF-10, RF-11 · CU-05 · RN-05.

**Depende de:** `HU-07` (menú de `Mis-productos`) y las filas de `musubi-api:HU-08` (PR #61, ya en `main`).

## Requisitos
1. **Pestañas desde la API (RF-10, RF-11):** cada pestaña se pide con `?tab=` y sus conteos vienen en la respuesta. "Ver más" pide la siguiente página con el cursor.
2. **"Marcar como vendido"** en el menú de una publicación que no está vendida, con el diálogo de la maqueta. Al confirmar: "¡Felicidades por tu venta!" y la publicación pasa a "Vendidos".
3. **"Vendidos":**
   - la tarjeta "N ventas" con el total;
   - cada fila con su precio y la fecha de la venta ("28 sep"), la marca "Vendido" y la foto a color.
4. **Una vendida solo se ve o se elimina:** su menú no ofrece "Editar", "Marcar como vendido" ni "Pausar" (la API respondería `409 listings.product_sold`).
5. **`sold` no se lee como activa:** antes, cualquier estado desconocido se tomaba como activo, y una vendida habría salido en "Yo tengo este producto" (HU-16) y en el conteo del Perfil.
6. **Pendientes:**
   - "Reservada": `NOTE (musubi-api:HU-52)`;
   - el comprador y el monto real en "Vendidos": `NOTE (HU-25)`;
   - la venta automática al completar pedidos: `NOTE (musubi-api:HU-23)`, la hace la API.

## Diseño
- **Dominio:**
  - `ListingStatus.sold`;
  - `OwnListing.soldAt` y `sold`;
  - `MyProductsTab` (con `apiValue`), `MyListingsCounts` y `MyListingsPage`;
  - `ListingsRepository.minePage` y `markSold`.
- **Datos:** `HttpListingsRepository` (`?tab=&cursor=`, conteos, `soldAt` y `sold`); `ApiPaths.productSold`.
- **Presentación:**
  - `myListingsTabProvider` (familia por pestaña);
  - `MyProductsScreen` con los conteos de la API, "Ver más", `_SalesTotal`, la fila vendida y el diálogo;
  - `dayMonth` ("30 sep") en `home_feed.dart`.

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), sección M-03:
- `GET /api/v1/products/mine?tab=&cursor=&limit=` (`MyProductPage`);
- `POST /api/v1/products/{id}/sold`.

Errores: `listings.product_sold`, `listings.invalid_tab` y `listings.product_not_found`.

## Tests
- `test/features/listings/http_listings_repository_test.dart` (+3):
  - `?tab=` y el cursor;
  - los conteos;
  - `soldAt` y `sold`;
  - `POST /sold`.
- `test/features/listings/my_products_manage_test.dart` (+4):
  - las pestañas con los conteos;
  - "Marcar como vendido" con su diálogo;
  - "Vendidos" (total, fecha, marca y menú corto);
  - "Ver más".
- `tool/screenshots_test.dart`: `mis-productos-vendidos` y `marcar-vendido`.

## Criterios
- [x] Pestañas, vender y "Vendidos": `my_products_manage_test.dart` en verde (11 en total con HU-07).
- [x] `sold` no se lee como activa: `mis productos por pestana: ?tab=, cursor y conteos` en verde. Mutación: sin `'sold' => ListingStatus.sold`, esa prueba falla.
- [x] `dart format` sin cambios · `flutter analyze --fatal-infos --fatal-warnings` 0 · `flutter test` 531/531 · critic PASS (Flutter 3.47.7).

## Límites
- "Reservada": `NOTE (musubi-api:HU-52)`.
- `NOTE (HU-25)`: comprador y monto real en "Vendidos".
- `NOTE (HU-50)`: contador +/− y "Reponer".
- Vender no se deshace (la maqueta no ofrece "Deshacer").

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 10-Nov-2026
- **Detalle:** detallada desde la maqueta (`Mis-productos`, diálogo de `Producto`) y las filas de `musubi-api:HU-08`; PR apilado sobre HU-07.
