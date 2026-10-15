# 01-04 — Configuración por ambiente (tareas)

## T1 — Config por ambiente y red de Android
- **Crear:** `config/*.example.json`, `config/README.md`, `lib/core/config/app_config.dart`, `android/app/src/{main,debug,profile}/res/xml/network_security_config.xml`, `test/core/config/app_config_test.dart`.
- **Verificar:** 7/7 pruebas; `config/dev.json` ignorado; critic PASS.
- **Estado:** ✅ Hecho (15-Oct-2026).

## Pendientes
- URLs reales de staging y prod → `musubi-api:02-05`.
- Opciones de Firebase → `HU-31` (política en la skill `critic-guardrails`).
