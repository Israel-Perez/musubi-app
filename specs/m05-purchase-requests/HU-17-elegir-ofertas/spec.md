# HU-17 — Ver y elegir ofertas recibidas (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-17 / SCRUM-39 / Sprint 3 (26 oct – 6 nov 2026) / M-05 / [musubi-api:HU-17](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-17-elegir-ofertas)

## Contexto
Jira (SCRUM-39): Como **comprador**, quiero **ver las ofertas que recibí en mi solicitud**, para **comparar opciones y elegir la que más me convenga**.

- Maqueta: `Necesidad-1`, `Necesidad-3`, `Necesidad-publicada`, `Mis-solicitudes`.
- Trazabilidad: RF-21 · CU-12.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-16`.

## Requisitos
1. El comprador ve las ofertas recibidas en cada solicitud.
2. Desde cada oferta puede abrir un chat con quien ofrece, rechazarla o aceptarla.
3. Aceptar una oferta inicia un pedido.

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/purchase_requests/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-17. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-17)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-17, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] El comprador ve las ofertas recibidas en cada solicitud.
- [ ] Desde cada oferta puede abrir un chat con quien ofrece, rechazarla o aceptarla.
- [ ] Aceptar una oferta inicia un pedido.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
