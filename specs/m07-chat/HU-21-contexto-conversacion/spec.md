# HU-21 — Ver el contexto de la conversación (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-21 / SCRUM-30 / Sprint 2 (12 – 23 oct 2026) / M-07 / [musubi-api:HU-21](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m07-chat/HU-21-contexto-conversacion)

## Contexto
Jira (SCRUM-30): Como **usuario**, quiero **que la conversación muestre el producto o la solicitud de la que se está hablando**, para **no perder el contexto**.

- Maqueta: `Mensajes`, `Chat`, `Acuerdo-esperando`, `Acuerdo-confirmado`.
- Trazabilidad: RF-28 · CU-15.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-20`.

## Requisitos
1. Cada conversación muestra el producto, la solicitud o la oferta que la originó.
2. Desde ese contexto se puede abrir el detalle del elemento.

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/chat/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-21. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-21)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-21, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Cada conversación muestra el producto, la solicitud o la oferta que la originó.
- [ ] Desde ese contexto se puede abrir el detalle del elemento.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
