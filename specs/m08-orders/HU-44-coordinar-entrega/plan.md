# plan.md — HU-44 Coordinar la entrega en un punto del campus (app)

## 1. Componentes
Ninguno nuevo: la hoja de entrega de HU-23, `OrderPaymentScreen` (HU-24) y `showReserveSheet` (HU-52).

## 2. Decisiones (con su porqué)
- **No se duplica código:** HU-23 ya elige el punto de la lista, el día y la hora; HU-52 lo mismo al apartar.
- **Quién administra la lista (propuesta de Jira, 16-Nov-2026):** HU-41.

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
La API valida el punto y la ventana de horas; la app solo ofrece la lista del campus.

## 5. Validación
Las pruebas de HU-23, HU-24 y HU-52 listadas en `spec.md`.

## 6. Secuencia
Conciliar la spec, `task.md` y `docs/trazabilidad.md`.
