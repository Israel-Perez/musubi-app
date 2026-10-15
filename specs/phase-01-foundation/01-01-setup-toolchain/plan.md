# plan.md — 01-01 Setup y toolchain

1. **Componentes:** `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `MainActivity.kt`.
2. **Decisiones:**
   - Instalar solo las cmdline-tools del SDK (sin Android Studio): es automatizable y suficiente para `flutter build apk`; el emulador se agrega después.
   - `targetSdk` desde el plugin de Flutter en vez de fijar 36 a mano: hoy vale 36 y sube con Flutter; se verifica en el APK en cada actualización.
   - Se quitan `cupertino_icons` (solo Android/Material) y `flutter_lints` (reemplazado por very_good_analysis).
3. **Guardarraíles:** confirmar el applicationId antes de crear el proyecto; `key.properties` y keystores ignorados.
4. **Validación:** build de debug + `aapt2 dump`.
5. **Secuencia:** toolchain → confirmar el applicationId → create → ajustar gradle/manifest → build → aapt2.
