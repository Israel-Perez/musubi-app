# HU-06 — Publicar un producto (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-06 / SCRUM-23 / S2 / M-03 (más HU-50 y la fase 2 de HU-48) / [musubi-api:HU-06](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-06-publicar-producto)

## Contexto
Maqueta: `Publicar`, `Vender-1`, `Vender-2`, `Vender-3`, `Vender-4`, `Vender-listo` y `Mis-productos`. Quien tiene sesión publica un producto desde el botón central de la barra. La publicación aparece en Inicio para todo el campus, también para visitantes (fase 2 de HU-48).

**Depende de:** `02-01`, `02-04` (piezas de la maqueta) y el back de HU-06 (filas "M-03" de `musubi-api/docs/endpoints.md`).

## Requisitos
1. **"Publicar"** (con sesión) abre "¿Qué quieres publicar?" detrás de la barra, que cambia su botón por "Cerrar" (la X entra girando).
   - "Vender un producto" abre el flujo;
   - "Publicar lo que necesito" queda "Muy pronto" (HU-13).
   - El visitante sigue viendo "Crea tu cuenta" (HU-48).
2. **`Vender-1` — fotos:**
   - cámara o galería, hasta 8, y la primera es la portada;
   - quitar con "Deshacer" y reordenar manteniendo presionado;
   - cada foto se sube en cuanto se agrega; si falla, se reintenta con un toque y también al publicar;
   - sin fotos: sacude y avisa "Agrega al menos una foto para continuar".
3. **`Vender-2` — detalles:** nombre (con la palomita al tener 3 letras) y descripción con el contador "N / 500". Sin nombre avisa "Escribe el nombre del producto".
4. **`Vender-3` — precio y categoría:**
   - precio en pesos (hasta 6 dígitos) y las 6 categorías con su ícono;
   - el rango "Productos parecidos se venden entre…" solo aparece con datos reales (HU-06 del back);
   - avisos: "Ponle un precio a tu producto" y "Elige una categoría".
5. **`Vender-4` — estado y cantidad:**
   - Nuevo o Usado, y "¿Cómo está?" solo si es usado;
   - piezas de 1 a 10 (HU-50) y la vista previa ("Usado · Como nuevo · 1 disponible");
   - "Publicar producto" → "Publicando…".
6. **`Vender-listo`:** el producto con "Publicado ahora", "Ver mis productos" y "Volver al inicio". Inicio se recarga con lo nuevo.
7. **"Guardar":** conserva el borrador; "Vender un producto" lo retoma.
8. **Inicio usa la vitrina real** (`GET /api/v1/products`) salvo con `DEMO_CATALOG`. "Populares" se oculta mientras no haya vistas (HU-11/49), por decisión del usuario.
9. **`Mis-productos`:** pestañas Activos, Vendidos y Agotados, y "Tu inventario".

## Diseño
- **`lib/features/listings/`:**
  - `domain/` (`NewListing`, `ProductCondition`, `UsedDetail`, `PriceRange`, `OwnListing` y `ListingsRepository`);
  - `data/` (`HttpListingsRepository` y `PhotoPicker` con `image_picker`);
  - `presentation/` (`SellDraftNotifier`, `PublishOverlay`, las pantallas `sell_*` y `MyProductsScreen`).
- **`lib/features/marketplace/data/`:**
  - `HttpCatalogRepository` reemplaza a `PendingCatalogRepository`;
  - `product_json.dart` traduce `ProductResponse` y arma la URL de las fotos con `API_BASE_URL`, porque CloudFront sirve `/media/*` en el mismo dominio.
- **Rutas** (todas con sesión): `/vender`, `/vender/detalles`, `/vender/precio`, `/vender/estado`, `/vender/listo`, `/mis-productos` y `/necesito`.
- **Íconos nuevos de la maqueta** en `musubi_icons.dart`: etiqueta, imagen, foco, calculadora, regla, chip, personas, tendencia y menos.
- **Pendientes:**
  - `NOTE (HU-13)`: "Publicar lo que necesito";
  - `NOTE (HU-18)`: "N estudiantes buscan algo similar";
  - `NOTE (HU-08)`: "Vendidos" y "Llevan tiempo sin venderse";
  - `NOTE (HU-50)`: cambiar piezas desde la lista;
  - `NOTE (HU-49)`: "Populares".

## Contratos
Filas "M-03" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md):
- `GET /api/v1/categories`;
- `GET /api/v1/products`;
- `GET /api/v1/products/mine`;
- `GET /api/v1/products/price-range`;
- `POST /api/v1/products`;
- `POST /api/v1/products/photos`.

## Tests
- `test/features/listings/sell_flow_test.dart` (7):
  - la hoja y "Cerrar";
  - el flujo completo con cada aviso y lo publicado;
  - "Ver mis productos";
  - quitar y "Deshacer";
  - sin cámara y reintento de subida;
  - "Guardar";
  - el rango de precios.
- `test/features/listings/http_listings_repository_test.dart` (6): multipart, contrato de publicar, estados de "mis productos", 204 del rango, percentiles y errores.
- `test/features/listings/sell_draft_test.dart` (4): tope de 8, reordenar, piezas y etiqueta, y "Guardar".
- `test/features/marketplace/http_catalog_repository_test.dart` (3): mapeo, filtro en la consulta y errores.
- `test/features/marketplace/home_screen_test.dart` (+2): sin vistas no hay "Populares"; la vitrina vacía lo explica.

## Criterios
- `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 217/217 · critic PASS.
- Capturas lado a lado con la maqueta (`tool/screenshots_test.dart`: `publicar`, `vender-1…4`, `vender-listo`).
- Probado en el Galaxy A54 contra la API en AWS después del despliegue.

## Límites
- **Fotos:** se reducen en el teléfono (1600 px, JPEG 85) y la API las vuelve a procesar. Si Android cierra la app mientras la cámara está abierta, la foto se pierde. `NOTE (HU-06)`: recuperarla con `retrieveLostData`.
- **El borrador vive en memoria:** "Guardar" lo conserva mientras la app siga abierta. `NOTE (HU-53)`: guardarlo con los datos locales.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 27-Oct-2026
- **Detalle:** `image_picker` aprobado por el usuario como excepción al stack (`plan.md`). "Populares" oculto hasta HU-11, por decisión del usuario.
