# plan.md — HU-02 Iniciar y cerrar sesión (app)

1. **Componentes:** `core/session/session_api.dart`, `SessionController.logOut`, `SessionTokens.fromApi`, `AuthRepository.signIn`, `sign_in_screen.dart`, `sign_out_button.dart` y `features/profile/presentation/profile_screen.dart`.
2. **Decisiones:**
   - **La guardia navega después del login**: la pantalla solo guarda la sesión y el router lleva a `?desde=`, sin duplicar la lógica de regreso.
   - **Al cerrar sesión, primero a Inicio y después el logout**: Inicio no pide sesión, así la guardia no manda a "Iniciar sesión".
   - **El refresh solo termina la sesión con 400/401**: perder la red no debe sacar al estudiante (L-16g).
   - **`SessionApi` en `core/`**: el interceptor de `core/` no depende de `features/`.
3. **Guardarraíles:** la renovación y el logout usan el cliente sin sesión (sin deadlock en el `QueuedInterceptor`); los tokens solo se guardan en el almacén seguro.
4. **Validación:** pruebas con la app completa (router real con su guardia) + `FakeHttpAdapter` + `FakeSessionApi`.
5. **Secuencia:** API de sesión → repositorio → pantallas → router → pruebas → self-tests.
