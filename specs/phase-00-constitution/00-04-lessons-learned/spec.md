# 00-04 — Lecciones aprendidas (musubi-app)

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) · contraparte: `musubi-api:00-04`

## Contexto
Reglas operativas derivadas de fallos reales: las de la referencia que aplican al front y las medidas al crear esta plantilla. Es la fuente canónica; `AGENTS.md` §10 solo la enlaza. **Depende de**: `00-01`.

## Requisitos
1. Cada regla cita su evidencia y la spec o skill donde aplica.
2. Sin duplicados con `AGENTS.md`.
3. Se agregan reglas cuando un error real se repite o cuesta más de 30 minutos.

## Diseño

### Heredadas de la referencia

| # | Regla | Evidencia | Aplica en |
|---|---|---|---|
| 1 | Verificar empíricamente antes de escribir (versiones, rutas, nombres). | Referencia WebAPIDevSecOpsScallingSDD, oct 2026 | skill `empirical-verification` |
| 2 | Medir tiempos reales antes de fijar timeouts o umbrales. | Referencia WebAPIDevSecOpsScallingSDD, oct 2026 | `lib/core/network/api_client.dart` (`NOTE (02-05)`) |
| 3 | Documentar límites conocidos en vez de hacks (`NOTE (ID)` en 4 capas). | Referencia WebAPIDevSecOpsScallingSDD, oct 2026 | skill `traceability` |
| 4 | Pruebas de frontera exactas (ambas ramas, mensajes). | Referencia WebAPIDevSecOpsScallingSDD, oct 2026 | skill `testing-strategy` |
| 5 | Scripts con respaldo explícito y salida determinista (`exit 0/1`). | Referencia WebAPIDevSecOpsScallingSDD, oct 2026 | `scripts/critic-guardrails.ps1` |
| 6 | `.gitignore` defensivo para artefactos y secretos locales. | Referencia WebAPIDevSecOpsScallingSDD, oct 2026 | `01-05` |
| 7 | Grupo de control antes de concluir (`status 0` no implica OK). | Referencia WebAPIDevSecOpsScallingSDD, oct 2026 | Self-test del critic (`ok()` de control) |
| 8 | Actions fijadas por SHA y YAML del CI validado en local. | Referencia WebAPIDevSecOpsScallingSDD, oct 2026 | `.github/workflows/ci-pr.yml` (PyYAML + actionlint) |
| 9 | `NOTE (ID)` y nunca `TODO`. | Referencia WebAPIDevSecOpsScallingSDD, oct 2026 | `todo: error` en `analysis_options.yaml`, critic B1, Semgrep |
| 10 | No duplicar tablas vivas: el catálogo canónico vive en un solo lugar y se enlaza. | Referencia WebAPIDevSecOpsScallingSDD, oct 2026 | skill `api-contract` (catálogo del back) |

### Propias de MUSUBI

| # | Regla | Evidencia | Aplica en |
|---|---|---|---|
| 11 | **Todo lo que va dentro del APK es público:** ningún secreto en el código, en los assets, en `config/*.json` ni en `--dart-define`. Las llaves privadas (IA, Firebase Admin, cifrado de datos de pago) viven solo en `musubi-api`. | Plantilla inicial MUSUBI, 15-Oct-2026 | critic B2, Semgrep `musubi-secret-in-dart-define`, `config/README.md` |
| 12 | En comentarios Dart no se empieza con la palabra "todo"/"Todo": la lint `flutter_style_todos` lo marca y `--fatal-infos` rompe el análisis (`todo: error` solo detecta "TODO" en mayúsculas). | Medido con un archivo de prueba, 15-Oct-2026 | Código Dart |
| 13 | very_good_analysis 11 + Dart 3.13 exigen `const new(...)` en los constructores (`unnecessary_type_name_in_constructor`); `dart fix --apply` lo corrige. | Medido: 12 hallazgos en el primer análisis, 15-Oct-2026 | Código Dart |
| 14 | En Windows, `sdkmanager.bat` está obsoleto y parte los argumentos en `;` (`platforms;android-36` → "Package not found"). Usar `android sdk install "<paquete>"` (cmdline-tools nuevas). Gradle (AGP) también falla al autoinstalar el NDK; instalarlo a mano: `android sdk install "ndk;28.2.13676358"`. | Medido: el build falló en "NDK 28.2.13676358 not installed", 15-Oct-2026 | `README.md` (setup) |
| 15 | `flutter build ... \| tail` devuelve el exit code de `tail`: revisar el exit de Flutter (o `"√ Built"`) antes de dar un build por bueno. | Medido: primer build "exit 0" con FAILURE de Gradle, 15-Oct-2026 | Scripts y CI |
| 16 | `flutter pub add` con dependencias del SDK (`integration_test`) falla al citar en Git Bash: editar `pubspec.yaml` y correr `flutter pub get`. | Medido, 15-Oct-2026 | Setup |
| 17 | En Riverpod 3, un provider `autoDispose` leído en `ProviderContainer.test` necesita un `listen` para no destruirse entre lecturas. | Pruebas de `status_providers_test.dart`, 15-Oct-2026 | skill `testing-strategy` |
| 18 | Un guardarraíl solo vale si muerde: self-test con violaciones a propósito + un caso de control que **no** debe fallar. | critic: 7 bloqueantes en el scratch y `ok()` sin falso positivo; Semgrep 5/5, 15-Oct-2026 | skill `critic-guardrails` |
| 19 | Verificar el APK real, no solo el Gradle: `aapt2 dump badging` (paquete y `targetSdkVersion`) y `dump xmltree` (manifiesto final). | Medido: `com.musubi.app`, `targetSdkVersion:'36'`, `allowBackup=false`, 15-Oct-2026 | `01-01` |

## Contratos
N/A — spec constitucional. Referencia normativa desde `AGENTS.md` §10.

## Tests
N/A — verificación manual: 19 filas, sin celdas vacías.

## Criterios
- 19 reglas, cada una con evidencia y cross-link.
- `AGENTS.md` §10 y `Memoria.md` enlazan esta spec (`grep -n "00-04" AGENTS.md Memoria.md`).

## Límites
Las reglas heredadas se citan como evidencia externa (referencia, oct 2026) hasta que el front las ejercite.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 15-Oct-2026
- **Detalle:** 10 reglas heredadas (adaptadas) + 9 propias medidas al crear la plantilla.
