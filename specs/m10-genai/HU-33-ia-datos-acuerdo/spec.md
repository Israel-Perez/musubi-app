# HU-33 — La IA identifica los datos del acuerdo (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-33 / SCRUM-53 / Sprint 4 (9 – 20 nov 2026) / M-10 / [musubi-api:HU-33](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m10-genai/HU-33-ia-datos-acuerdo)

## Contexto
Jira (SCRUM-53): Como **comprador o vendedor**, quiero **que la IA identifique producto, precio, cantidad, entrega y fecha a partir del chat**, para **convertir la conversación en una propuesta de acuerdo**.

- Maqueta: `Acuerdo-esperando`.
- Trazabilidad: RF-45 · CU-16 · RN-42, RN-43.
- Decisiones de la usuaria (10-Nov-2026): Gemini en la capa gratuita; la primera vez, un aviso; en el chat, "Ana pidió un resumen con IA"; del chat no se guarda nada y la propuesta se borra al crear el pedido o a los 30 días, y el aviso de privacidad lo dice.

**Depende de:** `HU-32`.

## Requisitos
1. **R1 · Propuesta:** la hoja muestra "Propuesta generada con IA, revísala antes de confirmar", producto, precio acordado, cantidad, entrega (con su detalle), fecha y, si la IA las encontró, condiciones.
2. **R2 · "No identificado" (RN-42):** lo que falta sale en ámbar con "Agregar" y la nota "No encontramos una fecha en la conversación. Agrégala o pregúntale a Diego en el chat." (concuerda con lo que falta).
3. **R3 · Misma forma:** `agreementFromJson` exige los ocho campos de la propuesta, cada uno de su tipo; si no, `agreements.invalid_response` y no se muestra.
4. **R4 · La IA no actúa (RN-43):** nada se confirma ni se envía solo; solo las personas tocan los botones.

## Diseño
Ver `HU-32/spec.md`. La hoja reutiliza `SummaryField` y los paneles de HU-23.

## Contratos
`AgreementResponse` (fixture `agreement.json` de musubi-api).

## Tests
`test/features/genai/agreement_flow_test.dart`, `test/features/genai/agreement_data_test.dart`: mapeo, lo que falta y lo agregado, forma inválida y la hoja con "No identificado".

## Criterios
- [x] La IA propone producto, precio, cantidad, lugar, fecha y condiciones (R1).
- [x] Lo que no se mencionó se marca como "No identificado" (R2, RN-42).
- [x] La IA no negocia ni actúa por nadie (R4, RN-43).
- [x] La app valida que la respuesta tenga siempre los mismos campos antes de mostrarla (R3).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS · capturas comparadas con la maqueta.

## Límites
- Diferencias con la maqueta: "Descartar propuesta" (HU-34 lo pide) y la fila de condiciones cuando la IA las encuentra.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 10-Nov-2026 (detallado e implementado)
- **Detalle:** la propuesta igual a `Acuerdo-esperando`, con validación de forma.
