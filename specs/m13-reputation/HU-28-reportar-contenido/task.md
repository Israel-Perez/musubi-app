# HU-28 — Reportar contenido o usuarios sospechosos (app, tareas)

## T1 — Datos
- **Crear:** `ReputationRepository`, `HttpReputationRepository` y `ApiPaths.reports`.
- **Verificar:** `http_reputation_repository_test.dart`.
- **Estado:** ✅ Hecho (08-Nov-2026).

## T2 — Hojas
- **Crear:** `showReportSheet` (motivos con la nota y el detalle) y `MusubiTextField(multiline)`.
- **Verificar:** `reputation_flow_test.dart` y las capturas `reportar` y `reportar-detalle`.
- **Estado:** ✅ Hecho (08-Nov-2026).

## T3 — Entradas
- **Cambiar:** "Más opciones" del chat → "Reportar" y Ajustes → "Reportar un problema".
- **Estado:** ✅ Hecho (08-Nov-2026).

## Pendientes
- Reportar desde el detalle de una publicación cuando la maqueta lo incluya.
