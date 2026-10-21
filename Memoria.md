# Memoria del proyecto — musubi-app

Bitácora viva: estado, decisiones con su porqué y errores a evitar. Reglas de mantenimiento en `AGENTS.md` §2. Las lecciones permanentes viven en `specs/phase-00-constitution/00-04-lessons-learned/spec.md`.

## Estado actual (20-Oct-2026)

- **SCRUM-66** (rama `feature/SCRUM-66-stack-nosql`, PR abierto junto con el del back): maqueta versionada, matriz de versionamiento y lineamientos.
- format 0 cambios · analyze 0 · test 20/20 · critic PASS · Semgrep 0 · actionlint 0 · shared OK (5 bloques).
- Siguiente: `02-01` (navegación, sesión, componentes base, tema con los tokens de la maqueta, permisos, caché local) antes de HU-01.

## T3 — Maqueta, versionamiento y lineamientos (20-Oct-2026, SCRUM-66)

**Qué se hizo**
- Maqueta HTML del equipo en `docs/maqueta/musubi-prototipo.html` (60 pantallas en 10 secciones + guía de estilo; SHA-256 en su README). En `.gitattributes` va como `-text -diff linguist-documentation` para conservar los bytes.
- `docs/maqueta/README.md`: tokens de diseño, pantallas ↔ HU (propuesta), 7 funciones sin HU (G-01…G-07) y la decisión D-01 (pago).
- Constitución §1 (compartida, copiada del back): evaluación el **02-Dic-2026**; los lineamientos de la materia mandan; la app es igual a la maqueta. §6: diseño visual y datos locales → `NOTE (02-01)`.
- `docs/versionado.md` (sección compartida) + `test/versioning_test.dart` (la `version` de `pubspec.yaml`, hoy `0.1.0+1`, debe coincidir con la última fila de la matriz).
- 00-03: RNF-20/RNF-27 con la paleta y el área táctil de la maqueta; filas L-04 (fidelidad a la maqueta) y Versionamiento.

**Decisiones (con su porqué)**
- **Los lineamientos viven en el back y aquí se enlazan** (como `endpoints.md`): una sola tabla viva.
- **La maqueta se versiona en el repo** (y no solo en Drive): las specs citan pantallas por ID y el evaluador revisa el proyecto con prompts.
- La maqueta solo trae personas y correos ficticios (comparados contra los usuarios de Jira el 20-Oct-2026); su contraseña de demo no es una credencial.

**Pendientes / decisiones del usuario**
- **D-01:** la maqueta paga por transferencia (CLABE) o efectivo y "no cobra comisión"; HU-43 (Mercado Pago) no aparece. El lineamiento 4 impide quitar lo de la maqueta.
- **G-01…G-07** (visitante, populares, inventario, comparar/Avísame, apartados con QR, favoritos, modo noche) necesitan HU en Jira.
- Riesgo de calendario: una cuenta personal nueva de Google Play exige 14 días de prueba cerrada con 12 testers antes de producción; desde el 09-Nov el margen hacia el 02-Dic es corto.

## T2 — Publicación en GitHub (15-Oct-2026)

- Repos **públicos**: `https://github.com/Israel-Perez/musubi-app` (y `musubi-api`). En GitHub gratuito, público habilita la protección de rama, minutos de Actions ilimitados y secret scanning sin costo. La plantilla ya parte de que no hay nada secreto en el repo.
- **Sin nombres de personas en el repo público** (decisión del usuario): se quitaron del §1 de la constitución (sección compartida, los dos repos), del crédito del README y del prompt archivado. Los nombres viven en Jira y Confluence.
- **Commit inicial sin clave Jira** (decisión del usuario: la tarea de plantilla no tiene clave). Desde la primera HU, cada commit y PR empieza con `SCRUM-NN`.
- Protección de `main`: ver el README (sección "Protección de rama recomendada") y la configuración aplicada con `gh`.

## T1 — Plantilla inicial SDD + DevSecOps (15-Oct-2026)

**Qué se hizo**
- Proyecto creado con `flutter create --org com.musubi --project-name musubi_app --platforms android`; applicationId/namespace definitivos **`com.musubi.app`** (confirmados por el usuario antes de crear) y `MainActivity` movida a `com/musubi/app`.
- Arquitectura feature-first: `lib/app/` (MusubiApp, router), `lib/core/` (config, network, errors, theme), `lib/features/status/` (ping a la API: domain/data/presentation), convención en `lib/features/README.md`.
- Primera conexión con el back: `HttpStatusRepository` → `GET /api/v1/ping` (fila de `musubi-api/docs/endpoints.md`), con fake y una pantalla inicial que no se rompe sin API.
- Config por ambiente con `--dart-define-from-file` (`config/*.example.json` versionados; los reales, ignorados) + `AppConfig.parse` (HTTPS fuera de dev) + `network_security_config` (release sin tráfico en claro; debug/profile solo `10.0.2.2`). `allowBackup=false`.
- Gobernanza: constitución (§1–§5 copiadas byte a byte de `musubi-api`), plantilla, `docs/modulos.md` (compartidos), specs 00-01…00-04 y 01-01…01-05, `AGENTS.md`, `CLAUDE.md`, `docs/trazabilidad.md` (47 HU).
- Guardarraíles: `analysis_options.yaml` estricto (`todo: error`), critic B1–B4, Semgrep (5 reglas generic), CI de 5 jobs, Dependabot (pub/actions con `cooldown`), plantilla de PR.
- Claude Code: 3 agentes (revisores con solo lectura forzada por `disallowedTools` + hook PowerShell idéntico al del back) y 9 skills (8 comunes + `api-contract`).
- El prompt original de la plantilla está archivado en `musubi-api/docs/bitacora/prompt-plantilla-inicial.md`.

