# HU-11 — Ver el detalle de un producto (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-11 / SCRUM-28 / Sprint 2 (12 – 23 oct 2026) / M-04 / [musubi-api:HU-11](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-11-detalle-producto)

## Contexto
Jira (SCRUM-28): Como **comprador**, quiero **ver el detalle de un producto**, para **decidir si me interesa antes de contactar al vendedor**.

- Maqueta: `Inicio-visitante`, `Se-busca-visitante`, `Producto-visitante`, `Visitante-modal`, `Producto`, `Perfil-vendedor`, `Chat-Valeria`.
- Trazabilidad: RF-14 · CU-06 · RNF-19.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-06`.

## Requisitos
1. El detalle muestra fotografías, descripción, precio, estado, cantidad, datos del vendedor y su reputación.
2. Desde el detalle se puede contactar al vendedor (chat) o comprar.
3. La interfaz distingue visualmente los productos publicados de las solicitudes de compra (RNF-19).

RNF que aplican: RNF-19.

## Diseño
- Feature `lib/features/marketplace/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-11. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-11)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-11, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] El detalle muestra fotografías, descripción, precio, estado, cantidad, datos del vendedor y su reputación.
- [ ] Desde el detalle se puede contactar al vendedor (chat) o comprar.
- [ ] La interfaz distingue visualmente los productos publicados de las solicitudes de compra (RNF-19).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
