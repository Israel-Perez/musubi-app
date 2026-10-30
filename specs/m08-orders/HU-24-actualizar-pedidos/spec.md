# HU-24 — Aceptar y actualizar mis pedidos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-24 / SCRUM-43 / Sprint 3 (26 oct – 6 nov 2026) / M-08 / [musubi-api:HU-24](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-24-actualizar-pedidos)

## Contexto
Jira (SCRUM-43): Como **vendedor**, quiero **aceptar y actualizar el estado de mis pedidos**, para **llevar control de las entregas**.

- Maqueta: `Pedido-pago`, `Pago-transferencia`, `Pago-validando`, `Pago-vendedor`, `Pedido-entrega`, `Pedido-efectivo`.
- Trazabilidad: RF-31, RF-33, RF-34 · CU-18 · RN-16, RN-19, RN-20.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-23`.

## Requisitos
1. El vendedor acepta o rechaza pedidos **Pendientes**; al aceptarlo pasa a **Confirmado** y la cantidad se aparta (RF-34).
2. Los estados del pedido son **Pendiente**, **Confirmado**, **Completado** y **Cancelado** (RF-31).
3. El pedido pasa a **Completado** cuando ambas partes confirman la entrega (RN-19, propuesta) y la cantidad se descuenta.
4. Cualquiera de las partes puede cancelar antes de completar, indicando el motivo; la cantidad se libera (RN-20).
5. Si la cantidad llega a cero, la publicación pasa a **Vendida**.

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/orders/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-24. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-24)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-24, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] El vendedor acepta o rechaza pedidos **Pendientes**; al aceptarlo pasa a **Confirmado** y la cantidad se aparta (RF-34).
- [ ] Los estados del pedido son **Pendiente**, **Confirmado**, **Completado** y **Cancelado** (RF-31).
- [ ] El pedido pasa a **Completado** cuando ambas partes confirman la entrega (RN-19, propuesta) y la cantidad se descuenta.
- [ ] Cualquiera de las partes puede cancelar antes de completar, indicando el motivo; la cantidad se libera (RN-20).
- [ ] Si la cantidad llega a cero, la publicación pasa a **Vendida**.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): confirmar si basta con que el comprador confirme la entrega (RN-19).
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
