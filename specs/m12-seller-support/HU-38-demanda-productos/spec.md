# HU-38 — Saber si hay demanda para mis productos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-38 / SCRUM-61 / Sprint 5 (14 nov – 1 dic 2026) / M-12 / [musubi-api:HU-38](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m12-seller-support/HU-38-demanda-productos)

## Contexto
Jira (SCRUM-61): Como **vendedor**, quiero **saber si hay usuarios buscando productos similares a los que no he vendido**, para **ofrecérselos directamente**.

- Maqueta: `Mis-productos` ("3 estudiantes la buscan · Ofrécesela") y `Vender-listo` ("2 estudiantes buscan algo similar · Ver solicitudes").
- Trazabilidad: RF-53 · CU-23 · RN-37.
- Decisiones de la usuaria (15-Nov-2026): una tarjeta por producto (hasta 3 y "Ver los N"); las ideas en una hoja al tocar la tarjeta; el aviso una sola vez, a las 3 semanas. Los 21 días salen de la maqueta ("2 productos con más de 3 semanas").

**Depende de:** [musubi-api:HU-38](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m12-seller-support/HU-38-demanda-productos), `HU-08` (`Mis-productos`), `HU-16` (ofertas), `HU-31` (avisos). Se entrega con HU-36, HU-37 y HU-38.

## Requisitos
1. **R1 · Quienes la buscan:** las solicitudes que coinciden (lo que busca, quién, "Hasta $220" y "Vence el 22 nov") con "Yo tengo este producto", que abre la hoja de oferta de HU-16 sobre la misma pantalla.
2. **R2 · RN-37:** las alertas solo se cuentan: "Y 1 persona más tiene una alerta que coincide con tu producto. Por privacidad, no te decimos quiénes."
3. **R3 · Vender-listo:** con solicitudes que coinciden, la tarjeta de la maqueta con "Ver solicitudes"; sin solicitudes, no se muestra.

## Diseño
- `lib/features/seller_support/`: `SellerSupportRepository` / `HttpSellerSupportRepository`, `sellerSupportRepositoryProvider`, `slowListingsProvider`, `productDemandProvider`; `SlowListingsPanel`, `showSalesTipsSheet`, `showDemandSheet` y `PublishedDemandCard`.

## Contratos
Filas `GET /api/v1/products/mine/slow` y `GET /api/v1/products/{id}/demand` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`ApiPaths.slowProducts` y `ApiPaths.productDemand`).

## Tests
- `test/features/seller_support/slow_listings_test.dart` (pantallas, hojas, `Vender-listo`, el aviso y `HttpSellerSupportRepository`); fake en `test/helpers/fake_seller_support.dart`.

## Criterios
- [x] "Quienes la buscan" y ofrecer → `slow_listings_test.dart` (grupo HU-38) y captura `quienes-la-buscan`.
- [x] `Vender-listo` → grupo "Vender-listo (HU-38)" y captura `vender-listo`.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 15-Nov-2026 (detallado e implementado, junto con HU-36, HU-37 y HU-38)
