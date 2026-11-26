# HU-42 — Consultar indicadores de uso (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-42 / SCRUM-65 / Sprint 5 (14 nov – 1 dic 2026; antes "versión posterior") / M-14 / [musubi-api:HU-42](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-42-indicadores-uso)

## Contexto
Jira (SCRUM-65): Como **administrador**, quiero **consultar indicadores de uso**, para **evaluar cómo funciona la plataforma**.

- Maqueta: sin pantalla propia. Se arma con las pestañas y las tarjetas de "Administración" (HU-39), sin quitar nada (lineamiento 4).
- Trazabilidad: RF-57 · CU-27 · apartado 19 de la propuesta. Las definiciones de cada indicador están en musubi-api HU-42.

**Depende de:** `HU-39` (Administración y el rol), musubi-api HU-42 (`GET /admin/indicators`).

## Requisitos
1. **R1 · Entrada:** "Indicadores de uso" en `Ajustes` → "Administración", solo con el rol `admin` (la API lo vuelve a revisar).
2. **R2 · Periodo:** "Última semana" (por defecto) y "Último mes".
3. **R3 · Áreas:** en el orden que da la API (adopción, oferta, demanda, conexión, operaciones, chat, IA, vendedores y confianza). Cada indicador muestra:
   - su nombre;
   - su valor con unidad: conteo con separador de miles, %, promedio, horas o estrellas;
   - su detalle;
   - el desglose por categoría cuando lo hay.
4. **R4 · Sin datos:** un valor `null` se ve como "—"; un porcentaje sin base lo explica ("Aún no hay datos para calcularlo").
5. **R5 · Errores:** el mensaje de la API y "Reintentar".
6. **R6 · Sin personas:** la pantalla solo muestra conteos; avisa que las ventas fuera de la app no se cuentan.

## Diseño
- `AdminRepository.indicators(IndicatorPeriod)` (`HttpAdminRepository`, `ApiPaths.adminIndicators`).
- `UsageIndicators`, `IndicatorArea`, `UsageIndicator` (`display`) e `IndicatorBreakdown`.
- `adminIndicatorsProvider(period)`, `AdminIndicatorsScreen` (`AppRoutes.adminIndicators`) y la fila de `Ajustes`.

## Contratos
Fila `GET /api/v1/admin/indicators` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) y fixture `admin-indicators.json`.

## Tests
- `test/features/admin/http_admin_repository_test.dart`:
  - el periodo, las áreas, un valor `null` y el desglose;
  - cómo se lee cada unidad.
- `test/features/admin/admin_indicators_test.dart`:
  - sin el rol no aparece;
  - con el rol, las áreas, los valores y el desglose;
  - sin datos, una raya;
  - "Último mes";
  - el error y "Reintentar".
- `test/integration/admin_flow_test.dart`: contra la API real, las 9 áreas, el mes de 30 días y 403 sin el rol.

## Criterios
- [x] El administrador consulta desde un panel los indicadores del apartado 19 (adopción, oferta, demanda, conexión, operaciones, chat, IA, vendedores y confianza) → `con el rol: las áreas, los valores con su unidad y el desglose`, `indicadores de uso (HU-42): las 9 áreas; sin el rol, 403`.
- [x] Solo con el rol `admin` → `Ajustes: sin el rol no hay "Indicadores de uso"` y la API (403).
- [ ] Prueba en el celular con la cuenta del equipo (T4).

## Límites
- Las definiciones y aproximaciones (usuarios activos, conversión, tiempos) están en musubi-api HU-42.
- No hay gráficas: son tarjetas con el número y su detalle.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (spec ligera) · 25-Nov-2026 (detallada e implementada)
