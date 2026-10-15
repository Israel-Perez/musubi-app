# plan.md — 01-03 Cliente de API y ping

1. **Componentes:** `lib/core/network/`, `lib/core/errors/`, `lib/features/status/`, `test/helpers/`.
2. **Decisiones:**
   - El repositorio devuelve un estado de dominio (`ApiStatus`) en vez de lanzar: la UI no necesita `try/catch` y nunca se rompe por la red.
   - Adaptador HTTP falso de Dio en lugar de un paquete de mocks: prueba la serialización real de Dio sin red y sin dependencias extra.
   - `sealed class` + `switch` exhaustivo en la UI: un estado nuevo obliga a manejarlo (error de compilación).
3. **Guardarraíles:** la ruta viene de `ApiPaths` (enlazada al catálogo del back); sin `http://` en `lib/`; mensajes sin detalle técnico.
4. **Validación:** 11 pruebas (repositorio, providers, widget).
5. **Secuencia:** dominio → cliente y errores → repositorio → providers → pantalla → pruebas.
