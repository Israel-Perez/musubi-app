# 01-04 — Configuración por ambiente

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) · contraparte: `musubi-api:01-04`

## Contexto
Configuración de compilación por ambiente con `--dart-define-from-file`, sabiendo que todo valor queda dentro del APK. **Depende de**: `01-01`.

## Requisitos
1. Configuración por archivo: `config/<ambiente>.json`; se versionan solo los `*.example.json` y los reales se ignoran.
2. Solo valores públicos: URL base de la API y banderas. Ninguna llave privada.
3. Validación al arrancar (`AppConfig.parse`): ambiente conocido, URL absoluta, HTTPS fuera de dev, y HTTP en dev solo hacia hosts locales.
4. La red de Android coincide: release sin tráfico en claro; debug/profile permiten HTTP solo hacia `10.0.2.2` (emulador) y `localhost` (celular por USB con `adb reverse`, desde el 25-Oct-2026).

## Diseño

| Clave (`--dart-define`) | Ejemplo dev | Estado / Fase | Descripción |
|---|---|---|---|
| `ENV` | `dev` | [01-04 / Implementado] | `dev` \| `staging` \| `prod` |
| `API_BASE_URL` | `http://10.0.2.2:5080` | [01-04 / Implementado] | URL base de musubi-api (10.0.2.2 = PC vista desde el emulador; puerto del perfil `http` de la API) |
| Firebase (opciones del cliente) | — | [HU-31 / Pendiente] | Generadas por `flutterfire configure` en `lib/firebase_options.dart` (ignorado; ver la skill `critic-guardrails`) |
| `SIGNALR_HUB_PATH` (tentativa) | — | [HU-20 / Pendiente] | Ruta del hub (fila del catálogo del back) |

Archivos:

- `config/{dev,staging,prod}.example.json` (versionados) + `config/README.md`.
- `lib/core/config/app_config.dart`: `AppConfig.parse`, `AppConfig.fromEnvironment`, `appConfigProvider`.
- `android/app/src/main/res/xml/network_security_config.xml` (release: sin tráfico en claro) y las versiones `debug`/`profile` (excepción para `10.0.2.2` y `localhost`).

## Contratos
Claves de la tabla. Una clave nueva: fila aquí + ejemplo en `config/*.example.json` + validación en `AppConfig.parse`.

## Tests
- `test/core/config/app_config_test.dart` (7): dev HTTP hacia 10.0.2.2; prod HTTPS con la barra final normalizada; staging HTTP rechazado (RNF-02); dev HTTP hacia un host externo rechazado; URL vacía o relativa rechazada; ambiente desconocido rechazado; esquema distinto de http/https rechazado.

## Criterios
- `flutter test test/core/config/app_config_test.dart` → 7/7.
- `git status --ignored config` → `config/dev.json` ignorado (`!!`).
- `pwsh scripts/critic-guardrails.ps1` → PASS (B2: sin claves `*SECRET*|*KEY*|*TOKEN*` en `config/` ni en `--dart-define`; B3: sin `http://` en `lib/`).

## Límites
Las URLs de staging y prod son placeholders hasta el despliegue (`musubi-api:02-05`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 15-Oct-2026
- **Detalle:** Tabla inicial con 2 claves implementadas y 2 pendientes.
