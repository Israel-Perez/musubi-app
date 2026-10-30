# HU-13 — Publicar una necesidad de compra (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-13 / SCRUM-35 / Sprint 3 (26 oct – 6 nov 2026) / M-05 / [musubi-api:HU-13](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-13-publicar-necesidad)

## Contexto
Jira (SCRUM-35): Como **comprador**, quiero **publicar una solicitud indicando el producto, la descripción, las características, el presupuesto, la cantidad y la fecha en que lo necesito**, para **que otros usuarios sepan lo que busco**.

- Maqueta: `Necesidad-1`, `Necesidad-3`, `Necesidad-publicada`, `Mis-solicitudes`.
- Trazabilidad: RF-16, RF-22 · CU-08 · Flujo B · RN-09, RN-10, RN-12.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-01`.

## Requisitos
1. El formulario captura producto buscado, categoría, descripción, características, presupuesto máximo, cantidad y fecha o periodo.
2. Son obligatorios: producto, categoría, presupuesto máximo y cantidad; descripción, características y fecha son opcionales (RN-09).
3. Si faltan datos obligatorios, el sistema señala los campos pendientes.
4. La solicitud se guarda como **Activa** y queda visible para todos los usuarios.
5. Se respeta el máximo de solicitudes activas por usuario (RN-12; valor [POR DEFINIR]).
6. La solicitud expira en la fecha indicada o, si no hay fecha, tras [POR DEFINIR] días (RN-10).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/purchase_requests/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-13. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-13)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-13, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] El formulario captura producto buscado, categoría, descripción, características, presupuesto máximo, cantidad y fecha o periodo.
- [ ] Son obligatorios: producto, categoría, presupuesto máximo y cantidad; descripción, características y fecha son opcionales (RN-09).
- [ ] Si faltan datos obligatorios, el sistema señala los campos pendientes.
- [ ] La solicitud se guarda como **Activa** y queda visible para todos los usuarios.
- [ ] Se respeta el máximo de solicitudes activas por usuario (RN-12; valor [POR DEFINIR]).
- [ ] La solicitud expira en la fecha indicada o, si no hay fecha, tras [POR DEFINIR] días (RN-10).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
