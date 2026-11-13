# HU-26 — Consultar mi historial de ventas (plan, app)

1. **T1 — Spec:** decisiones de la usuaria ("Vendidos" de `Mis-productos`). ✅
2. **T2 — Datos:** `SalesPage`, `OrderRepository.sales`, `salesProvider` y el fake. ✅
3. **T3 — "Vendidos":** tarjeta con el total real, filas de venta, "Tu venta" al tocar, lo marcado a mano abajo y "Ver más". ✅
4. **T4 — Pruebas, captura y documentación.** ✅

**Decisiones:**
- **D1 · La tarjeta solo cuenta ventas completadas:** lo marcado a mano no tiene monto real; es el mismo número que "Ventas" del perfil.
- **D2 · Lo marcado a mano va después de la última venta:** son dos listas con su propio cursor; mezclarlas por fecha obligaría a pedir las dos completas.
