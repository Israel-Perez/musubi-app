# HU-16 — Responder "Yo tengo este producto" (app, plan)

## Decisiones
- **Una hoja con dos pestañas en lugar de dos pantallas:** la maqueta navega entre `Yo-tengo-vincular` y `Yo-tengo-oferta` sin cerrar la hoja; en la app es la misma hoja con el selector.
- **Abre en "Vincular publicación" si hay publicaciones disponibles:** como la maqueta. Sin ellas, la hoja no muestra pestañas (HU-16).
- **Al editar, la foto se conserva:** la respuesta trae la ruta `/media/...` y la app guarda la llave para volver a mandarla.
- **La foto se elige con la cámara o la galería del teléfono:** la maqueta simula una galería; en la app se usa el mismo selector de "Datos personales".
- **"Ir a mensajes" abre la bandeja:** la conversación de una oferta la abre quien busca (HU-17).

## Archivos
- **Nuevos:** `domain/offer_models.dart`, `presentation/offer_sheet.dart` y `test/features/purchase_requests/offer_test.dart`.
- **Cambian:**
  - `wanted_repository.dart`, `http_wanted_repository.dart`, `api_paths.dart` y `wanted_board_screen.dart`;
  - `css_dashes.dart` (`CssDashedBorderPainter`) y `sell_photos_screen.dart`;
  - `tool/screenshots_test.dart`, `test/helpers/fake_wanted.dart` y las notas de HU-17.

## Validación
- format, analyze, test y critic.
- Capturas contra la maqueta (Edge headless con `#sesion.Yo-tengo-vincular`, `…oferta` y `…enviada`).
- En el celular con la API `0.5.0-alpha.10`.
