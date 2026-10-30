# HU-35 — Ver productos recomendados (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-35 / SCRUM-58 / Sprint 5 (23 nov – 4 dic 2026) / M-11 / [musubi-api:HU-35](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m11-recommendations/HU-35-productos-recomendados)

## Contexto
Jira (SCRUM-58): Como **comprador**, quiero **ver productos recomendados según mis intereses**, para **descubrir artículos que me pueden servir**.

- Maqueta: `Inicio`, `Recien-publicados`, `Recien-publicados-antiguas`.
- Trazabilidad: RF-48, RF-49 · CU-21 · RN-45, RN-46 · RNF-07.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-09`, `HU-11`.

## Requisitos
1. Se registran búsquedas, productos consultados, categorías de interés, compras, solicitudes e interacciones (RF-48).
2. Se muestran recomendaciones basadas en reglas: productos recientes de las categorías que el usuario más busca o consulta.
3. Si no hay datos suficientes, se muestran recomendaciones generales (productos recientes o categorías más activas) (RN-46).
4. No se recomiendan productos propios, vendidos o inactivos (RN-45).
5. El historial de interacciones es privado (RNF-07).

RNF que aplican: RNF-07.

## Diseño
- Feature `lib/features/recommendations/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-35. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-35)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-35, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Se registran búsquedas, productos consultados, categorías de interés, compras, solicitudes e interacciones (RF-48).
- [ ] Se muestran recomendaciones basadas en reglas: productos recientes de las categorías que el usuario más busca o consulta.
- [ ] Si no hay datos suficientes, se muestran recomendaciones generales (productos recientes o categorías más activas) (RN-46).
- [ ] No se recomiendan productos propios, vendidos o inactivos (RN-45).
- [ ] El historial de interacciones es privado (RNF-07).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): Versión básica en el MVP; el modelo con ML.NET queda para una etapa posterior.
- Decisión pendiente (Jira): Recomendación: implementar el registro de interacciones (RF-48) desde Sprint 2–3 para acumular datos.
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
