# 01-05 — Estructura, calidad y CI (tareas)

## T1 — Análisis estricto y guardarraíles
- **Crear:** `analysis_options.yaml`, `scripts/critic-guardrails.ps1`, `scripts/check_shared_sections.ps1`, `.semgrep/semgrep.yaml`.
- **Verificar:** analyze 0; critic PASS (5.1 y pwsh); self-tests: critic 7 FAIL + control OK, Semgrep 5/5.
- **Estado:** ✅ Hecho (15-Oct-2026).

## T2 — CI y Dependabot
- **Crear:** `.github/workflows/ci-pr.yml`, `.github/dependabot.yml`, `.github/pull_request_template.md`.
- **Verificar:** PyYAML + actionlint sin errores; Semgrep `--config=auto` exit 0.
- **Estado:** ✅ Hecho (15-Oct-2026).

## T3 — Claude Code
- **Crear:** `CLAUDE.md`, `.claude/agents/*`, `.claude/skills/*/SKILL.md`, `.claude/hooks/readonly-git-guard.ps1` (idéntico al del back).
- **Estado:** ✅ Hecho (15-Oct-2026).

## Pendientes
- Protección de `main` en GitHub → equipo. Cobertura con umbral → `02-01`.
