# HU-16 — Responder "Yo tengo este producto" (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-16 / SCRUM-38 / Sprint 3 (26 oct – 6 nov 2026) / M-05 / [musubi-api:HU-16](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-16-yo-tengo-este-producto)

## Contexto
Jira (SCRUM-38): Como **usuario**, quiero **responder a una solicitud con "Yo tengo este producto", ya sea vinculando una publicación o describiendo un producto que todavía no publico**, para **ofrecerlo directamente al comprador**.

- Maqueta: `Se-busca`, `Yo-tengo-vincular`, `Yo-tengo-oferta`, `Yo-tengo-enviada`.
- Trazabilidad: RF-20, RF-40 · CU-11 · Flujo B · RN-06, RN-13, RN-14.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-15`, `HU-06`.

## Requisitos
1. Desde una solicitud **Activa** el usuario elige "Yo tengo este producto".
2. Puede **vincular una publicación existente** o crear una **oferta directa** (descripción, precio, estado del producto y fotografía opcional) sin publicarlo en el marketplace.
3. Si el usuario no tiene publicaciones, solo se ofrece la oferta directa.
4. La oferta directa solo es visible para el comprador que hizo la solicitud (RN-13).
5. Solo se permite una oferta por solicitud, que puede editarse (RN-14); no se puede responder a solicitudes propias (RN-06).
6. Si el precio supera el presupuesto, el sistema lo advierte pero permite enviar la oferta.
7. El comprador recibe una notificación (RF-40).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/purchase_requests/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-16. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-16)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-16, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Desde una solicitud **Activa** el usuario elige "Yo tengo este producto".
- [ ] Puede **vincular una publicación existente** o crear una **oferta directa** (descripción, precio, estado del producto y fotografía opcional) sin publicarlo en el marketplace.
- [ ] Si el usuario no tiene publicaciones, solo se ofrece la oferta directa.
- [ ] La oferta directa solo es visible para el comprador que hizo la solicitud (RN-13).
- [ ] Solo se permite una oferta por solicitud, que puede editarse (RN-14); no se puede responder a solicitudes propias (RN-06).
- [ ] Si el precio supera el presupuesto, el sistema lo advierte pero permite enviar la oferta.
- [ ] El comprador recibe una notificación (RF-40).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): decidir si una oferta directa aceptada se convierte en publicación (Anexo A, observación 2).
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
