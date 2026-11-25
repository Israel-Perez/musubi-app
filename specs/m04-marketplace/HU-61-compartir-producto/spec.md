# HU-61 — Compartir un producto con un enlace

**HU / Jira / Sprint / Módulo / Contraparte:** HU-61 / SCRUM-101 / Sprint 5 (14 nov – 1 dic 2026) / M-04 / sin cambios en musubi-api. La vista previa vive en [`musubi-landing`](https://github.com/Israel-Perez/musubi-landing) (`worker/`).

## Contexto
Jira (SCRUM-101): Como **usuario**, quiero **compartir un producto por WhatsApp u otra app con un enlace**, para **que mis compañeros lo vean y lo compren**.

- Pantalla: `Producto`. El botón de compartir ya estaba en la maqueta (arriba de la foto, junto al corazón) y hasta ahora decía "llega muy pronto".
- Trazabilidad: lineamiento **L-17** (landing con enlace a la tienda). Relacionada con HU-11 (detalle) y HU-48 (visitante).
- **Decisión (24-Nov-2026, para que la usuaria la revise):** la vista previa de la landing **es pública**.
  - Muestra foto, nombre, precio, estado y categoría.
  - Es exactamente lo que la API ya da sin sesión (`GET /api/v1/products/{id}`, HU-48), sin quien vende (RNF-05).
  - Para comprar o escribir hay que entrar a la app con el correo institucional del campus.

**Depende de:** `HU-11` (detalle), `HU-48` (detalle público) y la landing (`musubi-landing`, SCRUM-84).

## Requisitos
1. **R1 · Compartir:**
   - "Compartir" en `Producto` abre la hoja del sistema (`Intent.ACTION_SEND`, canal `musubi/share`, sin paquete ni permisos).
   - Lleva el texto "{nombre} · {precio} en Musubi" y el enlace `https://musubiapp.com.mx/p/{id}`.
   - Funciona con sesión y sin ella, también en una agotada.
   - Nunca lleva datos de quien vende.
2. **R2 · Solo lo que está a la venta:** una publicación mía pausada o vendida (que solo yo veo) no se comparte y la app lo dice. Sin una app que lo reciba, también lo dice.
3. **R3 · Con la app instalada:**
   - El enlace abre el producto en la app (App Links: `intent-filter` con `autoVerify` solo para `https://musubiapp.com.mx/p/`, y `/.well-known/assetlinks.json` en la landing).
   - El router lleva `/p/{id}` a `/producto/{id}`, y "Regresar" va a Inicio porque no hay pantalla anterior.
4. **R4 · Sin la app (landing):**
   - `/p/{id}` muestra la vista previa con etiquetas Open Graph (foto, nombre y precio) para WhatsApp.
   - Tiene el botón de Google Play y, en Android, "Abrir en Musubi" (`intent://` que cae en Google Play).
   - La página lleva `noindex`.
5. **R5 · Ya no está:** un producto vendido, pausado o eliminado (404 de la API) muestra "Ya no está disponible", sin sus datos. Si la API no responde, muestra "Abre Musubi para verlo".
6. **R6 · Privacidad (RNF-05, MASVS-PLATFORM):**
   - La landing solo lee el detalle público y escapa todo lo que viene de la API.
   - Usa la misma CSP del sitio, sin JavaScript en el navegador.
   - El `intent-filter` acepta solo `https`, ese host y esa ruta.

## Diseño
- App:
  - `lib/core/platform/share_sheet.dart` (`ShareSheet`, `shareSheetProvider`);
  - `lib/features/marketplace/domain/product_share.dart` (`ProductShare.link`, `of` y `canShare`);
  - `ProductScreen._share` y `_back`;
  - la ruta `'/p/:id'` en `router.dart`;
  - `MainActivity.kt` (`musubi/share`) y el `intent-filter` de `AndroidManifest.xml`.
- Landing (`musubi-landing`):
  - `worker/index.js` (solo `/p/*`, `run_worker_first`) y `worker/product-page.js`;
  - la plantilla que genera `build.mjs` con el mismo encabezado y pie;
  - `src/static/.well-known/assetlinks.json`.

## Contratos
Fila `GET /api/v1/products/{id}` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (sin sesión). No hay endpoints nuevos.

## Tests
- `test/features/marketplace/product_share_test.dart`: el enlace, el texto sin quien vende y qué se puede compartir.
- `test/features/marketplace/product_screen_test.dart` (grupo "Compartir (HU-61)"):
  - la hoja con el texto;
  - un visitante y una agotada;
  - mi pausada;
  - sin app;
  - el enlace `/p/{id}` y "Regresar".
- `test/security/android_config_test.dart`: un solo `intent-filter` de enlaces, verificado, solo `https://musubiapp.com.mx/p/`.
- `test/integration/marketplace_flow_test.dart`: contra la API real, el enlace con el id real, lo que ve un visitante (la vista previa) y el 404 de una pausada.
- `musubi-landing/test/worker.test.mjs` (13 pruebas `node:test`):
  - la vista previa con Open Graph;
  - agotado;
  - "Ya no está disponible";
  - la API caída;
  - ids inválidos sin llamar a la API;
  - escape del texto;
  - los encabezados de `_headers`;
  - `assetlinks.json`.

## Criterios
- [x] "Compartir" abre la hoja del sistema con el nombre, el precio y el enlace → `abre la hoja del sistema con nombre, precio y enlace`, `nombre, precio y enlace; nunca quien vende (RNF-05)`.
- [ ] Con la app instalada, el enlace abre el producto (App Links verificados) → `el enlace /p/{id} abre el detalle; "Regresar" va a Inicio` y `App Links (HU-61)`. Falta la huella de la llave de firma de Google Play en `assetlinks.json` y la prueba en el celular (T5).
- [x] Sin la app, la landing muestra la vista previa con Open Graph y el botón de Google Play → `un producto disponible: nombre, precio, foto y Open Graph…` y la prueba con `wrangler dev` (T3).
- [x] Vendido, pausado o eliminado: "Ya no está disponible" → `vendido, pausado o eliminado (404 de la API)…`, `compartir (HU-61): el enlace lleva lo que ve un visitante`.
- [x] Sin datos de quien vende → `nombre, precio y enlace; nunca quien vende`, `seller: null` en el Worker.

## Límites
- La vista previa la arma WhatsApp con la foto WebP de la API; una app que no lea WebP muestra solo el texto.
- `www.musubiapp.com.mx` no abre la app: el enlace que se comparte es siempre sin `www`.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 24-Nov-2026 (detallada e implementada)
