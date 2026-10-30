# HU-08 — Consultar el estado de mis productos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-08 / SCRUM-25 / Sprint 2 (12 – 23 oct 2026) / M-03 / [musubi-api:HU-08](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-08-estado-mis-productos)

## Contexto
Jira (SCRUM-25): Como **vendedor**, quiero **consultar el estado de mis productos**, para **saber cuáles están disponibles, reservados o vendidos**.

- Maqueta: `Perfil`, `Mis-productos`.
- Trazabilidad: RF-10, RF-11 · CU-05 · RN-05.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-06`, `HU-23`.

## Requisitos
1. El vendedor ve la lista de sus publicaciones con su estado y el tiempo que llevan publicadas (RF-11).
2. Los estados posibles son **Disponible**, **Reservada**, **Vendida** e **Inactiva** (RF-10).
3. El estado cambia automáticamente según los pedidos; cuando la cantidad llega a cero pasa a **Vendida** (RN-05).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/listings/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-08. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-08)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-08, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] El vendedor ve la lista de sus publicaciones con su estado y el tiempo que llevan publicadas (RF-11).
- [ ] Los estados posibles son **Disponible**, **Reservada**, **Vendida** e **Inactiva** (RF-10).
- [ ] El estado cambia automáticamente según los pedidos; cuando la cantidad llega a cero pasa a **Vendida** (RN-05).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
