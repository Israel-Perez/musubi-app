# HU-16 — Responder "Yo tengo este producto" (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-16 / SCRUM-38 / Sprint 4 (9 – 20 nov 2026) / M-05 / [musubi-api:HU-16](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-16-yo-tengo-este-producto)

## Contexto
Jira (SCRUM-38): Como **usuario**, quiero **responder a una solicitud con "Yo tengo este producto", ya sea vinculando una publicación o describiendo un producto que todavía no publico**, para **ofrecerlo directamente al comprador**.

- Maqueta: `Yo-tengo-vincular`, `Yo-tengo-oferta` y `Yo-tengo-enviada`, desde los boletos de `Se-busca` (HU-15).
- Trazabilidad: RF-20, RF-40 · CU-11 · Flujo B · RN-06, RN-13, RN-14.

**Depende de:** `02-04` (piezas de la maqueta), `HU-06` (mis publicaciones y la subida de fotos) y `HU-15`.

## Requisitos
1. **R1 · Hoja "Yo tengo este producto":** empieza a 90 de arriba con la solicitud ("Fernanda busca", "Hasta $300", la fecha).
2. **R2 · Vincular publicación:** mis publicaciones disponibles (no las pausadas ni agotadas) como opciones con foto, precio y estado; la primera ya elegida; "Mensaje para Fernanda · Opcional".
3. **R3 · Oferta directa:** "Descripción", "Precio" con `$`, "Estado" Nuevo/Usado y "Foto · opcional" (cámara o galería); avisa "Está dentro de su presupuesto ($300)" o "Está arriba de su presupuesto ($300)" al escribir el precio.
4. **R4 · Sin publicaciones:** no hay pestañas; solo la oferta directa.
5. **R5 · Lo que falta:** sin descripción o sin precio, el campo se marca y se sacude; no se envía.
6. **R6 · Editar (RN-14):** si ya ofrecí, la hoja abre con mi oferta y el botón dice "Actualizar oferta"; la foto que ya tenía se conserva.
7. **R7 · `Yo-tengo-enviada`:** "¡Oferta enviada!", lo que ofrecí ("Vinculada a tu publicación" u "Oferta directa") con su precio, "Ir a mensajes" y "Seguir viendo solicitudes". El tablero vuelve a pedirse y suma la oferta.
8. **R8 · Errores:** un rechazo de la API (moderación, solicitud que ya no está) se muestra en español y la hoja sigue abierta.

## Diseño
- `lib/features/purchase_requests/`:
  - `domain/offer_models.dart` (`WantedOffer`, `NewOffer`);
  - `WantedRepository.myOffer` y `sendOffer` (`HttpWantedRepository`);
  - `presentation/offer_sheet.dart` (`showOfferSheet` y `showOfferSentSheet`).
- Reutiliza `listingsRepositoryProvider` (`mine()` y `uploadPhoto`) y `photoPickerProvider` de HU-06.
- `CssDashedBorderPainter` pasa a `lib/core/widgets/css_dashes.dart` (antes era privado de `Vender-1`).

## Contratos
Filas `GET` y `PUT /api/v1/wanted/{requestId}/offers/mine` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), enlazadas desde `ApiPaths.myOffer`.

## Tests
- `test/features/purchase_requests/offer_test.dart`: R2–R8 con el router real.
- `test/features/purchase_requests/wanted_data_test.dart`: `myOffer` (`offers.not_found` → `null`), `sendOffer` (PUT y la llave de la foto) y `NewOffer`.
- `test/features/purchase_requests/wanted_board_test.dart`: el boleto abre la hoja.
- `tool/screenshots_test.dart`: `yo-tengo-vincular`, `yo-tengo-oferta` y `yo-tengo-enviada`.

## Criterios
- [x] Desde una solicitud **Activa** se elige "Yo tengo este producto" (R1).
- [x] Se puede vincular una publicación o crear una oferta directa (descripción, precio, estado y foto opcional) sin publicarla (R2, R3).
- [x] Sin publicaciones, solo la oferta directa (R4).
- [x] Una oferta por solicitud, editable (R6); en las propias no aparece el botón (el tablero no las muestra, HU-15).
- [x] Si el precio supera el presupuesto, se advierte y se permite (R3).
- [ ] El comprador recibe una notificación (RF-40): `NOTE (HU-30)`.
- [x] Capturas iguales a la maqueta (hoja a 90 pt y título a 130 pt; "¡Oferta enviada!" a 383 pt contra 382).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 405/405 · critic PASS.

## Límites
- `NOTE (HU-18)`: "Coincide" en la publicación que encaja con lo que se busca.
- `NOTE (HU-30)`: "Le avisamos a Fernanda" queda como en la maqueta; el aviso llega con las notificaciones. Mientras, quien busca ve "N ofertas" en "Mis solicitudes".
- `NOTE (HU-17)`: "Ir a mensajes" abre la bandeja; la conversación nace cuando quien busca abre el chat desde la oferta.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador) · 09-Nov-2026 (implementación)
- **Detalle:** la oferta directa usa la subida de fotos de los productos; sin conversación al enviar (HU-17).
