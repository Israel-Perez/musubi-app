# HU-42 — Consultar indicadores de uso (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-42 / SCRUM-65 / Versión posterior (fuera del MVP) / M-14 / [musubi-api:HU-42](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-42-indicadores-uso)

## Contexto
Jira (SCRUM-65): Como **administrador**, quiero **consultar indicadores de uso**, para **evaluar cómo funciona la plataforma**.

- Maqueta: sin pantalla propia. Se diseña con la guía de estilo de la maqueta; el lineamiento 4 permite agregar, nunca quitar.
- Trazabilidad: RF-57 · CU-27.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-39`.

## Requisitos
1. El administrador consulta desde un panel los indicadores definidos en el apartado 19 de la propuesta (adopción, oferta, demanda, conexión, operaciones, chat, IA, vendedores y confianza).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/admin/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-42. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-42)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-42, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- Widget tests de las pantallas nuevas (sin escena de maqueta).

## Criterios
- [ ] El administrador consulta desde un panel los indicadores definidos en el apartado 19 de la propuesta (adopción, oferta, demanda, conexión, operaciones, chat, IA, vendedores y confianza).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Versión posterior al MVP (Jira: `version-posterior`): no entra en la evaluación del 02-Dic-2026.
- Decisión pendiente (Jira): Marcada como versión posterior; no forma parte del MVP.
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera — posterior al MVP)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
