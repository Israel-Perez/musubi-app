# HU-33 — La IA identifica los datos del acuerdo (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-33 / SCRUM-53 / Sprint 4 (9 – 20 nov 2026) / M-10 / [musubi-api:HU-33](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m10-genai/HU-33-ia-datos-acuerdo)

## Contexto
Jira (SCRUM-53): Como **comprador o vendedor**, quiero **que la IA identifique producto, precio, cantidad, entrega y fecha a partir del chat**, para **convertir la conversación en una propuesta de acuerdo**.

- Maqueta: `Mensajes`, `Chat`, `Acuerdo-esperando`, `Acuerdo-confirmado`.
- Trazabilidad: RF-45 · CU-16 · RN-42, RN-43.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-32`.

## Requisitos
1. La IA propone producto, precio acordado, cantidad, lugar de entrega, fecha y condiciones.
2. Lo que no se mencionó en la conversación se marca como **"No identificado"** (RN-42).
3. La IA no negocia, no envía mensajes en nombre de los usuarios y no acepta ni rechaza tratos (RN-43).
4. La aplicación valida que la respuesta contenga siempre los mismos campos antes de mostrarla.

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/genai/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-33. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-33)` (skill `deferred-scope-fakes`).
- La propuesta de la IA se muestra editable, con su etiqueta, y lo que falta como "No identificado" (guía de estilo).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-33, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] La IA propone producto, precio acordado, cantidad, lugar de entrega, fecha y condiciones.
- [ ] Lo que no se mencionó en la conversación se marca como **"No identificado"** (RN-42).
- [ ] La IA no negocia, no envía mensajes en nombre de los usuarios y no acepta ni rechaza tratos (RN-43).
- [ ] La aplicación valida que la respuesta contenga siempre los mismos campos antes de mostrarla.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
