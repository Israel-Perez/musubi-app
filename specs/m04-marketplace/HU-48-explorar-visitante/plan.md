# plan.md — HU-48 Explorar como visitante (app, fase 1)

1. **Componentes:** `features/marketplace/` (dominio, repositorio pendiente y vitrina), `account_gate.dart`, `return_path.dart`, `AppShell` y `MusubiBottomBar`.
2. **Decisiones:**
   - **Hoja y no pantalla:** igual que el prototipo, pedir la cuenta no saca de lo que se estaba viendo.
   - **Regreso recordado + `?desde=`:** iniciar sesión usa la guardia del router y el registro usa la bienvenida. Ambos aceptan solo rutas conocidas.
   - **`go` en lugar de `push` hacia registro e inicio de sesión:** con `push`, la guardia no veía la pantalla de visitante y el usuario se quedaba ahí después de entrar (encontrado con las pruebas).
   - **Repositorio pendiente que sí distingue el error de red:** la vitrina ya tiene sus estados reales antes del catálogo.
   - **Sin reintento automático:** la maqueta trae su propio "Reintentar".
3. **Guardarraíles:** pruebas con la app completa (router real) y dos self-tests; ninguna ruta externa en `?desde=`.
4. **Validación:** pruebas de widget y el APK en un dispositivo contra la API en AWS.
5. **Secuencia:** dominio → hoja → pestañas → vitrina → regreso → pruebas → dispositivo.
