# HU-34 — Revisar y confirmar la propuesta de la IA (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-34 / SCRUM-54 / Sprint 4 (9 – 20 nov 2026) / M-10 / [musubi-api:HU-34](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m10-genai/HU-34-confirmar-propuesta-ia)

## Contexto
Jira (SCRUM-54): Como **usuario**, quiero **revisar y corregir la propuesta de la IA antes de confirmarla**, para **asegurarme de que refleja lo que realmente acordamos**.

- Maqueta: `Mensajes`, `Chat`, `Acuerdo-esperando`, `Acuerdo-confirmado`.
- Trazabilidad: RF-46, RF-47 · CU-16 · RN-41.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-33`.

## Requisitos
1. Ambos participantes pueden revisar y corregir la propuesta.
2. Un participante la envía al otro, que la confirma o pide cambios; si la rechaza, se descarta y la conversación continúa.
3. El acuerdo solo es válido cuando **ambos** lo confirman (RN-41).
4. Un acuerdo confirmado se puede convertir en pedido con los datos ya llenados (RF-47).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/genai/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-34. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-34)` (skill `deferred-scope-fakes`).
- La propuesta de la IA se muestra editable, con su etiqueta, y lo que falta como "No identificado" (guía de estilo).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-34, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Ambos participantes pueden revisar y corregir la propuesta.
- [ ] Un participante la envía al otro, que la confirma o pide cambios; si la rechaza, se descarta y la conversación continúa.
- [ ] El acuerdo solo es válido cuando **ambos** lo confirman (RN-41).
- [ ] Un acuerdo confirmado se puede convertir en pedido con los datos ya llenados (RF-47).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
