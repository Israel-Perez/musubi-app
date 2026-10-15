# plan.md — 01-04 Configuración por ambiente

1. **Componentes:** `config/`, `lib/core/config/app_config.dart`, network security configs de Android, `.gitignore`.
2. **Decisiones:**
   - `--dart-define-from-file` en lugar de flavors de Gradle: un solo APK por ambiente sin duplicar la configuración nativa; suficiente para el MVP.
   - Validar en `main` (fail-fast): una URL insegura es un error de compilación, no del usuario.
   - La excepción de cleartext vive solo en los recursos de `debug`/`profile`, así release no la hereda.
3. **Guardarraíles:** critic B2/B3 + Semgrep (`musubi-secret-in-dart-define`, `musubi-android-cleartext-in-release`).
4. **Validación:** 7 pruebas de `AppConfig` + `aapt2` sobre el APK.
5. **Secuencia:** ejemplos → validación → network security config → pruebas.
