# plan.md — HU-61 Compartir un producto con un enlace

## 1. Componentes
- App:
  - `ShareSheet` (canal `musubi/share`) y `ProductShare`;
  - `ProductScreen` (`_share`, `_back`);
  - la ruta `/p/:id`;
  - `intent-filter` y `MainActivity.kt`.
- Landing:
  - `worker/` (solo `/p/*`);
  - `build.mjs` (la plantilla);
  - `.well-known/assetlinks.json`, `styles.css` y `wrangler.jsonc`.

## 2. Decisiones (con su porqué)
- **Canal nativo y no `share_plus`:** es un `Intent.ACTION_SEND` de cinco líneas, como el calendario de HU-62. Sin paquete nuevo, así no hay excepción de 00-01.
- **Vista previa en un Worker de Cloudflare:**
  - WhatsApp necesita las etiquetas Open Graph en el HTML; un sitio estático no puede ponerlas por producto.
  - El Worker solo atiende `/p/*` y arma el HTML en el servidor: el navegador sigue sin JavaScript y con la misma CSP.
  - Cuesta cero: es el plan gratis de Workers y Cloudflare guarda la respuesta 5 minutos.
- **La vista previa es pública:** son los mismos datos que la API ya da sin sesión (HU-48), sin quien vende. Todo lo demás (comprar, el chat, quien vende) exige la cuenta del campus.
- **"Abrir en Musubi" con `intent://`:** si App Links no se verifica (por ejemplo, el enlace se abre dentro del navegador de WhatsApp), Android igual abre la app, o Google Play si no está instalada.
- **Solo `https://musubiapp.com.mx/p/`:** un esquema propio (`musubi://`) lo podría registrar cualquier app. Con App Links verificados, solo la nuestra lo abre.

## 3. Excepciones al stack
Ninguna. La landing suma su único código de servidor, `worker/`, dentro del mismo Worker de Cloudflare que ya la sirve.

## 4. Guardarraíles
- MASVS-PLATFORM: un solo `intent-filter` de enlaces, verificado y acotado (`android_config_test.dart`).
- RNF-05: ni el texto ni la landing llevan datos de quien vende.
- La landing escapa todo lo que viene de la API, valida el id (24 hex) y la ruta de la foto, y aplica los encabezados de `_headers`.

## 5. Validación
`flutter analyze`, `flutter test`, `run_integration_tests.ps1`; en la landing, `node build.mjs`, `node --test` y `wrangler dev`; prueba en el celular (T5).

## 6. Secuencia
T1 → T2 → T3 → T4 → T5.
