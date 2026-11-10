# HU-13 — Publicar una necesidad de compra (app, plan)

## Decisiones
- **Reutilizar `SellStepLayout`:** los tres pasos tienen el encabezado, la barra de progreso y la barra inferior de Vender. Se agregan parámetros con los valores de Vender por defecto, sin duplicar la pantalla.
- **Borrador en memoria (`needDraftProvider`):** sobrevive al ir y venir entre pasos y se limpia al publicar. El MVP no tiene modo sin conexión (HU-53, 08-Nov-2026); guardarlo en el teléfono queda fuera del MVP.
- **Coincidencias con la búsqueda de HU-09:** no hay endpoint de coincidencias todavía (HU-18). La misma consulta alimenta el aviso del paso 1 y la lista de la pantalla publicada.
- **"Elegir fecha" con las fechas de la maqueta:** una hoja `MusubiOptions` en lugar del calendario de Material, que no es parte del sistema visual.
- **`<legend>` de la maqueta:** el navegador pega "Categoría" y "¿Para cuándo la necesitas?" al bloque de arriba y deja el relleno debajo; la app lo replica.
- **Mis solicitudes en la rama de Perfil:** la maqueta la muestra con la barra de pestañas.

## Archivos
- **Nuevos:**
  - `lib/features/purchase_requests/{domain,data,presentation}/…`;
  - `test/features/purchase_requests/*` y `test/helpers/fake_wanted.dart`.
- **Cambian:**
  - `sell_layout.dart`, `api_paths.dart`, `musubi_icons.dart` (`target`) y `home_feed.dart` (`longDate`);
  - `router.dart` y `profile_screen.dart` ("Mis solicitudes" y Privacidad en un renglón aparte);
  - `tool/screenshots_test.dart`.
