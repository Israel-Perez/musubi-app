# HU-25 — Consultar mis pedidos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-25 / SCRUM-44 / Sprint 3 (26 oct – 6 nov 2026) / M-08 / [musubi-api:HU-25](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-25-mis-pedidos)

## Contexto
Jira (SCRUM-44): Como **comprador**, quiero **consultar mis pedidos**, para **saber en qué estado está cada compra**.

- Maqueta: sin pantalla propia. Se diseña con la guía de estilo de la maqueta; el lineamiento 4 permite agregar, nunca quitar.
- Trazabilidad: RF-32 · CU-17.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-23`.

## Requisitos
1. El comprador ve la lista de sus pedidos con su estado actual.
2. El detalle muestra producto, cantidad, precio, lugar y fecha de entrega.

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/orders/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-25. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-25)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-25, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- Widget tests de las pantallas nuevas (sin escena de maqueta).

## Criterios
- [ ] El comprador ve la lista de sus pedidos con su estado actual.
- [ ] El detalle muestra producto, cantidad, precio, lugar y fecha de entrega.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
