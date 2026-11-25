# HU-65 — Enviar fotos y ver "escribiendo…" y "leído" en el chat (tareas, app)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (24-Nov-2026).

## T2 — Datos y tiempo real
- **Qué:** la foto en el repositorio, `counterpartReadAt` y el hub (`typing`, `conversationRead`, `Typing`).
- **Prueba:** `test/features/chat/chat_data_test.dart`.
- **Estado:** ✅ Hecho.

## T3 — Pantalla
- **Qué:** el "+" con cámara y galería, la burbuja de la foto, "Escribiendo…", "Leído" y las respuestas rápidas.
- **Prueba:** `test/features/chat/chat_flow_test.dart` y `test/integration/chat_flow_test.dart`.
- **Estado:** ✅ Hecho.

## T4 — Prueba en el celular
- **Qué:** con la API `0.5.0-alpha.45` y dos teléfonos: foto de la cámara y de la galería, "Escribiendo…", "Leído" y las respuestas rápidas.
- **Estado:** ⏳ Por hacer (siguiente lote de Google Play).
