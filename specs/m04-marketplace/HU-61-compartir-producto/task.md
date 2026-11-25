# HU-61 — Compartir un producto con un enlace (tareas)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (24-Nov-2026). Decisión para revisar: la vista previa de la landing es pública (los datos que ya da la API sin sesión).

## T2 — App
- **Qué:** "Compartir" (`ShareSheet`, `ProductShare`), la ruta `/p/:id`, "Regresar" a Inicio y el `intent-filter` de App Links.
- **Prueba:** `product_share_test.dart`, `product_screen_test.dart`, `android_config_test.dart` y `test/integration/marketplace_flow_test.dart`.
- **Estado:** ✅ Hecho.

## T3 — Landing (`musubi-landing`)
- **Qué:** el Worker de `/p/{id}` (vista previa con Open Graph, "Ya no está disponible" y "Abre Musubi para verlo") y `/.well-known/assetlinks.json`.
- **Prueba:**
  - `test/worker.test.mjs` (13);
  - `wrangler dev` con una API de prueba: `/p/{id}` lo atiende el Worker y lo demás son los archivos;
  - capturas en claro y oscuro.
- **Estado:** ✅ Hecho.

## T4 — Huella de Google Play
- **Qué:** agregar a `assetlinks.json` la huella SHA-256 de la llave con la que Google Play firma la app (Play Console → Integridad de la app → Firma de apps). Sin ella, App Links solo se verifica con la llave de subida, y en un teléfono el enlace abre la landing ("Abrir en Musubi" sí funciona).
- **Estado:** ✅ Hecho (25-Nov-2026, musubi-landing#5): `assetlinks.json` lleva la huella de subida y la de Google Play.

## T5 — Prueba en el celular
- **Qué:** con la app del siguiente lote de Google Play:
  - compartir por WhatsApp y ver la vista previa;
  - tocar el enlace con la app instalada;
  - tocarlo sin ella;
  - un producto pausado.
- **Estado:** ⏳ Por hacer.
