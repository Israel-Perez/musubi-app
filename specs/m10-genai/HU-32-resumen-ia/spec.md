# HU-32 — Pedir un resumen de la conversación con IA (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-32 / SCRUM-52 / Sprint 4 (9 – 20 nov 2026) / M-10 / [musubi-api:HU-32](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m10-genai/HU-32-resumen-ia)

## Contexto
Jira (SCRUM-52): Como **usuario**, quiero **pedir un resumen de la conversación**, para **recordar lo que se ha platicado**.

- Maqueta: `Chat` ("¿Ya se pusieron de acuerdo?" → "Resumir acuerdo") y `Acuerdo-esperando`.
- Trazabilidad: RF-44 · CU-16 · RN-39, RN-40, RN-44 · RNF-06, RNF-12, RNF-15.
- Decisiones de la usuaria (10-Nov-2026): Gemini en la capa gratuita; la primera vez, un aviso; en el chat, "Ana pidió un resumen con IA"; del chat no se guarda nada y la propuesta se borra al crear el pedido o a los 30 días, y el aviso de privacidad lo dice.
- HU-32, HU-33 y HU-34 comparten la hoja y la ruta: se entregan en un solo PR.

**Depende de:** `02-04`, `HU-20` (chat), `HU-23` (resumen sin IA y pedido).

## Requisitos
1. **R1 · A petición (RN-39):** "Resumir acuerdo" (los dos participantes) es lo único que llama a la IA.
2. **R2 · Aviso (RN-40):** la primera vez en el dispositivo, un diálogo explica qué se envía y qué se guarda ("Resumir" o "Cancelar"); cancelar no envía nada. En el chat, el aviso `kind: notice` de la API se pinta centrado ("Ana pidió un resumen con IA"), no como burbuja.
3. **R3 · Indicador (RNF-12):** mientras la IA lee el chat, la hoja muestra "La IA está leyendo el chat…" con el esqueleto de los datos.
4. **R4 · Sin IA (RNF-15):** con `genai.unavailable`, quien compra ve el aviso y se abre el resumen a mano de HU-23; quien vende, el aviso. Otros errores se avisan y el chat sigue.
5. **R5 · Aviso de privacidad:** `assets/legal/aviso-de-privacidad.md` explica qué sale a Gemini, cómo se filtra y cuánto se conserva.

## Diseño
- Feature `lib/features/genai/`: `domain/` (`Agreement`, `AgreementEdit`, `AgreementRepository`), `data/` (`HttpAgreementRepository`, espera hasta 30 s) y `presentation/` (`agreementProvider`, `AiNoticeStore` en el almacén cifrado y `agreement_sheet.dart`).
- El chat (`chat_screen.dart`) abre el acuerdo vigente o pide uno; `ChatMessage.notice` y `ChatRealtime.agreementChanges` (evento `agreementChanged`).

## Contratos
Filas "M-10" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), enlazadas desde `lib/core/network/api_paths.dart`; `MessageResponse.kind` (M-07).

## Tests
`test/features/genai/agreement_flow_test.dart`, `test/features/genai/agreement_data_test.dart`: el aviso de la primera vez, el indicador, sin IA, otro error, el aviso del chat, `kind: notice` y el evento del hub con un servidor WebSocket real.

## Criterios
- [x] La IA solo se ejecuta cuando un participante lo solicita (R1, RN-39).
- [x] Ambos participantes saben que la conversación puede procesarse con IA (R2, R5, RN-40).
- [x] Solo se envía la información mínima: `musubi-api:HU-32` (RNF-06).
- [x] Se muestra un indicador mientras se genera el resumen (R3, RNF-12).
- [x] Si la IA no está disponible, se informa y el chat sigue funcionando (R4, RNF-15).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS · capturas comparadas con la maqueta.

## Límites
- `NOTE (HU-47)`: subir la versión del aviso de privacidad (y pedir aceptarlo otra vez) es decisión de la usuaria; hoy sigue `2026-10`.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 10-Nov-2026 (detallado e implementado)
- **Detalle:** aviso de la primera vez, indicador mientras lee y respaldo sin IA.
