# HU-20 — Iniciar una conversación con el vendedor (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-20 / SCRUM-29 / Sprint 2 (12 – 23 oct 2026) / M-07 / [musubi-api:HU-20](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m07-chat/HU-20-iniciar-conversacion)

## Contexto
Jira (SCRUM-29): Como **comprador**, quiero **iniciar una conversación con el vendedor desde la publicación o desde la oferta**, para **resolver dudas y negociar**.

- Maqueta: `Producto`, `Perfil-vendedor`, `Chat-Valeria`, `Mensajes`, `Chat`, `Acuerdo-esperando`, `Acuerdo-confirmado`.
- Trazabilidad: RF-26, RF-27 · CU-15 · RN-21, RN-22, RN-23 · RNF-10.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-11`.

## Requisitos
1. Se puede iniciar un chat desde una publicación, una solicitud o una oferta.
2. Cada conversación es entre dos usuarios y está asociada a una publicación, solicitud u oferta (RN-21).
3. Los mensajes de texto se entregan casi en tiempo real (RNF-10).
4. Solo los participantes pueden leer la conversación (RN-22).
5. Los mensajes pueden reportarse (RN-23).

RNF que aplican: RNF-10.

## Diseño
- Feature `lib/features/chat/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-20. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-20)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-20, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Se puede iniciar un chat desde una publicación, una solicitud o una oferta.
- [ ] Cada conversación es entre dos usuarios y está asociada a una publicación, solicitud u oferta (RN-21).
- [ ] Los mensajes de texto se entregan casi en tiempo real (RNF-10).
- [ ] Solo los participantes pueden leer la conversación (RN-22).
- [ ] Los mensajes pueden reportarse (RN-23).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): En Sprint 2 se habilita desde publicaciones; el inicio desde solicitudes y ofertas se completa en Sprint 3.
- Decisión pendiente (Jira): envío de imágenes [POR DEFINIR] (RF-27).
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
