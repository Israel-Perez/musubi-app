# HU-26 — Consultar mi historial de ventas (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-26 / SCRUM-45 / Sprint 4 (9 – 20 nov 2026) / M-08 / [musubi-api:HU-26](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-26-historial-ventas)

## Contexto
Jira (SCRUM-45): Como **vendedor**, quiero **consultar mi historial de ventas**, para **saber qué he vendido**.

- Maqueta: la pestaña "Vendidos" de `Mis-productos`: tarjeta verde con "N ventas" y el total, y una fila por venta con foto, nombre, "$1,400 · 30 sep" y "Vendido".
- Trazabilidad: RF-33 · CU-18.
- Decisiones de la usuaria (13-Nov-2026):
  - el historial va en "Vendidos" de `Mis-productos`, con las ventas completadas; al tocar una se abre "Tu venta";
  - lo marcado como vendido a mano (HU-08) sigue apareciendo, sin comprador;
  - "Ventas" y "Compras" del perfil cuentan los pedidos completados (lo hace la API).

**Depende de:** `HU-08` ("Vendidos"), `HU-24` (pedido completado) y [musubi-api:HU-26](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-26-historial-ventas).

## Requisitos
1. **R1 · Ventas:** "Vendidos" muestra mis ventas completadas, de la más nueva a la más vieja: foto, nombre, el monto, la fecha, las piezas (si son más de una) y quién compró, con la marca "Vendido".
2. **R2 · Tarjeta:** "N ventas" y el total real de todas las ventas completadas. Sin ventas completadas no se muestra.
3. **R3 · Tu venta:** al tocar una venta se abre "Tu venta" (`AppRoutes.order`).
4. **R4 · A mano:** después de las ventas, lo marcado como vendido a mano, con "· Marcado a mano" y el menú de HU-08 (ver o eliminar).
5. **R5 · Pestaña y páginas:** "Vendidos (n)" suma las dos; "Ver más" trae primero las ventas que faltan y luego lo marcado a mano.
6. **R6 · Errores:** si las ventas no cargan, la pestaña muestra el mensaje de la API y "Reintentar".

## Diseño
- `lib/features/orders/`: `SalesPage`, `OrderRepository.sales({cursor})`, `HttpOrderRepository.sales` y `salesProvider`.
- `lib/features/listings/presentation/my_products_screen.dart`: `_SaleRow`, `_SalesTotal` con el total real y las páginas de ventas (`_moreSales`, `_salesCursor`).

## Contratos
Fila `GET /api/v1/orders/sales` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), enlazada desde `ApiPaths.orderSales`. La fila de `GET /products/mine` explica que `tab=sold` ya no repite lo vendido por un pedido.

## Tests
- `test/features/orders/order_data_test.dart` → "Mis ventas (HU-26)": la ruta, el cursor y la lectura de la página.
- `test/features/listings/my_products_manage_test.dart`: ventas con quien compró y el total real (y abrir "Tu venta"), "Ver más" de ventas y luego lo marcado a mano, error con "Reintentar", y lo marcado a mano sin tarjeta.
- Captura `mis-productos-vendidos` (`tool/screenshots_test.dart`).

## Criterios
- [x] El vendedor consulta su historial de ventas → `my_products_manage_test.dart`.
- [x] Cada venta muestra producto, comprador, cantidad, precio, fecha y estado → la fila de la venta y "Tu venta".
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 648 al 100 % · critic PASS.

## Límites
- Lo marcado a mano no tiene comprador ni monto real: no cuenta en la tarjeta ni en "Ventas" del perfil.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 13-Nov-2026 (detallado e implementado)
- **Detalle:** con las decisiones de la usuaria del 13-Nov-2026.
