# 01-01 — Setup y toolchain

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) · contraparte: `musubi-api:01-01`

## Contexto
Crea el proyecto Flutter de MUSUBI para Android con el applicationId definitivo y la cadena de compilación verificada. **Depende de**: `00-01`, `00-02`.

## Requisitos
1. Proyecto `musubi_app` creado con `flutter create --platforms android` en el canal stable.
2. applicationId y namespace **definitivos**: `com.musubi.app`, confirmados por el equipo antes de crear el proyecto (no se pueden cambiar después de publicar en Google Play).
3. `targetSdk` 36 (requisito de Google Play para apps nuevas desde el 31-Ago-2026), `minSdk` 24 y Java 17.
4. Release sin firma de debug cuando exista `android/key.properties` (ignorado).
5. `flutter build apk --debug` compila.

## Diseño
- Toolchain medido (15-Oct-2026): Flutter 3.47.7 (stable), Dart 3.13.5, JDK 17.0.20 (Microsoft OpenJDK), Android SDK con platform `android-36`, build-tools 36.1.0 y NDK 28.2.13676358, AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0.
- `flutter create --org com.musubi --project-name musubi_app`; después `applicationId`/`namespace` = `com.musubi.app` y `MainActivity` movida a `android/app/src/main/kotlin/com/musubi/app/`.
- `targetSdk = flutter.targetSdkVersion`: el plugin de Flutter 3.47.7 lo fija en 36 (`FlutterExtension.kt`); verificado en el APK.
- Firma: `android/app/build.gradle.kts` lee `android/key.properties` si existe; si no, release usa la llave de debug (solo local). `NOTE (02-02)`: firma de subida para Google Play.
- Manifiesto principal: permiso `INTERNET`, etiqueta "Musubi", `allowBackup=false` (MASVS-STORAGE), `networkSecurityConfig` (01-04).

## Contratos
- applicationId `com.musubi.app` (inmutable después de publicar).
- `pubspec.yaml`: `environment.sdk ^3.13.5`, `flutter >=3.47.7`; versión `0.1.0+1`.

## Tests
- Verificación del artefacto: `aapt2 dump badging build/app/outputs/flutter-apk/app-debug.apk`.

## Criterios
- `flutter build apk --debug --dart-define-from-file=config/dev.example.json` → `√ Built build\app\outputs\flutter-apk\app-debug.apk`.
- `aapt2 dump badging …` → `package: name='com.musubi.app'` y `targetSdkVersion:'36'` (medido el 15-Oct-2026).
- `aapt2 dump xmltree --file AndroidManifest.xml …` → `allowBackup=false` y `networkSecurityConfig` presentes.

## Límites
No incluye la firma de subida ni la ficha de Google Play (`02-02`). Solo Android (RNF-26).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 15-Oct-2026
- **Detalle:** applicationId `com.musubi.app` confirmado por el usuario dos veces (en el plan y antes de `flutter create`).
