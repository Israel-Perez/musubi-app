---
name: spec-first-writing
description: Redactar specs del front de MUSUBI (técnicas NN-NN o de HU) con la plantilla SDD, enlazando el contrato del back y con criterios verificables por comando o prueba. Úsala antes de implementar cualquier HU o cambio técnico, y al refinar una spec.
---

## Propósito
Que cada pantalla o flujo nazca de una spec vertical (`spec.md` + `plan.md` + `task.md`) con criterios comprobables y con el contrato HTTP enlazado al back.

## Cuándo usarla
- Al iniciar el sprint de una HU (crear `specs/mNN-<modulo>/HU-NN-<slug>/`, la misma carpeta que en `musubi-api`).
- Antes de un cambio técnico (fase 02 y siguientes).
- Al cerrar una spec (conciliar con lo implementado).

## Precondiciones
- Haber leído `.specify/memory/constitution.md`, `specs/_template.md` y `00-02`.
- Conocer la fila de la HU en `docs/trazabilidad.md`, su módulo en `docs/modulos.md` y la spec de la contraparte en `musubi-api`.

## Pasos
1. Copiar `specs/_template.md`; llenar `HU / Jira / Sprint / Módulo / Contraparte` con el enlace a la spec del back.
2. **Contexto:** actor, problema y `**Depende de**:` (incluye `musubi-api:HU-NN` si se necesita el endpoint).
3. **Requisitos:** numerados, citando los RNF del front (RNF-12 indicador, RNF-17 pocos pasos, RNF-18 español, RNF-19, RNF-20, RNF-27).
4. **Diseño:** archivos reales bajo `lib/features/<modulo>/{domain,data,presentation}`; estados de la pantalla (cargando / datos / vacío / error); fake si el endpoint no existe (skill `deferred-scope-fakes`).
5. **Contratos:** **enlazar** las filas de `musubi-api/docs/endpoints.md` (skill `api-contract`); nunca copiar DTOs ni códigos.
6. **Tests:** rutas reales (`test/features/<modulo>/data/…`, `…/presentation/…_test.dart`, `integration_test/…`).
7. **Criterios:** con su comando (`flutter test` N/N, `flutter analyze` 0, critic PASS) y el comportamiento observable de cada estado.
8. **Límites** con sus dueños; **Aprobación** honesta.
9. `plan.md` y `task.md` operativos.

## Checklist
Encabezado con contraparte · RNF citados · estados de UI · contrato enlazado · pruebas con rutas · criterios con comando · límites con dueño.

## Criterios de done
Cada criterio se puede ejecutar o comprobar; 8 encabezados `##` (comparación estructural de `00-02`).

## Límites/trampas
- No escribir specs horizontales ("todas las pantallas"): una spec = una HU vertical.
- No duplicar el catálogo del back ni `docs/modulos.md`.
- No inventar umbrales (tiempo de carga, tamaño de foto): "🎯 Por definir con el PO".

## Referencias
`specs/_template.md`, `00-02`, skills `api-contract`, `vertical-slice`, `traceability`.
