<!-- Titulo: SCRUM-NN HU-NN <Titulo corto>: <resumen> (Tests N, analyze 0, critic PASS) -->

## Que cambia y por que

- Spec: `specs/...` (enlace)
- Jira: SCRUM-NN
- PR de la contraparte en musubi-api (si aplica): #

## Checklist

- [ ] Titulo con la clave Jira (`SCRUM-NN ...`) y rama `feature/SCRUM-NN-slug` o `fix/SCRUM-NN-slug`
- [ ] `dart format --output=none --set-exit-if-changed .` sin cambios
- [ ] `flutter analyze --fatal-infos --fatal-warnings` sin observaciones
- [ ] `flutter test` verde (conteo real en el titulo)
- [ ] Sin secretos: nada sensible en el codigo, en `config/*.json` ni en `--dart-define` (todo lo que va en el APK es publico)
- [ ] Sin `TODO`: solo `NOTE (NN-NN)` / `NOTE (HU-NN)` con su spec duena registrada en `task.md`
- [ ] Cada endpoint consumido enlaza su fila de `musubi-api/docs/endpoints.md` (o usa un fake con `NOTE (musubi-api:HU-NN)` si aun no existe)
- [ ] `pwsh scripts/critic-guardrails.ps1` PASS
- [ ] `spec.md`, `plan.md` y `task.md` conciliados con lo implementado; `docs/trazabilidad.md` actualizado
- [ ] `Memoria.md` actualizada (que, decisiones con su porque, errores a evitar)
