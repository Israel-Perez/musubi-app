# HU-25 — Consultar mis pedidos (plan, app)

1. **T1 — Spec:** con las decisiones de la usuaria (solo compras; pestañas por estado). ✅
2. **T2 — Datos:** `MyOrdersTab`, `MyOrdersCounts`, `MyOrdersPage`, `Order.updatedAt`, `OrderRepository.mine` y `ApiPaths.myOrders`. ✅
3. **T3 — Perfil:** `RecentOrdersSection` después de "Privacidad", con las piezas de la maqueta. ✅
4. **T4 — "Mis pedidos":** `MyOrdersScreen` con pestañas, "Ver más", vacíos y error. ✅
5. **T5 — Evidencia y documentación:** pruebas, capturas, `docs/trazabilidad.md`, `docs/versionado.md` (sección compartida) y `Memoria.md`. ✅

**Decisiones:**
- **D1 · Cancelado en gris:** la maqueta no tiene la píldora; se usa `circle-x` como el aviso de cancelación de HU-24.
- **D2 · La fecha de un completado o cancelado** es `updatedAt` (el día en que pasó), como "26 sep" de la maqueta.
- **D3 · Las pestañas cubren los 44 de alto** (RNF-27) y la pastilla de 38 queda a 3 del borde, como en `Perfil-vendedor`.
