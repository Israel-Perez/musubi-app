# HU-32 — Pedir un resumen de la conversación con IA (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-32 / SCRUM-52 / Sprint 4 (9 – 20 nov 2026) / M-10 / [musubi-api:HU-32](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m10-genai/HU-32-resumen-ia)

## Contexto
Jira (SCRUM-52): Como **usuario**, quiero **pedir un resumen de la conversación**, para **recordar lo que se ha platicado**.

- Maqueta: `Mensajes`, `Chat`, `Acuerdo-esperando`, `Acuerdo-confirmado`.
- Trazabilidad: RF-44 · CU-16 · Flujo E · RN-39, RN-40 · RNF-06, RNF-12, RNF-15.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-20`.

## Requisitos
1. La IA solo se ejecuta cuando un participante lo solicita; no analiza conversaciones de forma automática (RN-39).
2. Ambos participantes saben que la conversación puede procesarse con IA (RN-40).
3. Solo se envía al servicio de IA la información mínima necesaria (RNF-06).
4. Se muestra un indicador de proceso mientras se genera el resumen (RNF-12).
5. Si el servicio de IA no está disponible, se informa y el chat sigue funcionando (RNF-15).

RNF que aplican: RNF-06, RNF-12, RNF-15.

## Diseño
- Feature `lib/features/genai/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-32. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-32)` (skill `deferred-scope-fakes`).
- La propuesta de la IA se muestra editable, con su etiqueta, y lo que falta como "No identificado" (guía de estilo).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-32, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] La IA solo se ejecuta cuando un participante lo solicita; no analiza conversaciones de forma automática (RN-39).
- [ ] Ambos participantes saben que la conversación puede procesarse con IA (RN-40).
- [ ] Solo se envía al servicio de IA la información mínima necesaria (RNF-06).
- [ ] Se muestra un indicador de proceso mientras se genera el resumen (RNF-12).
- [ ] Si el servicio de IA no está disponible, se informa y el chat sigue funcionando (RNF-15).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): mecanismo de consentimiento (RN-40) y tiempo de conservación de datos procesados por la IA (RN-44).
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
