# 01-05 — Estructura del repositorio, calidad y CI

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) · contraparte: `musubi-api:01-05`

## Contexto
Árbol del repo, análisis estricto, guardarraíles, SAST, CI, Dependabot y herramientas de Claude Code del front. **Depende de**: `01-01`.

## Requisitos
1. `analysis_options.yaml` estricto (`very_good_analysis` + `strict-casts`, `strict-inference`, `strict-raw-types`, `todo: error`).
2. `dart format` y `flutter analyze --fatal-infos --fatal-warnings` sin observaciones.
3. `scripts/critic-guardrails.ps1` con 4 bloqueantes, compatible con PS 5.1 y pwsh.
4. Semgrep con al menos 2 reglas propias reales.
5. CI con actions fijadas por SHA y Flutter fijado: `analyze`, `test` (cobertura como artefacto), `critic`, `semgrep` y `build-apk` (Java 17, solo en push a `main`).
6. Dependabot (pub, github-actions) con `cooldown`.
7. `.gitignore` defensivo (config real, Firebase, firma, llaves).
8. Sub-agentes y skills de Claude Code con solo lectura forzada en los revisores.

## Diseño

| Ruta | Tipo | Estado |
|---|---|---|
| `lib/` (`app/`, `core/`, `features/status/`) | Código | ✅ |
| `test/` (`core/`, `features/status/`, `helpers/`) | Unit + widget | ✅ (18) |
| `integration_test/` | Esqueleto (dispositivo) | ✅ (1, no corre en CI) |
| `android/` | Proyecto Android (`com.musubi.app`) | ✅ |
| `config/` | `*.example.json` + README | ✅ |
| `docs/` | `trazabilidad.md`, `modulos.md` | ✅ |
| `scripts/` | `critic-guardrails.ps1`, `check_shared_sections.ps1` | ✅ |
| `.semgrep/semgrep.yaml` | 5 reglas propias | ✅ |
| `.github/` | `workflows/ci-pr.yml`, `dependabot.yml`, `pull_request_template.md` | ✅ |
| `.claude/` | `agents/` (3 + README), `skills/` (9), `hooks/readonly-git-guard.ps1` | ✅ |

**Bloqueantes del critic:** ver la skill `critic-guardrails` (B1 TODO · B2 secretos · B3 `http://` en `lib/` · B4 `catch` vacío o que ignora la excepción).

## Contratos
- Nombres de los jobs del CI = checks obligatorios recomendados para `main` (README).

## Tests
- Self-tests (Memoria.md, 15-Oct-2026): critic con un scratch → FAIL con 7 bloqueantes (B1, B2×3, B3, B4×2) + 1 aviso, sin falso positivo en el `catch` de control; Semgrep con un scratch → 5/5 reglas; hook → mismo comportamiento que en el back.

## Criterios
- `dart format --output=none --set-exit-if-changed .` → 0 cambios.
- `flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`.
- `flutter test` → 18/18.
- `pwsh scripts/critic-guardrails.ps1` → PASS (y con `powershell -File` en 5.1).
- `python -c "import yaml; yaml.safe_load(open('.github/workflows/ci-pr.yml'))"` y `actionlint .github/workflows/ci-pr.yml` → sin errores.
- `semgrep scan --config=auto --config=.semgrep/semgrep.yaml --error` → exit 0.
- `git status` sin `build/`, `.dart_tool/` ni `config/*.json` reales.

## Límites
El job `build-apk` no corre en los PR (ahorra minutos). `integration_test` requiere un dispositivo.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 15-Oct-2026
- **Detalle:** Condición de `build-apk`: `github.event_name == 'push' && github.ref == 'refs/heads/main'` (ajuste pedido por el usuario).
