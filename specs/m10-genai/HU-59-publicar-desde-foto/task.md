# HU-59 — Publicar un producto a partir de una foto (tareas)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (25-Nov-2026). Decisiones para revisar: el aviso de privacidad sin cambiar de versión y "Fotos" como compartido en Play.

## T2 — Repositorio y borrador
- **Qué:** `draftFromPhoto` y `fillFromCover`.
- **Prueba:** `http_listings_repository_test.dart` y `sell_draft_test.dart`.
- **Estado:** ✅ Hecho.

## T3 — Pantalla
- **Qué:** la tarjeta "Llenar con IA" en `Vender-1`, el aviso de la primera vez y abrir `Vender-2`.
- **Prueba:** `sell_flow_test.dart` (grupo "Llenar con IA (HU-59)") y `test/integration/sell_flow_test.dart`.
- **Estado:** ✅ Hecho.

## T4 — Privacidad y Play
- **Qué:** el aviso de privacidad (HU-47) y "Seguridad de los datos" (`docs/play/README.md`).
- **Prueba:** `legal_documents_test.dart`.
- **Estado:** ✅ Hecho. Después de fusionar, volver a desplegar la landing para que `/aviso-de-privacidad` muestre el texto nuevo.

## T5 — Prueba en el celular
- **Qué:** con la app del siguiente lote y la API `0.5.0-alpha.46` con Gemini: fotos de una calculadora, una bata y un libro; el aviso de la primera vez; sin red.
- **Estado:** ⏳ Por hacer (siguiente lote de Google Play; antes, actualizar el formulario de Play).
