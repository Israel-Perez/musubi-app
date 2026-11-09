# HU-17 — Ver y elegir ofertas recibidas (app, plan)

## Decisiones
- **"Deshacer" sin endpoint propio:** la oferta se esconde al confirmar y la API se llama cuando termina el aviso de 4 s; "Deshacer" cancela el temporizador. Si se sale antes, el rechazo se envía al desmontar la sección.
- **"Recomendadas" en la app:** las aceptadas primero, luego las que caben en el presupuesto, mejor reputación y menor precio. Son pocas ofertas por solicitud (RN-14).
- **Etiquetas:** "Mejor reputación" va en la oferta con mejor promedio, si hay con quién comparar; "Menor precio", en la más barata; "Aceptada", en la elegida.
- **El saludo queda escrito, no enviado:** la persona lo manda o lo cambia; la maqueta lo deja listo.
- **Una oferta no tiene "Ver":** no siempre hay publicación (oferta directa).

## Archivos
- **Nuevos:** `presentation/received_offers.dart` y `test/features/purchase_requests/received_offers_test.dart`.
- **Cambian:**
  - `offer_models.dart`, `wanted_repository.dart`, `http_wanted_repository.dart`, `wanted_providers.dart`, `my_wanted_screen.dart` y `offer_sheet.dart`;
  - `chat_models.dart`, `http_chat_repository.dart`, `chat_screen.dart` y `router.dart`;
  - `api_paths.dart`, `tool/screenshots_test.dart` y `test/helpers/fake_wanted.dart`.
