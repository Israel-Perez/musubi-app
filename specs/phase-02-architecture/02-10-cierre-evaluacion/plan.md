# 02-10 — Cierre de brechas de la evaluación (app, plan)

1. **Arnés:** `test/integration/support/` con los proveedores reales de la app y un interceptor de cobertura.
2. **Flujos:** uno por grupo de pantallas, siguiendo `docs/maqueta/`: sesión, perfil, vender, explorar, chat, pedidos y apartados, "Se busca", avisos y reputación, administración y seguridad.
3. **Guard:** `tool/check_integration_coverage.dart`, que toma el catálogo de musubi-api.
4. **CI:** job `integration` con `scripts/run_integration_tests.ps1`.
5. **Seguridad:** `test/security/session_security_test.dart`, y el logout manda el access token.
6. **Documentación:** `AGENTS.md`, `Memoria.md`, skill `testing-strategy`, `test/integration/README.md` y `docs/versionado.md` (fila compartida).
