# plan.md — HU-56 Recuperar mi contraseña (app)

1. **Componentes:** `forgot_password_screen.dart`, `AuthRepository.requestPasswordReset` / `resetPassword`, `PasswordRuleList` y `PasswordChanged`.
2. **Decisiones:**
   - **Dos pasos en una sola pantalla:** el correo y la cuenta regresiva viven en un solo estado; "Cambiar correo" no navega.
   - **Texto condicional en el paso 2** ("Si {correo} tiene cuenta…"): la API no revela si existe y la app tampoco.
   - **Volver a "Iniciar sesión"** con el correo escrito: la API cerró todas las sesiones y hay que entrar de nuevo.
3. **Guardarraíles:** la contraseña nueva cumple la misma política que el back; ningún dato se guarda en el dispositivo.
4. **Validación:** pruebas con la app completa y el fake del repositorio (código `482173`).
5. **Secuencia:** repositorio → pantalla → ruta → pruebas.
