# HU-44 — Coordinar la entrega en un punto del campus (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-44 / SCRUM-56 / Sprint 4 (9 – 20 nov 2026) / M-08 / [musubi-api:HU-44](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-44-coordinar-entrega)

## Contexto
Jira (SCRUM-56): Como **comprador o vendedor**, quiero **acordar un punto de encuentro dentro del campus para la entrega**, para **concretar la operación de forma segura sin salir de la aplicación**.

- Maqueta: `Apartar`, `Apartado-listo`, `Mis-apartados`, `Verificar-comprador`, `Apartado-verificado`, `Pedido-pago`, `Pago-transferencia`, `Pago-validando`, `Pago-vendedor`, `Pedido-entrega`, `Pedido-efectivo`.
- Trazabilidad: RF-30 · R-14 · Entregable 1 §6, §7 y §11 (Sprint 4).
- Origen: Entregable 1 §6–7 — historia nueva, no estaba en la lista original.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-23`.

## Requisitos
1. Al generar o confirmar un pedido se elige un punto de encuentro de una lista definida dentro de la universidad, junto con fecha y hora.
2. El punto de encuentro y la fecha quedan registrados en el pedido y son visibles para ambas partes.
3. Los envíos a domicilio y la logística externa quedan fuera del alcance.

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/orders/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-44. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-44)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-44, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Al generar o confirmar un pedido se elige un punto de encuentro de una lista definida dentro de la universidad, junto con fecha y hora.
- [ ] El punto de encuentro y la fecha quedan registrados en el pedido y son visibles para ambas partes.
- [ ] Los envíos a domicilio y la logística externa quedan fuera del alcance.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): quién administra la lista de puntos de encuentro (propuesta: el administrador).
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
