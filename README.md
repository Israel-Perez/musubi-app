# musubi-app

App Android de **MUSUBI**, la plataforma de compra-venta entre estudiantes de la UTTT. Hecha con **Flutter** (Riverpod, go_router, dio), consume la API `musubi-api`.

Se desarrolla con **Spec Driven Development (SDD)** y DevSecOps: cada cambio nace de una spec en `specs/` (plantilla `specs/_template.md`) y se verifica con comandos y pruebas. Las reglas no negociables están en `.specify/memory/constitution.md`.

- Repo hermano (API .NET 10): <https://github.com/Israel-Perez/musubi-api>
- Contrato HTTP: [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (canónico; aquí se enlaza, no se copia)
- Backlog: Jira, proyecto `SCRUM` · Documentación funcional: Confluence
- **Maqueta** (la app debe ser igual, lineamiento 4): [`docs/maqueta/`](docs/maqueta/README.md) · Versiones: [`docs/versionado.md`](docs/versionado.md)
- Lineamientos de la materia (evaluación el 02-Dic-2026): [`musubi-api/docs/bitacora/lineamientos-materia.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/bitacora/lineamientos-materia.md)

## Estado (21-Oct-2026)

Plantilla inicial lista. Fases 00 (constitución) y 01 (fundación) implementadas en "🚧 Borrador con evidencia", en espera de designar revisores:

- `dart format` sin cambios · `flutter analyze --fatal-infos --fatal-warnings` sin observaciones · `flutter test` 144/144.
- HU-01/03/47: "Crea tu cuenta" con detección del campus, verificación con código de 6 dígitos, bienvenida y aviso de privacidad/términos (`assets/legal/`, fuente única para la app y la landing).
- HU-48 (fase 1): la app abre en la vitrina del campus sin cuenta; comprar, chatear, guardar, publicar, Mensajes y Perfil piden la cuenta con la hoja de la maqueta y regresan a donde estabas.
- Marca (02-03): logotipo de anillos, ícono de la app, splash nativo y splash animado.
- HU-02 + HU-56: "Hola de nuevo" (iniciar sesión), renovación de la sesión con el refresh token, "Cerrar sesión" con confirmación y recuperar la contraseña con un código de 6 dígitos.
- Base 02-01: tema de la maqueta (Plus Jakarta Sans, claro/oscuro, contraste AA), barra de 5 pestañas con guardia de sesión, tokens en almacenamiento seguro con renovación automática, errores por `code` y pruebas de seguridad de Android.
- Maqueta HTML versionada en `docs/maqueta/` con su índice de pantallas ↔ HU (SCRUM-66).
- APK de debug compilado: paquete `com.musubi.app`, `targetSdkVersion 36`.
- `critic-guardrails` PASS · Semgrep 0 hallazgos · actionlint sin hallazgos.
- Pantalla inicial "Musubi" que consulta `GET /api/v1/ping` y muestra el estado sin romperse si la API no responde.

## Requisitos

- Flutter **3.47.7** (stable; el CI usa la misma versión) — Dart 3.13.5
- JDK 17
- Android SDK: platform `android-36`, build-tools 36.1.0, NDK 28.2.13676358
- PowerShell 7 (`pwsh`) para el critic (también funciona en Windows PowerShell 5.1)

> **Windows:** el `sdkmanager.bat` de las cmdline-tools recientes está obsoleto y parte los argumentos en `;`. Instala los paquetes con el CLI nuevo:
> `android sdk install "platforms;android-36" "build-tools;36.1.0" "ndk;28.2.13676358"` (en `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin`).

## Puesta en marcha

```powershell
flutter pub get
Copy-Item config/dev.example.json config/dev.json        # ignorado por Git
flutter run --dart-define-from-file=config/dev.json      # emulador → musubi-api en http://10.0.2.2:5080
adb reverse tcp:5080 tcp:5080; flutter run --dart-define-from-file=config/usb.json   # celular por USB → http://localhost:5080
```

Para ver "Servidor conectado", levanta la API (`dotnet run --project Musubi.Api` en `musubi-api`). Sin la API, la app muestra "Sin conexión con el servidor" y el botón "Reintentar".

**Configuración:** solo valores públicos (URL base y banderas) en `config/<ambiente>.json` — ver [`config/README.md`](config/README.md). **Todo lo que va en el APK es público:** nunca llaves privadas; esas viven en `musubi-api`.

## Comandos de calidad (los mismos del CI)

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test                                   # flutter test --coverage para lcov
flutter build apk --debug --dart-define-from-file=config/dev.example.json
pwsh scripts/critic-guardrails.ps1
semgrep scan --config=auto --config=.semgrep/semgrep.yaml --error
```

## Estructura

```
lib/
├── main.dart                 valida la config y arranca ProviderScope
├── app/                      MusubiApp (tema, es-MX) y router (go_router)
├── core/                     config/, network/ (dio, api_paths), errors/, theme/
└── features/                 un módulo por carpeta (M-01…M-14) → domain/ data/ presentation/
    └── status/               ping a la API (patrón de referencia, spec 01-03)
test/                         unit + widget (helpers/ con fakes)
integration_test/             pruebas en un dispositivo
android/                      com.musubi.app · targetSdk 36 · network_security_config
config/                       *.example.json por ambiente
docs/                         trazabilidad, módulos, versionado.md, maqueta/
specs/ scripts/ .claude/ .github/ .semgrep/
```

La convención de módulos y capas está en [`lib/features/README.md`](lib/features/README.md); los 14 módulos, en [`docs/modulos.md`](docs/modulos.md).

## Flujo SDD

1. Al iniciar el sprint de una HU: `specs/mNN-<modulo>/HU-NN-<slug>/{spec,plan,task}.md`, con la **misma carpeta** que en `musubi-api` y el enlace en `Contraparte`.
2. Rama `feature/SCRUM-NN-slug`.
3. Esqueleto con el agente `slice-scaffolder` → implementación y pruebas (skills `vertical-slice` y `api-contract`).
4. Gate pre-push: `pwsh scripts/critic-guardrails.ps1` + agente `security-reviewer` (MASVS); trazabilidad con `traceability-clerk`.
5. PR con la clave Jira en el título (`SCRUM-19 HU-01 Crear cuenta: … (Tests N, analyze 0, critic PASS)`) que **enlaza el PR del back**.
6. Actualizar `docs/trazabilidad.md` y `Memoria.md`.

## CI

`.github/workflows/ci-pr.yml` corre en cada `pull_request` y `push` a `main`:

| Job | Qué hace |
|---|---|
| `analyze` | `dart format` (sin cambios) + `flutter analyze --fatal-infos --fatal-warnings` |
| `test` | `flutter test --coverage` + artefacto `coverage-lcov` |
| `critic` | `scripts/critic-guardrails.ps1` (4 bloqueantes) |
| `semgrep` | SAST (`--config=auto` + reglas propias) |
| `build-apk` | APK de debug con Java 17 — **solo en push a `main`** (ahorra minutos) |

Las actions están fijadas por SHA y Flutter está fijado (`FLUTTER_VERSION`). Dependabot (pub y github-actions, con `cooldown` de 7 días) las mantiene al día.

## Protección de rama recomendada (`main`)

En GitHub → Settings → Branches (o Rulesets) → regla para `main`:

- Requerir un pull request con **1 aprobación** (de un integrante distinto del autor).
- Requerir que pasen los checks: `analyze`, `test`, `critic` y `semgrep` (`build-apk` corre después del merge).
- Requerir que la rama esté actualizada y bloquear los force push.

> En GitHub gratuito, la protección de rama (y los rulesets) solo se aplica en **repos públicos**. Para un repo **privado** se necesita GitHub Pro (cuenta personal) o GitHub Team (organización).

## Créditos

Las prácticas de SDD, DevSecOps y guardarraíles se adaptaron del repositorio de referencia **WebAPIDevSecOpsScallingSDD**, compartido en la materia de Aplicaciones Móviles. Se copió la forma de trabajar, no el dominio ni el stack.
