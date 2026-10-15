# plan.md — 01-05 Estructura, calidad y CI

1. **Componentes:** `analysis_options.yaml`, `scripts/`, `.semgrep/`, `.github/`, `.claude/`, `.gitignore`, `.gitattributes`, `.editorconfig`.
2. **Decisiones:**
   - `todo: error` en el analizador: equivalente a S1135 del back.
   - B4 con conteo de llaves (no solo regex de una línea) para distinguir un `catch` que traduce el error de uno que lo traga.
   - Semgrep con `languages: [generic]` (no hay parser de Dart).
   - `build-apk` solo en push a `main`.
3. **Guardarraíles:** self-test de cada guard con un caso de control (00-04 #18).
4. **Validación:** format, analyze, test, critic (5.1 y pwsh), YAML (PyYAML + actionlint), Semgrep auto + reglas propias.
5. **Secuencia:** análisis → critic + self-test → Semgrep + self-test → CI → Dependabot → Claude Code.
