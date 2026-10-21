# Constitución de MUSUBI — musubi-app

> Documento rector bajo Spec Driven Development (SDD). Define los principios, estándares y límites que deben respetar cada spec, cada implementación y cada agente.
> Ante un conflicto entre este documento y otro artefacto, **manda esta constitución**.
> Las secciones 1 a 5 son compartidas con `musubi-api`; las secciones 6 a 11 son propias de este repo.

<!-- Sección compartida con musubi-app/musubi-api: si cambia, cámbiala en ambos repos y regístralo en las dos Memoria.md -->
## 1. Propósito y alcance

- **Producto:** MUSUBI, app Android de compra-venta entre estudiantes de la UTTT (Universidad Tecnológica de Tula-Tepeji). Conecta la **oferta** (productos publicados) con la **demanda** (solicitudes "busco…"), con coincidencias automáticas, chat, pedidos pagados por transferencia a la cuenta del vendedor o en efectivo (sin comisión; Musubi no procesa el dinero), reputación, IA generativa para resumir acuerdos y recomendaciones con ML.
- **Repos hermanos:** `musubi-api` (back, ASP.NET Core / .NET 10) y `musubi-app` (front, Flutter). Cada uno es autosuficiente: constitución, plantilla, specs, `AGENTS.md`, `Memoria.md`, CI y guardarraíles propios.
- **Contrato entre repos:** el contrato HTTP es canónico en `musubi-api/docs/endpoints.md` (más el OpenAPI que la API expone en Development). El front **enlaza** sus filas y nunca lo duplica.
- **Metodología:** Spec Driven Development. Cada funcionalidad nace de una spec en `specs/`; esta constitución gobierna su forma, su implementación y su verificación.
- **Calendario del MVP:** sprints de 2 semanas desde el 28-Sep-2026. **Evaluación el 02-Dic-2026**: empieza descargando la app desde Google Play. Prueba cerrada en Google Play desde el 09-Nov-2026; la versión `1.0.0` se publica antes de la evaluación (matriz en `docs/versionado.md`).
- **Lineamientos de la materia:** son criterios de evaluación y mandan sobre este documento. Texto y checklist (L-NN) en `musubi-api/docs/bitacora/lineamientos-materia.md`. Si una sección de esta constitución o una spec los contradice, se corrige ese artefacto. La app se construye a la imagen de la maqueta (`musubi-app/docs/maqueta/`) y nunca se le quitan funciones.
- **Equipo:** Start-Up 10IDGS-G3 (4 integrantes; nombres y roles en Jira y Confluence, no en el repo público). Roles Scrum (PO/SM) por definir.

## 2. Principios no negociables

| # | Principio | Consecuencia práctica |
|---|---|---|
| 1 | **Seguridad primero** | Validar en la frontera, rechazar por defecto, mínimo privilegio y auth explícita en cada endpoint. Sin secretos en el código, en los logs ni en el APK. Referencias: OWASP API Security Top 10 – 2023 (back) y OWASP MASVS (front). |
| 2 | **Privacidad por diseño** (RNF-05 a RNF-08) | Datos mínimos y aviso de privacidad aceptado (HU-47). La conversación solo se envía a la IA si un participante lo pide, y con datos mínimos. Búsquedas e historial privados (solo uso agregado). Eliminación real de la cuenta y sus datos (HU-46). |
| 3 | **IA y ML desacoplados con degradación controlada** (RNF-15, RNF-23) | La IA generativa y las recomendaciones viven detrás de una interfaz con proveedor intercambiable. Si fallan, búsqueda, chat y pedidos siguen funcionando, y la UI muestra un estado claro en lugar de romperse. |
| 4 | **Multi-comunidad** (RNF-21) | Nada asume una sola universidad: la comunidad (UTTT) es un dato y no una constante en el código. Sumar otra universidad no requiere rediseño. |
| 5 | **Trabajo pesado en segundo plano** (RNF-11, RNF-12) | Coincidencias, notificaciones y llamadas a IA no bloquean la petición del usuario. La UI muestra un indicador mientras espera. |
| 6 | **Empírico antes que teórico** | Versiones, umbrales, timeouts y nombres se miden antes de fijarse (skill `empirical-verification`). Mientras un umbral no se mida, queda como "🎯 Objetivo (Por medir)" o "🎯 Objetivo (Por definir con el PO)". |
| 7 | **Documentar límites** | Los límites conocidos y el alcance diferido se registran con `NOTE (ID)` en 4 capas (código, `spec.md`, `task.md`, `Memoria.md`). Prohibido el workaround no documentado. |

