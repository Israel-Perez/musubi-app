# HU-35 — Ver productos recomendados (plan, app)

1. **T1 — Spec.** ✅
2. **T2 — Datos:** repositorio, providers y fake. ✅
3. **T3 — Inicio:** "Recomendado para ti". ✅
4. **T4 — Producto:** "Productos parecidos" y "Ver parecidos". ✅
5. **T5 — Privacidad:** el interruptor y el aviso de privacidad. ✅
6. **T6 — Pruebas y capturas.** ✅

**Decisiones:**
- **D1 · Las secciones son secundarias:** si la API no responde, Inicio y Producto siguen iguales (sin mensaje de error).
- **D2 · Mismo estilo que "Publicaciones recientes":** `RecentTile` en fila horizontal; la maqueta no dibuja la sección y la guía de estilo da el título.
