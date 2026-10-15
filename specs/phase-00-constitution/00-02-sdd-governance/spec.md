# 00-02 — Gobernanza SDD y Definition of Done

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) · contraparte: `musubi-api:00-02`

## Contexto
Define cómo se escriben, revisan, aprueban y verifican las specs de musubi-app. Las reglas comunes viven en la constitución §3 y §4 (secciones compartidas); esta spec fija el DoD ejecutable de este repo. **Depende de**: `00-01`.

## Requisitos
1. Cada spec usa `specs/_template.md` y vive en su carpeta con `spec.md`, `plan.md` y `task.md`.
2. Cada spec define criterios verificables por comando o prueba.
3. La trazabilidad spec ↔ código ↔ test ↔ Jira se cierra en `docs/trazabilidad.md`.
4. Revisión: 1 integrante distinto del autor. Una spec solo queda "✅ Aprobado" si el usuario indica el revisor; si no, queda en "🚧 Borrador con evidencia".
5. Un cambio de principios o de stack actualiza la constitución, el bloque de aprobación y `Memoria.md` (las dos Memoria.md si la sección es compartida).

## Diseño

**Definition of Done por tipo de spec:**

| Tipo | DoD |
|---|---|
| Constitucional (00-*) | Plantilla completa + bloque de aprobación + citas cruzadas (`AGENTS.md`, `Memoria.md`). |
| Técnica (01-*, 02-*) | Plantilla + format/analyze/test en verde + critic PASS + `spec/plan/task` conciliados con los archivos reales + Memoria.md. |
| Funcional (HU-NN) | Lo anterior + cada endpoint consumido enlaza su fila de `musubi-api/docs/endpoints.md` (o un fake con `NOTE (musubi-api:HU-NN)`) + widget tests de las pantallas + fila de `docs/trazabilidad.md` con Spec, Contraparte y Tests + PR con clave Jira que enlaza el PR del back. |
| Fix | Mismo DoD que su tipo + clave Jira del bug + prueba que reproduce el fallo. |

**Comandos del DoD (musubi-app):**

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter build apk --debug --dart-define-from-file=config/dev.example.json
pwsh scripts/critic-guardrails.ps1
```

**Flujo:** spec (Borrador) → `slice-scaffolder` (esqueleto compilable) → implementación + pruebas → `security-reviewer` (gate pre-push, MASVS) → `traceability-clerk` → PR → "Borrador con evidencia" → firma con revisor → "Aprobado".

## Contratos
N/A — spec de gobernanza. Referencia normativa: `specs/_template.md` y constitución §3–§5.

## Tests
N/A — se verifica aplicando la plantilla a las 9 specs de las fases 00 y 01 de este repo.

## Criterios
- Las 9 specs de las fases 00 y 01 tienen las 7 secciones + aprobación (`grep -c "^## " specs/phase-0*/*/spec.md` → 8 por archivo).
- Cada criterio de las specs 01-* cita un comando o una prueba concreta.
- Ningún cambio a la constitución queda sin entrada en `Memoria.md`.

## Límites
La trazabilidad es documental (Markdown + enlaces + Jira). La firma de revisores depende de que el equipo designe roles (PO/SM pendientes).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 15-Oct-2026
- **Detalle:** Plantilla y DoD adaptados de la referencia al front; comandos de Flutter.
