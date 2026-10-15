# plan.md — 00-01 Principios y stack

1. **Mapeo de componentes e impacto**
   - Crear: `.specify/memory/constitution.md` (§1–§5 compartidas, §6–§11 propias) y esta spec.
   - Modificar: `AGENTS.md` §1 (cita a 00-01).
2. **Decisiones de arquitectura**
   - **Riverpod** (MIT) sobre Bloc: menos código repetitivo para un equipo de 4 y overrides de providers que encajan con el patrón de fakes.
   - **go_router** (BSD-3, del equipo de Flutter): navegación declarativa y deep links (avisos push → pantalla, HU-31).
   - **dio** (MIT): interceptores (token de HU-02), timeouts y cancelación.
   - **very_good_analysis** (MIT): conjunto de lints estricto y reconocido.
   - Sin codegen por ahora (`riverpod_generator`, `freezed`): se reevalúa en 02-01 si el modelo crece.
3. **Guardarraíles:** ningún paquete sin evaluar su licencia, mantenimiento y seguridad; nada que exija un secreto en el cliente.
4. **Validación:** revisión humana (1 revisor) + `flutter analyze` sin hallazgos con el stack declarado.
5. **Secuencia:** constitución → esta spec → citas en AGENTS.md y 00-02.