## 3. Gobernanza SDD

- Cada spec sigue `specs/_template.md` (7 secciones + Aprobación y Control de Cambios). Cada criterio cita el comando o la prueba que lo verifica.
- Cada spec vive en su carpeta con `spec.md` (qué y por qué), `plan.md` (cómo) y `task.md` (pasos, pendientes y evidencia).
- **Estados:** "🚧 Borrador" (en redacción) → "🚧 Borrador con evidencia" (implementada y verificada) → "✅ Aprobado" **solo** si el usuario indica el revisor (1 integrante distinto del autor) y el PR está en verde. Sin revisor indicado, la spec queda en "Borrador con evidencia" aunque todo esté en verde.
- **Alcance diferido:** `NOTE (ID)` y nunca `TODO`. El ID es la spec dueña del reemplazo (`NOTE (02-01)`, `NOTE (HU-02)`).
- **Catálogos canónicos** en `docs/`: las specs los enlazan y nunca copian sus tablas. Los guardarraíles detectan el drift.
- Un cambio de principio o de stack exige actualizar esta constitución, el bloque de aprobación de la spec afectada y las dos `Memoria.md` cuando la sección es compartida.
- `AGENTS.md` describe **cómo** se trabaja; esta constitución describe **qué no se negocia**.

## 4. Convención de IDs

| Tipo | Formato | Ejemplo | Carpeta |
|---|---|---|---|
| Spec técnica | `NN-NN` (fase-número) | `01-03` | `specs/phase-NN-<nombre>/NN-NN-<slug>/` |
| Spec funcional (historia de usuario) | `HU-NN` | `HU-01` | `specs/mNN-<modulo>/HU-NN-<slug>/` (mismo ID y misma carpeta en los dos repos) |
| Módulo / épica | `M-NN` | `M-01` | Tabla canónica en `docs/modulos.md` |
| Requerimiento no funcional | `RNF-NN` | `RNF-02` | Spec `00-03` de cada repo |
| Spec del otro repo | `<repo>:<ID>` | `musubi-api:02-01` | — |

- Los `NOTE (…)` usan estos mismos IDs: `NOTE (02-01)`, `NOTE (HU-20)`, `NOTE (musubi-api:HU-02)`.
- Cada spec funcional declara en su encabezado `**HU / Jira / Sprint / Módulo / Contraparte:**` con el enlace a la spec del otro repo.

## 5. Jira, ramas y commits

- **Backlog:** Jira, proyecto `SCRUM` (fuente de verdad de HU, sprints y estados). **Documentación funcional:** Confluence. Los repos enlazan y no duplican.
- **Trazabilidad:** `docs/trazabilidad.md` en cada repo (HU ↔ Jira ↔ sprint ↔ módulo ↔ spec ↔ contraparte ↔ tests ↔ estado).
- **Ramas:** `feature/SCRUM-NN-slug` y `fix/SCRUM-NN-slug`, iguales en los dos repos. Un PR = una HU o un fix.
- **Commits y títulos de PR:** empiezan con la clave Jira, por ejemplo `SCRUM-19 HU-01 Crear cuenta: <resumen> (Unit N/Integration N/Security N, critic PASS)`.
- **HU que toca los dos repos:** un PR por repo con la misma clave; el PR del front enlaza al del back.
- **Protección de `main`:** 1 aprobación y los jobs del CI como checks obligatorios (ver el README de cada repo).
<!-- Fin de sección compartida -->

## 6. Stack de musubi-app

