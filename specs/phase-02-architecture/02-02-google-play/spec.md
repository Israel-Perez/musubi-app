# 02-02 — Publicación en Google Play

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) / SCRUM-86 / S3–S5 / — / [musubi-api:02-05](https://github.com/Israel-Perez/musubi-api/tree/main/specs/phase-02-architecture/02-05-aws-deploy) (la API y el dominio en producción)

## Contexto
La evaluación del 02-Dic-2026 empieza descargando la app desde Google Play (L-01) y pide desplegar desde GitHub (L-16a).

La cuenta de desarrollador es **personal** (un equipo estudiantil no tiene D-U-N-S) y se registró con `desarrollo@musubiapp.com.mx`. Por ser personal y nueva, Google exige una **prueba cerrada con al menos 12 testers durante 14 días seguidos** antes de dar acceso a producción.

**Depende de:**
- `02-01`, `02-03` (marca e ícono);
- `musubi-api:02-05` (API en `https://api.musubiapp.com.mx`);
- el sitio `musubi-landing` (`/privacidad` y `/eliminar-cuenta`);
- `HU-46` (eliminar la cuenta desde la app, requisito de Google).

## Requisitos
1. **Firma:**
   - llave de subida (`.jks`) fuera del repo, referida desde `android/key.properties` (ignorado);
   - Play App Signing activado (Google guarda la llave de la app);
   - respaldo de la llave y su contraseña fuera del equipo de desarrollo.
2. **Build de release:**
   - AAB firmado con `--dart-define-from-file=config/prod.json`;
   - R8 activado;
   - `targetSdk` 36;
   - `versionName`/`versionCode` según `docs/versionado.md` (la primera subida es `0.3.0+3`).
3. **Ficha de la tienda (es-MX):**
   - nombre "Musubi", descripción corta (≤ 80) y larga (≤ 4000);
   - categoría Compras;
   - ícono de 512 px, gráfico de 1024 × 500 y de 4 a 8 capturas reales;
   - correo `contacto@musubiapp.com.mx` y sitio `https://musubiapp.com.mx`.
4. **Contenido de la app:**
   - política de privacidad: `https://musubiapp.com.mx/privacidad`;
   - eliminación de cuenta: `https://musubiapp.com.mx/eliminar-cuenta`, más la opción dentro de la app (HU-46);
   - Seguridad de los datos (lo que la versión subida recopila de verdad);
   - sin anuncios;
   - clasificación de contenido (IARC);
   - público objetivo.
5. **Acceso para los revisores:** una cuenta de prueba con usuario y contraseña, porque el registro solo acepta correos institucionales.
6. **Pistas:** prueba interna → prueba cerrada (lista de testers por correo y enlace de inscripción) → solicitud de producción al cumplir 12 testers × 14 días → producción antes del 02-Dic-2026.
7. **Despliegue desde GitHub (L-16a):** un workflow que compila el AAB y lo sube a la pista elegida con la API de Google Play. Usa una cuenta de servicio cuya llave vive en los secretos de GitHub, nunca en el repo.

## Diseño
- **Firma:** `android/app/build.gradle.kts` ya lee `key.properties` (01-01). Sin ese archivo, release se firma con la llave de debug, solo para pruebas locales.
- **Workflow `release-play.yml`:**
  - manual, con la pista como entrada;
  - pasos: build del AAB con los secretos de firma decodificados en el runner, subida con la API de Google Play, y etiqueta `app-vX.Y.Z`;
  - permisos mínimos.
- **Ficha y gráficos:** en `docs/play/`, con los textos, el gráfico y las capturas generadas con `tool/screenshots_test.dart`.
- **Pendientes:**
  - `NOTE (HU-46)`: eliminar la cuenta desde la app antes de la primera revisión;
  - `NOTE (02-02)`: cuenta de revisión (decisión pendiente: permitir `@musubiapp.com.mx` en el campus).

## Contratos
- `android/key.properties` (ignorado): `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
- Secretos de GitHub: `PLAY_UPLOAD_KEYSTORE_B64`, `PLAY_UPLOAD_KEYSTORE_PASSWORD`, `PLAY_UPLOAD_KEY_ALIAS`, `PLAY_UPLOAD_KEY_PASSWORD` y `PLAY_SERVICE_ACCOUNT_JSON`.
- Sin cambios en la API.

## Tests
- `test/versioning_test.dart`: la versión del `pubspec.yaml` coincide con `docs/versionado.md`.
- `test/security/android_config_test.dart`: release sin tráfico en claro, `allowBackup=false` y solo los permisos aprobados.
- `aapt2 dump badging` del AAB: paquete `com.musubi.app`, `targetSdkVersion:'36'` y la versión esperada.
- `actionlint` del workflow; la primera corrida del workflow sube a la prueba interna.

## Criterios
- [ ] El AAB de release está firmado con la llave de subida y Play Console lo acepta en la prueba interna.
- [ ] La ficha, la clasificación, Seguridad de los datos, el público, los anuncios y el acceso para revisores están completos (sin avisos en Play Console).
- [ ] La prueba cerrada tiene 12 o más testers inscritos durante 14 días seguidos.
- [ ] La app está publicada en producción y se descarga desde Google Play antes del 02-Dic-2026.
- [ ] `release-play.yml` sube una versión desde GitHub (L-16a).

## Límites
- **Cuenta personal:** el nombre legal del titular lo verifica Google; en la ficha se muestra "Musubi" como desarrollador.
- **Decisiones pendientes:**
  - cuenta para los revisores;
  - público objetivo (propuesta: 18 años o más).
- **Fuera de alcance:** iOS / App Store.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** cuenta personal por no tener D-U-N-S; requisito de 12 testers × 14 días (support.google.com/googleplay/android-developer/answer/14151465).
