# HU-37 — Recibir sugerencias para vender (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-37 / SCRUM-60 / Sprint 5 (14 nov – 1 dic 2026) / M-12 / [musubi-api:HU-37](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m12-seller-support/HU-37-sugerencias-venta)

## Contexto
Jira (SCRUM-60): Como **vendedor**, quiero **recibir sugerencias como revisar el precio, mejorar la descripción o actualizar las fotografías**, para **aumentar la probabilidad de venta**.

- Maqueta: sin pantalla propia (el aviso dice "Te damos ideas para venderla"); se agrega la hoja "Ideas para vender más rápido" con las piezas de la maqueta (lineamiento 4).
- Trazabilidad: RF-52 · CU-23 · RN-38.
- Decisiones de la usuaria (15-Nov-2026): una tarjeta por producto (hasta 3 y "Ver los N"); las ideas en una hoja al tocar la tarjeta; el aviso una sola vez, a las 3 semanas. Los 21 días salen de la maqueta ("2 productos con más de 3 semanas").

**Depende de:** [musubi-api:HU-37](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m12-seller-support/HU-37-sugerencias-venta), `HU-08` (`Mis-productos`), `HU-16` (ofertas), `HU-31` (avisos). Se entrega con HU-36, HU-37 y HU-38.

## Requisitos
1. **R1 · Hoja:** al tocar una tarjeta del panel, "Ideas para vender más rápido" con las tres ideas de la API (primero las que aplican, con el icono en color de advertencia).
2. **R2 · Orientativas (RN-38):** "Son ideas: tú decides qué cambiar. Musubi nunca cambia tu publicación por su cuenta."
3. **R3 · Editar:** "Editar publicación" abre `Vender-2…4` con el borrador de edición (HU-07); al guardar, la API vuelve a buscar coincidencias.
4. **R4 · Ideas con IA (criterio de SCRUM-60 del 13-Nov-2026):** debajo de las tres ideas, el bloque "Nombre y descripción con IA" (no está en la maqueta: se agrega por el lineamiento 4, con las piezas de la hoja y el ícono `sparkle` de "Resumir acuerdo"). Nada sale hasta tocar "Proponer con IA" (RNF-06), y el bloque dice que solo se envía la publicación, sin nombre ni datos. Con la propuesta muestra "Nombre" y "Descripción" y "Usar en mi publicación", que abre la edición con ese texto ya escrito: quien vende revisa y guarda (RN-38). Si la IA no está (`seller_support.ideas_unavailable`, cuota o red), dice el mensaje de la API, quedan las ideas predefinidas y ofrece "Intentar de nuevo" (RNF-15).

## Diseño
- `lib/features/seller_support/`: `SellerSupportRepository` / `HttpSellerSupportRepository`, `sellerSupportRepositoryProvider`, `slowListingsProvider`, `productDemandProvider`; `SlowListingsPanel`, `showSalesTipsSheet`, `showDemandSheet` y `PublishedDemandCard`.

## Contratos
Filas `GET /api/v1/products/mine/slow`, `GET /api/v1/products/{id}/demand` y `POST /api/v1/products/{id}/ideas` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`ApiPaths.slowProducts`, `ApiPaths.productDemand` y `ApiPaths.productIdeas`, con espera de 30 s como el acuerdo).

## Tests
- `test/features/seller_support/slow_listings_test.dart` (pantallas, hojas, `Vender-listo`, el aviso y `HttpSellerSupportRepository`); fake en `test/helpers/fake_seller_support.dart`.

## Criterios
- [x] Las tres ideas y "Editar publicación" → `slow_listings_test.dart` (grupo HU-37) y captura `ideas-vender`.
- [x] Ideas con IA solo a petición, "Usar en mi publicación" llena la edición sin guardar y sin IA quedan las predefinidas → `"Proponer con IA" solo a peticion…`, `sin IA lo dice…`, las dos pruebas de `HttpSellerSupportRepository` y captura `ideas-ia`.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 15-Nov-2026 (detallado e implementado, junto con HU-36, HU-37 y HU-38; R4 de IA agregada el mismo día a petición de la usuaria)
