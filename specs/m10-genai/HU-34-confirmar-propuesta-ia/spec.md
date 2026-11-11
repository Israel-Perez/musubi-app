# HU-34 — Revisar y confirmar la propuesta de la IA (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-34 / SCRUM-54 / Sprint 4 (9 – 20 nov 2026) / M-10 / [musubi-api:HU-34](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m10-genai/HU-34-confirmar-propuesta-ia)

## Contexto
Jira (SCRUM-54): Como **usuario**, quiero **revisar y corregir la propuesta de la IA antes de confirmarla**, para **asegurarme de que refleja lo que realmente acordamos**.

- Maqueta: `Acuerdo-esperando` (lápices, "0 de 2", "Confirmar acuerdo") y `Acuerdo-confirmado` ("Agregada", "Crear pedido", "Volver al chat").
- Trazabilidad: RF-46, RF-47 · CU-16 · RN-41.
- Decisiones de la usuaria (10-Nov-2026): Gemini en la capa gratuita; la primera vez, un aviso; en el chat, "Ana pidió un resumen con IA"; del chat no se guarda nada y la propuesta se borra al crear el pedido o a los 30 días, y el aviso de privacidad lo dice.

**Depende de:** `HU-33`, `HU-23` (paneles y `Pedido-pago`).

## Requisitos
1. **R1 · Corregir:** los lápices abren el producto, el precio (en pesos), la cantidad, la entrega y la fecha (paneles de HU-23) y las condiciones; cada cambio borra las confirmaciones.
2. **R2 · Confirmar (RN-41):** "Confirmar acuerdo" se ve activo como en la maqueta; si falta algo, avisa sin llamar a la API. Después: "1 de 2" y "Esperando a Diego". Si la otra persona cambió algo antes, `agreements.changed` se avisa y la hoja se vuelve a leer.
3. **R3 · Tiempo real:** con `agreementChanged` la hoja abierta y el aviso del chat se actualizan (por ejemplo, pasa a "Acuerdo confirmado").
4. **R4 · Confirmado:** "Acuerdo confirmado · Ana y Diego lo confirmaron · hora", "Agregada" en lo que agregó una persona y "Si algo cambia, ambos deben confirmar de nuevo." Quien compra toca "Crear pedido" (`POST /orders` con `agreementId`) y se abre `Pedido-pago`; quien vende ve que lo crea quien compra.
5. **R5 · Descartar:** "Descartar propuesta" (con diálogo) lo borra para los dos y vuelve "Resumir acuerdo".
6. **R6 · Aviso del chat:** "Acuerdo · Esperando confirmación (1 de 2)" o "Acuerdo confirmado · Falta crear el pedido", con "Ver acuerdo".

## Diseño
Ver `HU-32/spec.md`. `OrderRepository.createFromAgreement`.

## Contratos
Filas "M-10" y `POST /api/v1/orders` (`agreementId`) de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md).

## Tests
`test/features/genai/agreement_flow_test.dart`, `test/features/genai/agreement_data_test.dart`: agregar la fecha, corregir el precio, confirmar, versión vieja, la otra persona confirma, crear el pedido, quien vende, el aviso del chat y descartar. `tool/screenshots_test.dart`: escenas `acuerdo-esperando` y `acuerdo-confirmado` en claro y oscuro.

## Criterios
- [x] Ambos participantes pueden revisar y corregir la propuesta (R1).
- [x] Un participante la envía al otro, que la confirma o pide cambios; si la rechaza, se descarta y la conversación continúa (R2, R3, R5).
- [x] El acuerdo solo es válido cuando ambos lo confirman (R2, R4, RN-41).
- [x] Un acuerdo confirmado se convierte en pedido con los datos ya llenados (R4, RF-47).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS · capturas comparadas con la maqueta.

## Límites
- `NOTE (HU-31)`: aviso push cuando la otra persona confirma.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 10-Nov-2026 (detallado e implementado)
- **Detalle:** corrección con los paneles de HU-23, confirmación por versión y pedido con lo acordado.
