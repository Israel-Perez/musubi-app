# HU-36 — Ver mis productos con baja rotación (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-36 / SCRUM-59 / Sprint 5 (14 nov – 1 dic 2026) / M-12 / [musubi-api:HU-36](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m12-seller-support/HU-36-baja-rotacion)

## Contexto
Jira (SCRUM-59): Como **vendedor**, quiero **saber qué productos llevan mucho tiempo publicados sin venderse**, para **decidir qué hacer con ellos**.

- Maqueta: `Mis-productos` (panel "Llevan tiempo sin venderse") y `Notificaciones` ("Tu bata lleva 34 días sin venderse").
- Trazabilidad: RF-50, RF-51 · CU-22 · RN-35, RN-36.
- Decisiones de la usuaria (15-Nov-2026): una tarjeta por producto (hasta 3 y "Ver los N"); las ideas en una hoja al tocar la tarjeta; el aviso una sola vez, a las 3 semanas. Los 21 días salen de la maqueta ("2 productos con más de 3 semanas").

**Depende de:** [musubi-api:HU-36](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m12-seller-support/HU-36-baja-rotacion), `HU-08` (`Mis-productos`), `HU-16` (ofertas), `HU-31` (avisos). Se entrega con HU-36, HU-37 y HU-38.

## Requisitos
1. **R1 · Panel:** en "Activos", arriba de "Tu inventario", "Llevan tiempo sin venderse · N productos con más de 3 semanas" y una tarjeta por producto (foto de 60, nombre, "$250 · Publicada hace 34 días", vistas y mensajes), hasta 3 y "Ver los N".
2. **R2 · Sin ruido:** no sale en "Vendidos" ni "Agotados"; sin nada o si falla, la pantalla sigue sin el panel.
3. **R3 · Aviso:** `slow_listing` con `trendingDown` sobre fondo de advertencia; abre `Mis productos` (`my_products`).

## Diseño
- `lib/features/seller_support/`: `SellerSupportRepository` / `HttpSellerSupportRepository`, `sellerSupportRepositoryProvider`, `slowListingsProvider`, `productDemandProvider`; `SlowListingsPanel`, `showSalesTipsSheet`, `showDemandSheet` y `PublishedDemandCard`.

## Contratos
Filas `GET /api/v1/products/mine/slow` y `GET /api/v1/products/{id}/demand` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`ApiPaths.slowProducts` y `ApiPaths.productDemand`).

## Tests
- `test/features/seller_support/slow_listings_test.dart` (pantallas, hojas, `Vender-listo`, el aviso y `HttpSellerSupportRepository`); fake en `test/helpers/fake_seller_support.dart`.

## Criterios
- [x] "Llevan tiempo sin venderse" como la maqueta → `slow_listings_test.dart` (grupo HU-36) y captura `mis-productos`.
- [x] El aviso abre `Mis productos` → `el aviso "lleva N días sin venderse" abre Mis productos`.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 15-Nov-2026 (detallado e implementado, junto con HU-36, HU-37 y HU-38)
