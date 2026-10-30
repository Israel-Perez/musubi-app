# HU-15 — Explorar solicitudes publicadas (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-15 / SCRUM-37 / Sprint 3 (26 oct – 6 nov 2026) / M-05 / [musubi-api:HU-15](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-15-explorar-solicitudes)

## Contexto
Jira (SCRUM-37): Como **vendedor**, quiero **consultar y filtrar las solicitudes publicadas**, para **encontrar oportunidades de venta**.

- Maqueta: `Inicio-visitante`, `Se-busca-visitante`, `Producto-visitante`, `Visitante-modal`, `Se-busca`, `Yo-tengo-vincular`, `Yo-tengo-oferta`, `Yo-tengo-enviada`.
- Trazabilidad: RF-19 · CU-10 · RNF-19.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-13`.

## Requisitos
1. Se listan las solicitudes **Activas**.
2. Se pueden filtrar por categoría y presupuesto.
3. Las solicitudes se distinguen visualmente de los productos publicados (RNF-19).

RNF que aplican: RNF-19.

## Diseño
- Feature `lib/features/purchase_requests/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-15. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-15)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-15, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Se listan las solicitudes **Activas**.
- [ ] Se pueden filtrar por categoría y presupuesto.
- [ ] Las solicitudes se distinguen visualmente de los productos publicados (RNF-19).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
