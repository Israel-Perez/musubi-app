# 02-05 — CI/CD de musubi-app

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) / SCRUM-90 / S4 / — / [musubi-api:02-08](https://github.com/Israel-Perez/musubi-api/tree/main/specs/phase-02-architecture/02-08-ci-cd)

## Contexto
El documento de la materia pide CI/CD para el móvil (requisito 8) y sugiere desplegar desde GitHub a Google Play (requisito 16). Las piezas estaban repartidas:
- el CI viene de `01-05`;
- la publicación, de `02-02` (T4).

Esta spec las junta y agrega la protección de `main`.

**Depende de:** `01-05` (CI), `02-02` (Google Play) y `docs/versionado.md`.

## Requisitos
1. **CI en cada PR y en cada push a `main`** (`ci-pr.yml`):
   - `dart format` y `flutter analyze --fatal-infos --fatal-warnings`;
   - `flutter test`, con cobertura como artefacto;
   - critic y Semgrep;
   - APK de debug después de fusionar.
2. **CD manual a Google Play** (`release-play.yml`, `workflow_dispatch`), solo desde `main` y en el entorno `google-play`. La pista se elige al lanzarlo: interna, cerrada (`alpha`) o producción.
   1. Revisa que la etiqueta de la versión no exista.
   2. Corre las pruebas.
   3. Compila el AAB firmado con la llave de subida.
   4. Lo sube con la API de Google Play.
   5. Crea la etiqueta `app-vX.Y.Z+N`.
3. **Secretos fuera del repo:** la llave de subida y la cuenta de servicio viven en el entorno `google-play`. La llave se borra del runner al terminar.
4. **Protección de `main`:** ruleset "Main Proteccion", igual al de la API (`musubi-api:02-08`), con los checks `analyze`, `test`, `critic` y `semgrep`.

## Diseño
- **`.github/workflows/ci-pr.yml`:** jobs `analyze`, `test`, `critic` y `semgrep` en paralelo; `build-apk` solo en push a `main`.
- **`.github/workflows/release-play.yml`:**
  - Flutter fijado (`FLUTTER_VERSION`) y actions fijadas por SHA;
  - las notas salen de `docs/play/whatsnew/`;
  - la etiqueta se crea con la identidad `github-actions[bot]`.
- **Guía:** [`docs/play/README.md`](../../../docs/play/README.md) (cuenta de servicio, secretos y pasos para publicar).

## Contratos
- **Checks obligatorios:** `analyze`, `test`, `critic` y `semgrep`.
- **Entorno `google-play`:** `PLAY_UPLOAD_KEYSTORE_B64`, `PLAY_UPLOAD_KEYSTORE_PASSWORD`, `PLAY_UPLOAD_KEY_ALIAS`, `PLAY_UPLOAD_KEY_PASSWORD` y `PLAY_SERVICE_ACCOUNT_JSON`.
- **Etiquetas:** `app-vX.Y.Z+N` (`docs/versionado.md`).

## Tests
- `actionlint` de los dos workflows antes de cambiarlos.
- `test/versioning_test.dart`: la versión de `pubspec.yaml` coincide con la matriz y con "Musubi X.Y.Z" de `Ajustes`.
- Evidencia de corrida:
  - `release-play` 41590675848: `0.3.0+4` a la prueba cerrada;
  - `release-play` 41695899512 (03-Nov-2026): `0.4.0+5`, con la etiqueta creada por el workflow.

## Criterios
- Un PR a `main` no se fusiona con un check en rojo: `gh api repos/Israel-Perez/musubi-app/rulesets` muestra "Main Proteccion" activo.
- `release-play` en `main` publica en la pista elegida y crea `app-v<versión>`.
- Falla si la etiqueta ya existe (versionCode repetido).

## Límites
- **Aprobación del administrador:** mientras no haya un revisor fijo, el administrador puede fusionar su propio PR. El CI sigue siendo obligatorio.
- **Fuera de alcance:** pruebas en dispositivo (`integration_test/`) dentro del CI, porque necesitan un emulador.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 03-Nov-2026
- **Detalle:** junta `01-05` (CI) y `02-02` T4 (CD), y agrega el ruleset (auditoría de requisitos, SCRUM-90).
