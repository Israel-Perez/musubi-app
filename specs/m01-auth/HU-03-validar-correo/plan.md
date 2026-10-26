# plan.md — HU-03 Validar correo (app)

1. **Componentes:** `verification_screen.dart`, `welcome_screen.dart`, `clockProvider` y las rutas `/registro/verificacion` y `/bienvenida`.
2. **Decisiones:**
   - **El reloj es inyectable**, así que la cuenta regresiva se prueba sin esperar.
   - **Navegar antes de guardar la sesión** evita la redirección de la guardia de visitante.
3. **Guardarraíles:** la sesión solo se guarda con una respuesta válida; la prueba de código incorrecto confirma que se sigue como visitante.
4. **Validación:** pruebas de widget del flujo completo.
5. **Secuencia:** verificación → bienvenida → rutas → pruebas.
