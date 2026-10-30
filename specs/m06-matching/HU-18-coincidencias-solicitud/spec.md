# HU-18 — Ver coincidencias al publicar una solicitud (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-18 / SCRUM-40 / Sprint 3 (26 oct – 6 nov 2026) / M-06 / [musubi-api:HU-18](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m06-matching/HU-18-coincidencias-solicitud)

## Contexto
Jira (SCRUM-40): Como **comprador**, quiero **que al publicar mi solicitud el sistema me muestre productos ya publicados que coinciden**, para **no tener que buscarlos manualmente**.

- Maqueta: `Necesidad-1`, `Necesidad-3`, `Necesidad-publicada`, `Mis-solicitudes`.
- Trazabilidad: RF-22, RF-24, RF-25 · CU-13 · RN-32, RN-33 · RNF-11.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-13`, `HU-06`.

## Requisitos
1. Al publicar una solicitud, el sistema la compara con las publicaciones **Disponibles** y muestra las que coinciden.
2. La coincidencia considera como mínimo: misma categoría, similitud entre nombre o descripción y lo buscado, y precio dentro del presupuesto (RN-33).
3. Si no hay coincidencia exacta, se sugieren productos similares (misma categoría, términos parecidos o precio cercano al presupuesto) (RF-24).
4. Si no hay coincidencias, la solicitud queda visible para recibir ofertas.
5. Cada coincidencia se registra, junto con si se notificó y si terminó en pedido (RF-25).
6. El cálculo se ejecuta en segundo plano (RNF-11).

RNF que aplican: RNF-11.

## Diseño
- Feature `lib/features/matching/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-18. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-18)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-18, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Al publicar una solicitud, el sistema la compara con las publicaciones **Disponibles** y muestra las que coinciden.
- [ ] La coincidencia considera como mínimo: misma categoría, similitud entre nombre o descripción y lo buscado, y precio dentro del presupuesto (RN-33).
- [ ] Si no hay coincidencia exacta, se sugieren productos similares (misma categoría, términos parecidos o precio cercano al presupuesto) (RF-24).
- [ ] Si no hay coincidencias, la solicitud queda visible para recibir ofertas.
- [ ] Cada coincidencia se registra, junto con si se notificó y si terminó en pedido (RF-25).
- [ ] El cálculo se ejecuta en segundo plano (RNF-11).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
