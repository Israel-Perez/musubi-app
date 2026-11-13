# HU-27 — Calificar al vendedor al terminar un pedido (plan, app)

Se implementó junto con HU-45.

1. **T1 — Spec:** decisiones de la usuaria del 12-Nov-2026. ✅
2. **T2 — Datos:** modelos, `ReputationRepository.rate`/`opinions`, `Order.ratedByMe`/`rateUntil` y `PublicProfile.onTime`. ✅
3. **T3 — `Calificar`:** `RateScreen` con las piezas de la maqueta y su ruta. ✅
4. **T4 — "Tu pedido" y `Perfil-vendedor`:** "Calificar a …", paso a `Calificar` al completar, "Opiniones" y "A tiempo". ✅
5. **T5 — Evidencia y documentación:** pruebas, capturas, trazabilidad, versionado (sección compartida) y Memoria. ✅

**Decisiones:**
- **D1 · Al completar, a `Calificar`:** como la maqueta (`Pedido-entrega` → `Calificar`); el aviso "Listo" se quita para que no tape "Ahora no".
- **D2 · Al enviar, a Inicio:** como la maqueta, con el aviso de agradecimiento.
- **D3 · El comentario va en un `TextField` propio:** la maqueta lo pone con "Opcional" junto a la etiqueta y dos líneas; `MusubiTextField` tiene otra forma.