| Capa | Tecnología |
|---|---|
| Framework | Flutter (canal stable, fijado en el CI) + Dart; Android primero (`targetSdk` 36, `minSdk` 24) |
| Estado | Riverpod (`flutter_riverpod`, sin codegen) |
| Navegación | `go_router` |
| Cliente HTTP | `dio` (contra `musubi-api`, contrato en `musubi-api/docs/endpoints.md`) |
| Idioma | Español (`flutter_localizations`, `es-MX`) — RNF-18 |
| Almacenamiento seguro | `flutter_secure_storage` para el token — `NOTE (HU-02)` |
| Tiempo real | Cliente SignalR (chat y avisos dentro de la app) — `NOTE (HU-20)` |
| Notificaciones y monitoreo | Firebase Cloud Messaging — `NOTE (HU-31)` · Firebase Crashlytics — `NOTE (02-01)` |
| Configuración | `--dart-define-from-file=config/<ambiente>.json` (valores públicos: URL base y banderas) |
| Diseño visual | Maqueta de `docs/maqueta/` (lineamiento 4): Plus Jakarta Sans, rojo `#D7191F`, modo claro y oscuro; tokens en `lib/core/theme/` — `NOTE (02-01)` |
| Datos locales | Caché local de consultas; SQLite con sincronización solo si una HU lo requiere (lineamiento 16) — `NOTE (02-01)` |
| Pruebas | `flutter_test` (unit + widget), `integration_test` (esqueleto) |
| Calidad y seguridad | `very_good_analysis` + `strict-casts/inference/raw-types`, `flutter analyze --fatal-infos --fatal-warnings`, Semgrep, critic-guardrails; referencia OWASP MASVS |
| CI | GitHub Actions (actions fijadas por SHA) + Dependabot (pub, github-actions) |

Regla de excepción: ver `specs/phase-00-constitution/00-01-principles-stack/spec.md`. No se agrega ningún paquete sin evaluar su licencia, mantenimiento y seguridad.

## 7. Arquitectura

- **Feature-first**, organizada por los 14 módulos de `docs/modulos.md` (RNF-23):
  - `lib/app/`: raíz de la app (tema, rutas, idioma).
  - `lib/core/`: configuración, red, errores y tema.
  - `lib/features/<modulo>/`: capas `domain/` ← `data/` y `domain/` ← `presentation/`.
  - La convención está en `lib/features/README.md`.
- Los repositorios viven detrás de una interfaz de `domain/`, con un fake en las pruebas; la UI solo observa providers.
- El contrato con el back es la fila de `musubi-api/docs/endpoints.md`; las rutas se centralizan en `lib/core/network/api_paths.dart`.
- La UI nunca se rompe por la red: los errores se traducen a estados de dominio con mensajes en español (RNF-18) y opción de reintentar.
- IA y recomendaciones (M-10, M-11) se muestran como opcionales: si fallan, la pantalla degrada sin bloquear búsqueda, chat ni pedidos (RNF-15).

## 8. Estándares de código

- Código en inglés; textos de la UI, documentos y specs en español. JSON camelCase (lo define el back).
- `flutter analyze --fatal-infos --fatal-warnings` sin observaciones; `dart format` sin cambios. `todo: error` en el analizador.
- Sintaxis de Dart 3.13 que exige very_good_analysis 11: `const new(...)` en los constructores (`dart fix --apply` la corrige).
- Sin `print` (usar `debugPrint` o un logger); sin `http://` en `lib/`; sin `catch` vacío.

## 9. Testing y QA

- `test/` refleja `lib/`: pruebas unitarias (config, repositorios con un adaptador HTTP falso, providers) y widget tests por pantalla.
- `integration_test/`: flujos en un emulador o dispositivo (no corre en el CI de PR).
- RNF-25: pruebas automatizadas obligatorias en auth, coincidencias y pedidos.
- Cobertura con `flutter test --coverage` (artefacto del CI); umbral "🎯 Objetivo (Por medir)" en `00-03`.

## 10. CI/CD

- `.github/workflows/ci-pr.yml` en `pull_request` y `push` a `main`: `analyze`, `test`, `critic`, `semgrep` y `build-apk` (solo en push a `main`).
- Flutter fijado en el CI (`FLUTTER_VERSION`); actions fijadas por SHA; YAML validado con PyYAML y actionlint.

## 11. Seguridad (OWASP MASVS)

- **Todo lo que va dentro del APK es público:** ningún secreto en el código, en los assets, en `config/*.json` ni en `--dart-define`. Las llaves privadas (IA, Firebase Admin, cifrado de datos de pago) viven solo en `musubi-api`.
- MASVS-NETWORK: HTTPS fuera de dev; `network_security_config` de release sin tráfico en claro; en debug solo hacia `10.0.2.2`.
- MASVS-STORAGE: token en almacenamiento seguro (`NOTE (HU-02)`); `android:allowBackup="false"`.
- MASVS-CODE: dependencias revisadas (Dependabot con `cooldown`), análisis estático estricto.
- MASVS-PRIVACY: datos mínimos y aviso de privacidad (HU-47); eliminación de cuenta (HU-46).
