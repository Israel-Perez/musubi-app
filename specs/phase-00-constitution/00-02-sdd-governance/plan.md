# plan.md — 00-02 Gobernanza SDD

1. **Componentes:** `specs/_template.md` (compartida), esta spec, `AGENTS.md` §2, `Memoria.md`, `docs/trazabilidad.md`, plantilla de PR.
2. **Decisiones:**
   - Mismos IDs y carpetas de HU que en `musubi-api`: una HU se rastrea de punta a punta (`specs/m01-auth/HU-01-*` en los dos repos).
   - El front nunca duplica el contrato HTTP: enlaza filas del catálogo del back.
   - Estado "Borrador con evidencia" para no simular firmas.
3. **Guardarraíles:** criterios medibles; secciones compartidas verificadas con `scripts/check_shared_sections.ps1`.
4. **Validación:** comparación estructural de las 9 specs piloto.
5. **Secuencia:** plantilla → specs 00 → specs 01 → AGENTS/Memoria → verificación estructural.
