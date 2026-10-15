# 01-01 — Setup y toolchain (tareas)

## T1 — Toolchain
- **Instalar:** Flutter (`git clone -b stable` en `C:\src\flutter`), OpenJDK 17 (winget), Android cmdline-tools + `android sdk install "platforms;android-36" "build-tools;36.1.0" "ndk;28.2.13676358"`.
- **Verificar:** `flutter doctor -v` → Android toolchain ✓, licencias aceptadas.
- **Estado:** ✅ Hecho (15-Oct-2026).

## T2 — Proyecto y applicationId
- **Crear:** proyecto con `flutter create`; `com.musubi.app` en gradle y `MainActivity`.
- **Verificar:** `flutter build apk --debug --dart-define-from-file=config/dev.example.json` → Built; `aapt2 dump badging` → `com.musubi.app`, `targetSdkVersion:'36'`.
- **Estado:** ✅ Hecho (15-Oct-2026).

## Pendientes
- `NOTE (02-02)`: firma de subida (`key.properties`), ficha de Google Play y prueba cerrada (09-Nov-2026).
