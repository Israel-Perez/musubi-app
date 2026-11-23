# musubi-app

App Android de **MUSUBI**, la plataforma de compra-venta entre estudiantes de la UTTT. Está hecha con **Flutter** (Riverpod, go_router, dio), consume la API [`musubi-api`](https://github.com/Israel-Perez/musubi-api) y se publica en **Google Play** (prueba cerrada).

Se desarrolla con **Spec Driven Development (SDD)** y DevSecOps. Cada cambio nace de una spec en `specs/` (plantilla `specs/_template.md`) y se verifica con pruebas y guardarraíles en el CI. Las reglas no negociables están en `.specify/memory/constitution.md`.

| Qué | Dónde |
|---|---|
| API en producción | <https://api.musubiapp.com.mx> |
| Contrato HTTP (canónico; aquí se enlaza, no se copia) | [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) |
| Maqueta (la app es igual, 60 pantallas) | [`docs/maqueta/`](docs/maqueta/README.md) |
| Historias de usuario ↔ specs ↔ pruebas | [`docs/trazabilidad.md`](docs/trazabilidad.md) |
| Versiones y Google Play | [`docs/versionado.md`](docs/versionado.md), [`docs/play/`](docs/play/README.md) |
| Backlog | Jira (proyecto `SCRUM`) y Confluence |

## Qué hace

Cada módulo vive en `lib/features/<modulo>/` con sus capas `domain/`, `data/` y `presentation/`:

| Módulo | Pantallas |
|---|---|
| `auth` | Crear cuenta con correo institucional y código, iniciar sesión, recuperar contraseña, eliminar la cuenta |
| `marketplace` | Inicio (recomendados, populares, recientes), buscar y filtrar, producto, favoritos, búsquedas guardadas, comparar y "Avísame" |
| `listings` | Vender con fotos en 4 pasos, Mis productos (editar, pausar, piezas, vendido) |
| `purchase_requests` | "Se busca": publicar una necesidad, ofertas, coincidencias |
| `chat` | Mensajes en tiempo real (SignalR sobre WebSocket) |
| `genai` | Acuerdo de entrega con IA (Gemini) |
| `orders` | Pedido, pago en efectivo o por transferencia, entrega ("Agregar al calendario" y "Ya llegué"), apartar 24 h con QR, cuenta para recibir pagos |
| `reputation` | Calificar, reportar y bloquear |
| `notifications` | Avisos y push (Firebase Cloud Messaging) |
| `recommendations` | "Recomendado para ti" y "Ver parecidos" (ML en la API) |
| `seller_support` | "Llevan tiempo sin venderse", quiénes la buscan, ideas con IA |
| `profile` | Perfil, privacidad, intereses, tema, insignias de confianza |
| `admin` | Moderación de reportes y cuentas, categorías (solo el rol `admin`) |
| `status` | Estado de la API (`GET /api/v1/ping`) |

**Lo que hace la app con los datos:**

- **Sesión:** se guarda en el almacén seguro (Keystore) y sigue viva al cerrar y volver a abrir la app. El logout revoca la sesión en la API (`POST /auth/logout`).
- **Moderación:** las fotos y los textos inapropiados se rechazan en la API (AWS Rekognition y Comprehend) y la app muestra el motivo.
- **Permisos (en contexto):**
  - `CAMERA`: leer el QR de un apartado (ML Kit);
  - `POST_NOTIFICATIONS`: avisos push;
  - `INTERNET`.
- Las fotos usan el selector del sistema, sin permiso de almacenamiento.

## Seguridad (OWASP MASVS)

- **Almacenamiento:**
  - los tokens van solo en el almacén seguro, y una prueba exige que solo los archivos de sesión los toquen;
  - `allowBackup=false`;
  - nada sensible en el APK: las llaves privadas viven solo en la API.
- **Red:**
  - HTTPS fuera de dev (se valida al arrancar);
  - release sin tráfico en claro;
  - el token solo viaja al esquema, host y puerto de la API.
- **Sesión:** refresh automático y una sola renovación ante varios 401. Si la API da la sesión por terminada (logout, suspensión), la app la cierra.
- **Código:** análisis estricto (very_good_analysis), Semgrep, critic y Dependabot.

## Pruebas

| Suite | Pruebas | Cómo se corre |
|---|---|---|
| Unitarias y de widget (`test/`) | 838 | `flutter test` |
| Seguridad (`test/security/` + `test/integration/security_flow_test.dart`) | 14 + 4 | Las primeras con `flutter test`; las 4 de flujos, con el script de integración |
| Integración contra la API real (`test/integration/`) | 54 | `pwsh scripts/run_integration_tests.ps1` (levanta `../musubi-api`) |
| **En un teléfono físico** (`integration_test/`) | 8 | `pwsh scripts/run_device_tests.ps1` (teléfono por USB; guía en [`integration_test/README.md`](integration_test/README.md)) |

- **Integración:** la suite llama a cada uno de los 122 endpoints que la app consume. Lo exige `tool/check_integration_coverage.dart` en el CI, así que una llamada nueva sin prueba no entra.
- **Teléfono físico:** la suite corrió el 19-Nov-2026 en un Galaxy A54, 8/8. Recorre crear cuenta, sesión persistente, cerrar sesión, eliminar cuenta, buscar y chatear, apartar, publicar con foto y moderación.

## CI y CD

| Job (`ci-pr.yml`, en cada PR y push a `main`) | Qué hace |
|---|---|
| `analyze` | `dart format` sin cambios y `flutter analyze --fatal-infos --fatal-warnings` |
| `test` | `flutter test --coverage` (artefacto lcov) |
| `integration` | Levanta musubi-api (la rama del mismo nombre, o `main`) y corre `test/integration` con el guard de cobertura |
| `critic` | Sin secretos, sin `http://` en `lib/`, sin `TODO`, sin `catch` que trague errores |
| `gitleaks` | Secretos en el historial completo de Git (gitleaks 8.30.1, binario verificado) |
| `semgrep` | SAST (`--config=auto` + reglas propias) |
| `build-apk` | APK de debug (solo en push a `main`) |

**Publicación (`release-play`, manual):**

1. Valida que la versión no exista.
2. Corre las pruebas.
3. Compila el AAB de producción y lo firma con la llave de subida (secreto de GitHub).
4. Lo sube a la pista elegida de Google Play.
5. Etiqueta `app-vX.Y.Z+N` y borra la llave.

Las actions están fijadas por SHA y Flutter está fijado (`FLUTTER_VERSION`).

## Puesta en marcha

Requisitos: Flutter **3.47.7** (stable), JDK 17 y Android SDK (`android-36`, build-tools 36.1.0, NDK 28.2.13676358).

```powershell
flutter pub get
Copy-Item config/dev.example.json config/dev.json        # ignorado por Git
flutter run --dart-define-from-file=config/dev.json      # emulador → musubi-api en http://10.0.2.2:5080
adb reverse tcp:5080 tcp:5080; flutter run --dart-define-from-file=config/usb.json   # teléfono por USB
```

**Configuración:** en `config/<ambiente>.json` van solo valores públicos (URL base y banderas); ver [`config/README.md`](config/README.md). Todo lo que va en el APK es público.

**Comandos de calidad (los mismos del CI):**

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
pwsh scripts/run_integration_tests.ps1
pwsh scripts/critic-guardrails.ps1
semgrep scan --config=auto --config=.semgrep/semgrep.yaml --error
```

## Estructura

```
lib/               main.dart, app/ (router, tema), core/ (config, red, sesión, widgets), features/ (14 módulos)
test/              unitarias y de widget, helpers/ (fakes), security/, integration/ (contra la API)
integration_test/  suite en un teléfono físico (app_test.dart, flows/)
android/           com.musubi.app · targetSdk 36 · network_security_config
config/            *.example.json por ambiente
docs/              trazabilidad, módulos, versionado, maqueta/, play/, mcp.md
specs/             SDD: fases 00–02 y mNN-<modulo>/HU-NN-*/
scripts/ tool/     critic, secciones compartidas, integración, teléfono, guard de cobertura
.claude/ .opencode/  agentes de IA (3) y skills (9)
```

## IA en el desarrollo

- **Agentes:** 3 sub-agentes en `.claude/agents/`:
  - `slice-scaffolder`;
  - `security-reviewer` (MASVS, solo lectura);
  - `traceability-clerk` (solo lectura).
- **Skills:** 9 en `.claude/skills/`.
- **MCP:** Atlassian y AWS ([`docs/mcp.md`](docs/mcp.md)).
- **Memoria:** el aprendizaje del desarrollo queda en [`Memoria.md`](Memoria.md); las reglas permanentes, en `AGENTS.md`.

## Flujo SDD y ramas

¿Eres nuevo en el equipo? Lee [`docs/guia-equipo.md`](docs/guia-equipo.md).

1. Escribe la spec de la HU, en la misma carpeta que en `musubi-api`.
2. Crea la rama `feature/SCRUM-NN-slug`.
3. Implementa con sus pruebas.
4. Pásala por `security-reviewer`.
5. Abre el PR con la clave Jira; debe enlazar el PR del back.

`main` está protegida (ruleset "Main Proteccion", spec [`02-05`](specs/phase-02-architecture/02-05-ci-cd/spec.md)): no acepta force push, pide un PR con 1 aprobación y los checks obligatorios en verde (`analyze`, `test`, `critic`, `semgrep` y `gitleaks`).

## Créditos

Las prácticas de SDD, DevSecOps y guardarraíles se adaptaron del repositorio de referencia **WebAPIDevSecOpsScallingSDD**, compartido en la materia de Aplicaciones Móviles. Se copió la forma de trabajar, no el dominio ni el stack.
