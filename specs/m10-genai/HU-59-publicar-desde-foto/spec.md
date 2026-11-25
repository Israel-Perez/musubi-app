# HU-59 — Publicar un producto a partir de una foto (IA generativa)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-59 / SCRUM-99 / Sprint 5 (14 nov – 1 dic 2026) / M-10 / [musubi-api:HU-59](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m10-genai/HU-59-publicar-desde-foto)

## Contexto
Jira (SCRUM-99): Como **vendedor**, quiero **que la app proponga el nombre, la categoría, el estado y la descripción a partir de la foto de mi producto**, para **publicar más rápido**.

- Pantallas: `Vender-1` (la tarjeta "Llenar con IA") y `Vender-2…4` (se revisa). La maqueta no la tiene: se agrega sin quitar nada (lineamiento 4), con la misma tarjeta de "Nombre y descripción con IA" de HU-37.
- Trazabilidad: lineamiento **L-16i** (IA generativa). Relacionada con HU-06 (publicar), HU-37 y HU-47 (aviso de privacidad).
- **Decisiones (25-Nov-2026, para que la usuaria las revise):**
  - El aviso de privacidad suma "Llenar con IA" (y las ideas de HU-37, que no estaban) **sin cambiar de versión** (`2026-10`), así no pide aceptarlo otra vez. El aviso de la app sale antes de enviar la foto.
  - En "Seguridad de los datos" de Play, "Fotos" pasa a **Compartido** con el siguiente lote.

**Depende de:** `HU-06` (`Vender-1…4` y la subida de fotos), `HU-32` (aviso de la IA), musubi-api HU-59 (`POST /products/photo-draft`).

## Requisitos
1. **R1 · La tarjeta:** con al menos una foto, `Vender-1` muestra "Llenar con IA": qué hace y que tú revisas todo. Sin fotos no aparece. Al editar una publicación (HU-07) no aparece, porque `Vender-1` no se usa ahí.
2. **R2 · El aviso (RNF-06):** la primera vez en el dispositivo explica que la IA de Google verá la foto de portada, sin tu nombre ni tus datos. Con "Cancelar" no se envía nada.
3. **R3 · La propuesta:**
   - Espera a que la portada se suba; si falló, la reintenta. Una portada rechazada por la moderación no se envía.
   - Pone en el borrador el nombre, la descripción, el estado y la categoría; si la IA no reconoció ninguna, deja la que había.
   - Avisa "Listo. Revisa lo que propuso la IA" y abre `Vender-2`.
4. **R4 · Se revisa (RN-38):** nada se publica solo: los pasos 2 a 4 muestran lo propuesto y quien vende lo cambia y pone el precio.
5. **R5 · Sin IA (RNF-15):** con `listings.draft_unavailable` (o sin red), avisa con el mensaje de la API y se queda en `Vender-1`; "Continuar" sigue a mano.
6. **R6 · Aviso de privacidad y Play (HU-47):**
   - `assets/legal/aviso-de-privacidad.md` dice qué se envía con "Llenar con IA" y con "Ideas para vender más rápido".
   - `docs/play/README.md` anota "Fotos" como compartido para el siguiente lote.

## Diseño
- `ListingsRepository.draftFromPhoto` (`HttpListingsRepository`, `ApiPaths.photoDraft`) → `PhotoDraftProposal`.
- `SellDraftNotifier.fillFromCover`.
- `SellPhotosScreen._fillWithAi` y `_AiFillCard`.
- `photoAiNoticeStoreProvider` (`SecureAiNoticeStore` con la entrada `photoKey`).

## Contratos
Fila `POST /api/v1/products/photo-draft` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) y sus errores `listings.photo_not_found` y `listings.draft_unavailable`.

## Tests
- `test/features/listings/sell_flow_test.dart` (grupo "Llenar con IA (HU-59)"):
  - sin foto no aparece; con la portada llena el borrador, se corrige y se publica;
  - el aviso sale una vez y "Cancelar" no envía;
  - sin IA lo dice y se sigue a mano;
  - una portada que no subió se reintenta.
- `test/features/listings/sell_draft_test.dart`: usa la portada; sin categoría deja la que había; sin fotos o con la portada rechazada no pide; sin IA el borrador no cambia.
- `test/features/listings/http_listings_repository_test.dart`: la ruta, la llave, la propuesta, un nuevo sin detalle y el 503.
- `test/features/auth/legal_documents_test.dart`: el aviso menciona "Llenar con IA" y la foto de portada.
- `test/integration/sell_flow_test.dart`: contra la API real, la propuesta de la portada, publicar con ella y que la foto de otra persona da `listings.photo_not_found`.

## Criterios
- [x] Después de subir la primera foto, "Llenar con IA" propone el nombre, la categoría, el estado y la descripción → `sin foto no aparece; con la portada llena el borrador y se revisa antes de publicar`, `Llenar con IA (HU-59): la portada propone el borrador; solo la mia`.
- [x] La propuesta queda como borrador editable (RN-38) → el mismo flujo: el nombre se corrige y se publica después.
- [x] La foto ya pasó la moderación y el texto también se modera → `sin fotos, o con la portada rechazada, no pide nada` y musubi-api HU-59.
- [x] Sin IA, la publicación sigue a mano (RNF-15) → `sin IA lo dice y se sigue a mano (RNF-15)`, `sin IA el borrador no cambia (RNF-15)`.
- [x] El aviso de privacidad y "Seguridad de los datos" se actualizan → `aviso: IA solo a petición (RN-40) y revisión de reportes (RN-22)` y `docs/play/README.md`.
- [ ] Prueba en el celular con Gemini real (T5).

## Límites
- Solo se envía la portada.
- El precio no lo propone la IA: lo sugiere HU-58 en `Vender-3`.
- La landing muestra el aviso nuevo cuando se vuelve a desplegar después de fusionar.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 25-Nov-2026 (detallada e implementada)
