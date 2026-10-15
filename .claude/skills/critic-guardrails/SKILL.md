---
name: critic-guardrails
description: Dueña de scripts/critic-guardrails.ps1 de musubi-app — 4 bloqueantes (TODO, secretos en código/config/CI, http:// en lib/, catch que traga), la política de Firebase (firebase_options.dart y google-services.json) y el hardening de PowerShell 5.1. Úsala antes de cada push, al endurecer el script o al integrar Firebase (HU-31).
---

## Propósito
Un gate pre-push barato y determinista que corre igual en local y en el job `critic` del CI, enfocado en lo que más duele en una app móvil: **todo lo que va en el APK es público**.

## Cuándo usarla
Antes de cada push o PR; al modificar el script; al integrar Firebase u otro SDK con configuración de cliente.

## Precondiciones
PowerShell 5.1 (`powershell -File`) o 7 (`pwsh -File`); git en el PATH.

## Pasos
1. **Ámbito:** unión de `git diff origin/main...HEAD` + `git diff HEAD` + untracked (`git ls-files --others --exclude-standard`, que **omite lo ignorado**). Sin `origin/main`: todos los archivos versionados + untracked. El CI usa `fetch-depth: 0`.
2. **B1 TODO:** `TODO` en comentarios de `lib/`, `test/` e `integration_test/`. El analizador también lo marca (`todo: error`), y `flutter_style_todos` marca los comentarios que empiezan con "todo" en español.
3. **B2 secretos** (en `.dart`, `.yml`, `.json`, `.kts`, `.gradle`, `.properties`, `.xml`, `.ps1`, `.sh` y todo `.github/`):
   - llave privada PEM;
   - API key de Google (`AIza…`);
   - Mercado Pago (`APP_USR-…`, `TEST-<dígitos>-`);
   - IA (`sk-…`);
   - GitHub (`ghp_`, `github_pat_`), AWS (`AKIA…`) y Slack (`xox?-`);
   - `--dart-define` o `String.fromEnvironment` con nombres `*SECRET*|*KEY*|*TOKEN*`;
   - claves `"*SECRET*|*KEY*|*TOKEN*":` en `config/*.json`.
4. **B3 `http://` en `lib/`:** la URL de dev vive en `config/*.json`; fuera de dev, HTTPS (RNF-02).
5. **B4 `catch` que traga:** en `lib/`, un `catch` vacío, un `catch (_)` o un `catch (e)` que no usa `e` ni hace `throw`/`rethrow`; también `on X {}` vacío. El cuerpo se extrae contando llaves. El `catch` que **traduce** el error (`return ApiOffline(message: networkErrorMessage(error))`) es válido.
6. **Aviso A1:** `NOTE` sin ID (`NOTE (NN-NN)`, `NOTE (HU-NN)` o `NOTE (musubi-api:HU-NN)`).
7. **Self-test** al modificar el script: scratch con TODO + `http://` + `fromEnvironment('…KEY')` + `catch (e) {}` + `catch (_)` + un YAML con `APP_USR-` y `--dart-define=…TOKEN=`, **y un `catch` correcto como control** → `FAIL (7 bloqueantes, 1 aviso)` sin marcar el control (medido el 15-Oct-2026).

## Política de Firebase (HU-31 Messaging / 02-01 Crashlytics)

`flutterfire configure` genera `lib/firebase_options.dart` y `android/app/google-services.json`, que contienen API keys `AIza…`. Son **identificadores públicos del cliente**: Firebase no los trata como secretos, y la protección real está en las reglas del servidor. Aun así, B2 los detectaría, y su lugar no es Git. Política acordada:

1. **No se versionan.** Ya están en `.gitignore` desde la fundación (`/lib/firebase_options.dart`, `/android/app/google-services.json`, `/firebase.json`). Como el critic usa `--exclude-standard`, B2 no los ve en local.
2. **Si alguien los fuerza** con `git add -f`, B2 **sí** falla a propósito: eso es lo correcto (no hay waiver).
3. **En CI**, cada job que **compila Dart** (`analyze`, `test` y `build-apk`) los necesita, porque `main.dart` importará `firebase_options.dart`. Se guardan como secretos de GitHub en base64 (`FIREBASE_OPTIONS_DART_B64`, `GOOGLE_SERVICES_JSON_B64`; también como *Dependabot secrets* para que los PR de Dependabot compilen) y se regeneran después del checkout, sin imprimirlos (el lugar está marcado con `NOTE (HU-31)` en `build-apk`; el mismo paso se agrega en `analyze` y `test`):
   ```yaml
   - name: Restaurar configuracion de Firebase (no se imprime)
     shell: bash
     env:
       FIREBASE_OPTIONS_DART_B64: ${{ secrets.FIREBASE_OPTIONS_DART_B64 }}
       GOOGLE_SERVICES_JSON_B64: ${{ secrets.GOOGLE_SERVICES_JSON_B64 }}
     run: |
       echo "$FIREBASE_OPTIONS_DART_B64" | base64 -d > lib/firebase_options.dart
       echo "$GOOGLE_SERVICES_JSON_B64" | base64 -d > android/app/google-services.json
   ```
   Los archivos se crean en el workspace del runner, **después** del checkout. El job `critic` corre en otro runner sin esos secretos, así que nunca los ve.
4. **En las pruebas**, la inicialización de Firebase vive detrás de una interfaz (`FirebaseBootstrap`, en `lib/core/`) con un fake en `test/helpers/`: los widget tests no llaman al SDK real ni a la red.
5. **PR desde forks:** no reciben secretos, así que `analyze`/`test` fallarían. El equipo trabaja con ramas del mismo repo; si se aceptan forks, se agrega un `firebase_options.dart` *stub* (valores vacíos) generado solo cuando falte el secreto.
6. **Alternativa descartada:** versionar los dos archivos con una excepción por ruta en B2. Se descartó porque cada excepción debilita el guard y porque el *secret scanning* de GitHub alerta por las llaves de Google.
7. **Mitigaciones obligatorias al activar Firebase:** restringir la API key en Google Cloud (aplicación Android: paquete `com.musubi.app` + SHA-1 de las llaves de debug y de subida), habilitar App Check y escribir reglas de seguridad. Las credenciales de **Firebase Admin** (cuenta de servicio) viven **solo** en `musubi-api` (00-04 #11).
8. **Dev local:** cada dev corre `flutterfire configure` contra el proyecto de Firebase del equipo y **nunca** hace `git add -f`.

## Checklist
4 bloqueantes en verde · avisos revisados · Firebase según la política · `exit 0/1` correcto.

## Criterios de done
`pwsh scripts/critic-guardrails.ps1` → `critic: PASS` y exit 0 sobre el diff real del PR.

## Límites/trampas
- Los archivos que definen los guardarraíles (`scripts/critic-guardrails.ps1`, `.semgrep/semgrep.yaml`, `.claude/hooks/readonly-git-guard.ps1`) se excluyen porque contienen los patrones que buscan.
- Los checks de privacidad, plataforma y autorización (5–9 del agente `security-reviewer`) requieren criterio.
- No ampliar los bloqueantes sin self-test con un caso de control (00-04 #18).

## Referencias
`scripts/critic-guardrails.ps1`, `.gitignore`, `config/README.md`, `.github/workflows/ci-pr.yml`, `.claude/agents/security-reviewer.md`.
