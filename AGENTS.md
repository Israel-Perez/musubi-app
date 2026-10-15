# AGENTS.md — Guía operativa de musubi-app para agentes y desarrolladores

> Qué no se negocia: `.specify/memory/constitution.md` (manda ante cualquier conflicto).
> Principios y stack: `specs/phase-00-constitution/00-01-principles-stack/spec.md`. No se agregan paquetes fuera del stack sin la regla de excepción de 00-01.
> Repo hermano: [`musubi-api`](https://github.com/Israel-Perez/musubi-api) (back .NET 10). El contrato HTTP canónico es `musubi-api/docs/endpoints.md`: aquí se enlaza, nunca se copia.

## 1. Forma de trabajo

- **Setup:** Flutter 3.47.7 (stable), JDK 17 y Android SDK (platform `android-36`, build-tools 36.1.0, NDK 28.2.13676358). En Windows, instala los paquetes con `android sdk install "<paquete>"` (`sdkmanager.bat` parte los argumentos en `;`).
- `Copy-Item config/dev.example.json config/dev.json` → `flutter run --dart-define-from-file=config/dev.json` (emulador contra musubi-api local en `http://10.0.2.2:5080`).
- **Comandos:**
  - `dart format --output=none --set-exit-if-changed .`
  - `flutter analyze --fatal-infos --fatal-warnings`
  - `flutter test`
  - `flutter build apk --debug --dart-define-from-file=config/dev.example.json`
  - `pwsh scripts/critic-guardrails.ps1`
- **CI (`ci-pr.yml`):** `analyze`, `test` (cobertura como artefacto), `critic`, `semgrep`; `build-apk` solo en push a `main`.
- **Flujo SDD por HU:** spec (`specs/mNN-<modulo>/HU-NN-<slug>/`, misma carpeta que en el back; skill `spec-first-writing`) → `slice-scaffolder` (Fase A) → implementación y pruebas (skill `vertical-slice`) → `security-reviewer` → `traceability-clerk` → PR que enlaza el PR del back.
- **Ramas y PR:** `feature/SCRUM-NN-slug` / `fix/SCRUM-NN-slug`; un PR = una HU o un fix; título con la clave Jira; checklist de `.github/pull_request_template.md` obligatorio.
- **Naming:** código en inglés; textos de la UI, documentos y specs en español.
- Sin secretos (todo lo que va en el APK es público), sin `TODO` (solo `NOTE (ID)`), sin `print`, sin código muerto.
- Al terminar, resume qué cambiaste y qué decisiones debe revisar el usuario.

## 2. Memoria

> **Gobernanza SDD:** plantilla obligatoria en `specs/_template.md` y DoD en `specs/phase-00-constitution/00-02-sdd-governance/spec.md`. Cada spec nueva sigue la plantilla; los criterios siempre se verifican con un comando o una prueba.

- `AGENTS.md`: manual operativo vivo. `Memoria.md`: bitácora del estado, las decisiones y las lecciones.
- **Al empezar**, lee `Memoria.md`.
- **Al terminar una tarea**, actualízala: estado actual, decisiones importantes (con su porqué) y errores a evitar.
- **Al cerrar una spec**, concilia `spec.md`/`plan.md`/`task.md` con lo implementado y resuelve la aprobación: "Borrador con evidencia", o "Aprobado" solo si el usuario indicó un revisor.
- Mantenla breve (máximo ~10 000 líneas). Las reglas permanentes se mueven a `AGENTS.md` o a `00-04`.
- Nunca guardes datos sensibles.
- Si cambias una **sección compartida** (`<!-- Sección compartida … -->`), cámbiala también en `musubi-api`, regístralo en las dos `Memoria.md` y corre `pwsh scripts/check_shared_sections.ps1`.

## 3. Límites

- No pongas secretos en el código, los assets, `config/*.json` ni `--dart-define`: las llaves privadas viven solo en `musubi-api`.
- No escribas `http://` en `lib/` (la URL de dev vive en `config/`).
- No empieces un comentario con la palabra "todo" en español: `flutter_style_todos` rompe el análisis.
- No llames a Dio desde la UI: pantalla → provider → interfaz del repositorio.
- No dejes que una excepción de red llegue a la UI: tradúcela a un estado de dominio con mensaje en español.
- No copies el catálogo del back (DTOs, códigos) en las specs: enlaza la fila.
- No des por bueno un build mirando el exit code de un pipe (`| tail`): revisa el de Flutter.
- Versiona solo `config/*.example.json`; los reales y los archivos de Firebase están ignorados.
- Siempre: actualiza `Memoria.md` al terminar cada tarea.

## 4. Verificación

- `dart format` sin cambios y `flutter analyze --fatal-infos --fatal-warnings` sin observaciones.
- `flutter test` 100 % en verde.
- `pwsh scripts/critic-guardrails.ps1` → `PASS` exit 0 (también con `powershell -File` en 5.1).
- `flutter build apk --debug --dart-define-from-file=config/dev.example.json` → `√ Built`; si tocas Android, revisa el APK con `aapt2 dump badging` (paquete `com.musubi.app`, `targetSdkVersion:'36'`).
- YAML del CI: `python -c "import yaml; yaml.safe_load(open('.github/workflows/ci-pr.yml'))"` y `actionlint .github/workflows/ci-pr.yml`.
- SAST antes del primer push de una rama: `semgrep scan --config=auto --config=.semgrep/semgrep.yaml --error`.

### 4.2 Requerimientos no funcionales

Tabla y comandos: `specs/phase-00-constitution/00-03-nfr/spec.md`. Si un cambio impacta un umbral (tiempo de carga, tamaño de foto, contraste), ejecuta su verificación antes de pedir la aprobación.

### 4.3 Configuración

Claves y estado: `specs/phase-01-foundation/01-04-config-reference/spec.md` + `config/README.md`.

## 5. Convenciones técnicas

> Fase 01 implementada (15-Oct-2026), en "Borrador con evidencia".

- Feature-first: `lib/app/`, `lib/core/{config,network,errors,theme}`, `lib/features/<modulo>/{domain,data,presentation}` (ver `lib/features/README.md`).
- Patrón de referencia: `lib/features/status/` (repositorio + fake + provider + estados de UI).
- Rutas de la API en `lib/core/network/api_paths.dart`, cada una citando su fila del catálogo del back (skill `api-contract`).
- Riverpod 3 sin codegen; go_router; dio; Material 3; `es-MX`.
- Dart 3.13 + very_good_analysis 11: constructores `const new(...)` (`dart fix --apply`).
- Pendientes con dueño: sesión y token seguro → HU-02; SignalR → HU-20; FCM → HU-31; Crashlytics, navegación por módulos y componentes base → 02-01; firma de subida → 02-02.

## 6. Seguridad (OWASP MASVS)

- MASVS-STORAGE: nada sensible en el APK; token en `flutter_secure_storage` (HU-02); `allowBackup=false`.
- MASVS-NETWORK: HTTPS fuera de dev (`AppConfig.parse`); release sin tráfico en claro; debug solo hacia `10.0.2.2`.
- MASVS-CODE: análisis estricto, Dependabot con `cooldown`, paquetes evaluados (00-01).
- MASVS-PRIVACY: datos mínimos, aviso de privacidad (HU-47), eliminación de cuenta (HU-46), la IA solo a petición (RNF-06).
- Firebase (HU-31): política en la skill `critic-guardrails` (archivos ignorados, regenerados en CI desde secretos).
- Checks del agente `security-reviewer`: `.claude/agents/security-reviewer.md`.

## 7. Testing

- Unit (config, repositorios con `FakeHttpAdapter`, providers con `ProviderContainer.test`) + widget tests por estado de cada pantalla.
- `integration_test/` corre en un emulador o dispositivo (no en el CI de PR).
- Matriz completa: skill `testing-strategy`.

## 8. Observabilidad

> 🚧 Pendiente (`02-01`): Firebase Crashlytics y registro de errores sin PII.

## 9. Publicación

> 🚧 Pendiente (`02-02`): firma de subida (`android/key.properties`, ignorado), ficha de Google Play, prueba cerrada desde el 09-Nov-2026 y publicación el 04-Dic-2026.

## 10. Reglas basadas en lecciones aprendidas

La fuente canónica es `specs/phase-00-constitution/00-04-lessons-learned/spec.md` (10 heredadas + 9 propias).

## 11. Sub-agentes (híbrido agentes → skills)

- `slice-scaffolder`: Fase A del lado front de una HU (modelo → repositorio/fake → estado → pantalla → pruebas).
- `security-reviewer`: gate pre-push contra OWASP MASVS; **solo lectura forzada** (`disallowedTools` + hook `readonly-git-guard.ps1`).
- `traceability-clerk`: spec ↔ código ↔ test ↔ Jira ↔ contraparte; solo lectura forzada.
- Reglas en `.claude/skills/` (9 skills); convención en `.claude/agents/README.md`.

---

## Estructura del repo

| Carpeta | Contenido |
|---|---|
| `lib/` | `main.dart`, `app/`, `core/`, `features/` |
| `test/` | Unit + widget (`core/`, `features/`, `helpers/`) |
| `integration_test/` | Pruebas en un dispositivo (esqueleto) |
| `android/` | Proyecto Android (`com.musubi.app`, targetSdk 36) |
| `config/` | `*.example.json` por ambiente + README |
| `docs/` | `trazabilidad.md` (47 HU), `modulos.md` (14 módulos) |
| `specs/` | SDD: plantilla, fases 00 y 01, `mNN-*/HU-NN-*` |
| `scripts/` | `critic-guardrails.ps1`, `check_shared_sections.ps1` |
| `.claude/` | `agents/` (3), `skills/` (9), `hooks/` |
| `.github/` | CI, Dependabot, plantilla de PR |
| `.semgrep/` | Reglas SAST propias |