**Versiones medidas (15-Oct-2026)**
- Flutter 3.47.7 (stable, rev abaf9c5237) · Dart 3.13.5 · DevTools 2.60.0.
- Android: platform `android-36`, build-tools 36.1.0, NDK 28.2.13676358, AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, JDK 17.0.20 (Microsoft OpenJDK); `minSdk` 24, `targetSdk`/`compileSdk` 36 (de `FlutterExtension.kt`, verificado en el APK con aapt2).
- Paquetes: flutter_riverpod 3.4.3 (MIT), go_router 18.1.0 (BSD-3), dio 5.11.1 (MIT), very_good_analysis 11.0.0 (MIT); licencias leídas del pub cache.
- CI: checkout v7.0.1, subosito/flutter-action v2.23.0, setup-java v6.1.0, setup-python v7.0.0, upload-artifact v7.0.2 (SHAs en `ci-pr.yml`); Semgrep 1.181.0.

**Decisiones (con su porqué)**
- **Riverpod** (sin codegen), **go_router** y **dio**: aprobados por el usuario. Riverpod por los overrides en pruebas y por tener menos código repetitivo que Bloc.
- **very_good_analysis 11**: exige `const new(...)` (sintaxis de Dart 3.13). Se mantiene y `dart fix --apply` la corrige. **Revisar con el equipo:** los tutoriales usan la forma clásica.
- **Repositorio que no lanza** (devuelve `ApiStatus` sealed): la UI no necesita `try/catch` y nunca se rompe por la red.
- **`appConfigProvider` sin valor por defecto**: obliga a configurar en `main` (fail-fast) y en cada prueba.
- **`targetSdk` desde el plugin de Flutter** (no fijado a mano): hoy vale 36; se verifica en el APK con cada actualización de Flutter.
- **Firebase** (HU-31/02-01): `firebase_options.dart` y `google-services.json` ignorados desde ya; en CI se regeneran desde secretos en los jobs que compilan (política completa en la skill `critic-guardrails`). Pedido del usuario.
- **`build-apk` solo en push a `main`** con la condición exacta `github.event_name == 'push' && github.ref == 'refs/heads/main'` (pedido del usuario).
- Textos de la UI con acentos correctos (RNF-18); comentarios en ASCII por consistencia con los scripts.
- Se quitaron `cupertino_icons` (solo Android) y `flutter_lints` (reemplazado).

**Self-tests (los guardarraíles muerden)**
- critic con un scratch → `FAIL (7 bloqueantes, 1 aviso)`: B1, B2 (APP_USR-, `--dart-define …TOKEN`, `fromEnvironment('…KEY')`), B3, B4 (`catch (e) {}` y `catch (_)` sin uso); el `catch` de control que traduce el error **no** se marcó.
- Semgrep con un scratch → 5/5 reglas; sobre el repo, con `--config=auto`, 0.
- Hook `readonly-git-guard.ps1`: mismo archivo y mismos 12 casos que en el back.
- `flutter analyze` con un archivo de prueba: `todo: error` solo marca "TODO"; `flutter_style_todos` marca "Todo"/"todo" al inicio de un comentario.

**Errores a evitar**
- `sdkmanager.bat` (obsoleto) parte `platforms;android-36` en el `;` → "Package not found". Usar `android sdk install`. AGP tampoco pudo autoinstalar el NDK por la misma causa → instalarlo a mano.
- `flutter build … | tail` dio "exit 0" con FAILURE de Gradle: revisar el exit de Flutter o "√ Built".
- `flutter pub add --dev "integration_test:{sdk: flutter}"` falla en Git Bash: editar `pubspec.yaml`.
- En Riverpod 3, leer un provider `autoDispose` en `ProviderContainer.test` sin `listen` lo destruye entre lecturas.

**Confluence (15-Oct-2026)**
- Publicado con confirmación del usuario en el espacio `DDS` ("Desarrollo de software") de `uttt-startup-musubi.atlassian.net`: página padre "MUSUBI · Documentación técnica" (id 4947970) con las hijas "00 · Constitución y gobernanza SDD", "01 · Fundación musubi-api", "01 · Fundación musubi-app", "Catálogo de endpoints" y "Trazabilidad HU ↔ specs".
- Regla: las páginas resumen y **enlazan** al repo; nunca copian tablas vivas. Los enlaces a GitHub funcionan después del primer push. Al cerrar una fase o HU relevante, actualizar el resumen de la página correspondiente.

**Pendientes con dueño**
- `02-01`: navegación por módulos, componentes base, paleta y contraste (RNF-20), tamaños (RNF-27), Crashlytics (`NOTE (02-01)`), timeouts medidos, cobertura con umbral.
- `02-02`: firma de subida (`NOTE (02-02)`), ficha de Google Play, prueba cerrada (09-Nov-2026), despliegue desde GitHub y tag de versión (`docs/versionado.md`).
- `HU-02`: sesión, `flutter_secure_storage`, interceptor del token (`NOTE (HU-02)`). `HU-20`: SignalR. `HU-31`: FCM + secretos de Firebase en el CI.
- Equipo: roles PO/SM, revisores, umbrales "Por definir con el PO", protección de `main` en GitHub y la clave Jira de la tarea de plantilla (commit `SCRUM-XX`).
