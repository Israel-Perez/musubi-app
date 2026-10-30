# HU-14 — Editar, cerrar o cancelar mi solicitud (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-14 / SCRUM-36 / Sprint 3 (26 oct – 6 nov 2026) / M-05 / [musubi-api:HU-14](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-14-gestionar-solicitud)

## Contexto
Jira (SCRUM-36): Como **comprador**, quiero **editar, cerrar o cancelar mi solicitud**, para **que refleje si todavía necesito el producto**.

- Maqueta: `Necesidad-1`, `Necesidad-3`, `Necesidad-publicada`, `Mis-solicitudes`.
- Trazabilidad: RF-17, RF-18 · CU-09 · RN-11, RN-15.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-13`.

## Requisitos
1. El comprador puede editar, cerrar (ya consiguió el producto) o cancelar sus solicitudes.
2. Los estados son **Activa**, **Cerrada**, **Cancelada** y **Expirada**; solo las activas reciben ofertas (RN-11).
3. La solicitud pasa a **Expirada** automáticamente al vencer su fecha límite o el periodo máximo (RF-18).
4. Al completarse un pedido originado en la solicitud, el sistema propone cerrarla (RN-15).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/purchase_requests/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-14. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-14)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-14, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] El comprador puede editar, cerrar (ya consiguió el producto) o cancelar sus solicitudes.
- [ ] Los estados son **Activa**, **Cerrada**, **Cancelada** y **Expirada**; solo las activas reciben ofertas (RN-11).
- [ ] La solicitud pasa a **Expirada** automáticamente al vencer su fecha límite o el periodo máximo (RF-18).
- [ ] Al completarse un pedido originado en la solicitud, el sistema propone cerrarla (RN-15).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
