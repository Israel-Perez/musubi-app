# HU-25 — Consultar mis pedidos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-25 / SCRUM-44 / Sprint 4 (9 – 20 nov 2026) / M-08 / [musubi-api:HU-25](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-25-mis-pedidos)

## Contexto
Jira (SCRUM-44): Como **comprador**, quiero **consultar mis pedidos**, para **saber en qué estado está cada compra**.

- Maqueta: la sección **"Mis pedidos"** de `Perfil`: las compras más nuevas con foto de 44, nombre, una línea gris ("Entrega jue 8 oct · $500", "Falta tu pago · $290", "26 sep · $420"), la píldora del estado y "Ver todos".
- La lista completa ("Ver todos") no tiene pantalla en la maqueta. Se arma con sus piezas: las pestañas de `Mis-productos` y las filas de `Perfil` (lineamiento 4: se agrega, no se quita).
- Trazabilidad: RF-32 · CU-17.
- Decisiones de la usuaria (12-Nov-2026): **solo mis compras** (las ventas son de HU-26) y "Ver todos" con **pestañas por estado**: Activos (pendientes y confirmados), Completados y Cancelados.

**Depende de:** `02-04` (piezas de la maqueta), `HU-23` y `HU-24` ("Tu pedido") y la API de HU-25.

## Requisitos
1. **R1 · Perfil:** después de "Privacidad", la sección "Mis pedidos" muestra mis tres compras más nuevas con su línea y su píldora. "Ver todos" abre la lista.
   - Sin compras: "Cuando compres algo, aquí verás cómo va tu pedido."
   - Si falla, el resto del Perfil sigue y aparece el mensaje con "Reintentar".
2. **R2 · Línea gris:** pendiente sin pago → "Falta tu pago · $290"; pendiente pagado → "Por aceptar · $290"; confirmado → "Entrega jue 8 oct · $500"; completado o cancelado → el día en que pasó ("26 sep · $420"). El precio es el total del pedido.
3. **R3 · Píldoras:** Pendiente (ámbar, `clock`), Confirmado (rojo suave, `check`) y Completado (verde, `circle-check`), como la maqueta. Cancelado no está en la maqueta: gris con `circle-x`, como el aviso de HU-24.
4. **R4 · "Mis pedidos":** pestañas "Activos (n)", "Completados (n)" y "Cancelados (n)" con los números de la API; empieza en Activos; páginas de 20 con "Ver más"; cada pestaña vacía explica qué va ahí (en Activos, "Ver productos" lleva a Inicio); error con "Reintentar".
5. **R5 · Detalle:** tocar un pedido abre "Tu pedido" (`Pedido-pago`, HU-23/24), que muestra producto, cantidad, precio, lugar y fecha. Al volver, las listas se recargan.
6. **R6 · Sesión:** `/mis-pedidos` exige sesión, como `Mis productos`.

RNF que aplican: RNF-12 (indicador de carga), RNF-18 (mensajes en español), RNF-20 (contraste) y RNF-27 (toques de 44: las pestañas cubren los 44 de alto).

## Diseño
- **Dominio:** `MyOrdersTab` (código y texto), `MyOrdersCounts`, `MyOrdersPage`; `Order.updatedAt`.
- **Datos:** `OrderRepository.mine({tab, cursor, limit})` → `GET /api/v1/orders/mine` (`ApiPaths.myOrders`).
- **Estado:** `recentOrdersProvider` (las tres de Perfil) y `myOrdersProvider(tab)` (primera página); la pantalla guarda las siguientes, como `Mis productos`.
- **Pantalla:** `my_orders_widgets.dart` (`orderLine`, `OrderStatusPill`, `OrderRow`, `RecentOrdersSection`) y `my_orders_screen.dart` (`MyOrdersScreen`, ruta `AppRoutes.myOrders`).

## Contratos
Fila "M-08" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md): `GET /api/v1/orders/mine` (`MyOrderPage`; cada elemento es un `OrderResponse`). Errores `orders.invalid_tab` y `orders.invalid_cursor`.

## Tests
- `test/features/orders/order_data_test.dart` (+3): pestaña, cursor y límite; sin pestaña; `orders.invalid_tab` como `ApiFailure`.
- `test/features/orders/my_orders_test.dart` (13): la línea de cada estado; Perfil con las tres compras, vacío, error y reintento, y tocar un pedido; "Ver todos" con sus números, cada pestaña, vacío de Activos, "Ver más", error, recarga al volver, accesibilidad a 360×640 y la ruta con sesión.
- `tool/screenshots_test.dart`: `perfil` (con "Mis pedidos" de la maqueta) y `mis-pedidos`.

## Criterios
- [x] El comprador ve la lista de sus pedidos con su estado actual → `my_orders_test` (Perfil y "Ver todos").
- [x] El detalle muestra producto, cantidad, precio, lugar y fecha de entrega → tocar un pedido abre "Tu pedido" (`order_flow_test` de HU-23/24 cubre lo que muestra).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 624 al 100 % · critic PASS.
- [ ] Prueba en el celular con la API desplegada (`alpha.23`).

## Límites
- `NOTE (HU-26)`: las ventas (y en "Vendidos" de `Mis productos`, quién compró y el monto real).
- `NOTE (HU-52)`: "Mis apartados" de `Perfil`.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 12-Nov-2026 (detallado e implementado)
- **Detalle:** la sección de `Perfil` es la de la maqueta; "Ver todos" se arma con sus piezas. Capturas comparadas con la maqueta (`Perfil`).
