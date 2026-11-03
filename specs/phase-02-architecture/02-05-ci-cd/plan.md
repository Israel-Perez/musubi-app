# plan.md — 02-05 CI/CD

## 1. Componentes
- **Workflows:** `ci-pr.yml` y `release-play.yml`, ya existentes; esta spec los documenta.
- **Ruleset "Main Proteccion"** en `main`.

## 2. Decisiones
- **Publicación manual:** cada versión pasa por la revisión de Google, y la pista (interna, cerrada o producción) la decide una persona.
- **APK de debug solo después de fusionar:** ahorra minutos de Actions en cada PR.
- **El bypass del administrador es solo por PR** (ver `musubi-api:02-08`).

## 3. Validación
`actionlint`, `versioning_test.dart` y una corrida de `release-play`.
