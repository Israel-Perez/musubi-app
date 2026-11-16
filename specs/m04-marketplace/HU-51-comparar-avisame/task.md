# HU-51 — Comparar opciones y pedir aviso de disponibilidad (tareas, app)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (16-Nov-2026), con las decisiones de la usuaria.

## T2 — Dominio y datos
- **Qué:** `comparison.dart` y `HttpComparisonRepository`.
- **Prueba:** `test/features/marketplace/comparison_test.dart`.
- **Estado:** ✅ Hecho.

## T3 — Pantallas
- **Qué:** "Compara antes de comprar", "Avísame" / "Te avisaremos", "Ver parecidos", "Ver todas", la hoja "Te avisamos si vuelve" y el aviso `back_in_stock`.
- **Prueba:** `product_screen_test.dart` (grupo HU-51).
- **Estado:** ✅ Hecho.

## T4 — Evidencia y documentación
- **Qué:** capturas contra la maqueta, `docs/trazabilidad.md`, `docs/versionado.md`, `AGENTS.md` y `Memoria.md`.
- **Estado:** ✅ Hecho: format 0 · analyze 0 · `flutter test` 787 · critic PASS.

## T5 — Prueba en el celular
- **Qué:** con la API `0.5.0-alpha.37`: comparar, cambiar de pestaña, pedir "Avísame" en una agotada, reponerla desde otra cuenta y recibir el push.
- **Estado:** ⏳ Por hacer.
