# HU-28 — Reportar contenido o usuarios sospechosos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-28 / SCRUM-57 / Sprint 3 (adelantada del S5: requisito de Google Play) / M-13 / [musubi-api:HU-28](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m13-reputation/HU-28-reportar-contenido)

## Contexto
Jira (SCRUM-57): Como **usuario**, quiero **reportar una publicación, solicitud o usuario sospechoso**, para **mantener segura la comunidad**.

- Google Play exige reportar y bloquear en apps con contenido de usuarios (el chat). Va junto con HU-57.
- Maqueta: `reportSheet`, desde el chat (`chatMoreSheet` → "Reportar") y desde Ajustes (`aj-reportar`, "Reportar un problema").
- Trazabilidad: RF-37 · CU-20 · RN-23, RN-27.

**Depende de:** `02-04` (piezas de la maqueta), `HU-20` (chat) y la API `musubi-api:HU-28` (`POST /api/v1/reports`).

## Requisitos
1. **R1 · Motivo:** la hoja "Reportar un problema" muestra los cinco motivos de la maqueta con su ícono (`flag`, o `help` en "Otro problema"). Debajo va la nota "Tu reporte es confidencial. El equipo de Musubi lo revisa en menos de 24 horas.".
2. **R2 · Detalle:** al elegir el motivo, 240 ms después se abre la hoja con:
   - el motivo como título;
   - "Cuéntanos qué pasó" (opcional, hasta 1000 caracteres; caja de 96 como `.s-field textarea`);
   - "Enviar reporte" y "Cancelar".
3. **R3 · Desde el chat:** reporta a la otra persona con la conversación (`targetType: user`). Desde Ajustes es un problema general.
4. **R4 · Resultado:**
   - al enviar, la hoja se cierra con el aviso "Recibimos tu reporte. Te escribimos en menos de 24 h.";
   - si falla, la hoja sigue abierta y el mensaje de la API aparece bajo la caja.

## Diseño
- `lib/features/reputation/` (M-13): `ReputationRepository` y `HttpReputationRepository`, `ReportReason`, `ReportTarget` (`GeneralReport` / `UserReport`) y `showReportSheet` (`report_sheet.dart`).
- `MusubiTextField(multiline: true)` dibuja la caja de varias líneas de la maqueta.
- Íconos nuevos `flag` y `circleHelp` (Lucide de la maqueta).
- **Diferencia con la maqueta:** el texto bajo la caja dice "Si tienes capturas, el equipo te las pedirá por correo.". El de la maqueta remite a un "chat de soporte" que no existe.

## Contratos
Fila `POST /api/v1/reports` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`ApiPaths.reports`).

## Tests
- `test/features/reputation/http_reputation_repository_test.dart`: la forma de la petición (`user` con conversación y `general` sin id ni detalle vacío) y el error como `ApiFailure`.
- `test/features/reputation/reputation_flow_test.dart`: desde el chat, desde Ajustes y la hoja que sigue abierta con el error.
- Captura `reportar` y `reportar-detalle` (`tool/screenshots_test.dart`) comparada con la maqueta.

## Criterios
- [x] Se reporta a la persona desde el chat y un problema desde Ajustes, con el motivo (R1–R3).
- [x] El aviso de recibido y el error en la hoja (R4).
- [x] `dart format` sin cambios · `flutter analyze` sin observaciones · `flutter test` 100 % · critic PASS.

## Límites
- Reportar una publicación desde su detalle (`Producto`) queda para cuando la maqueta lo tenga. La API ya acepta `product`.
- `NOTE (HU-39)`: "Centro de ayuda".

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador) · 08-Nov-2026 (implementación)
- **Detalle:** se adelanta al S3 por Google Play; el texto bajo la caja cambia porque el "chat de soporte" no existe.
