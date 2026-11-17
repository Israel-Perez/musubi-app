# HU-44 — Coordinar la entrega en un punto del campus (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-44 / SCRUM-56 / Sprint 4 (9 – 20 nov 2026) / M-08 / [musubi-api:HU-44](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-44-coordinar-entrega)

## Contexto
Jira (SCRUM-56): Como **comprador o vendedor**, quiero **acordar un punto de encuentro dentro del campus para la entrega**, para **concretar la operación de forma segura sin salir de la aplicación**.

- Maqueta: `Pedido-pago` ("Entrega": punto, día y hora), `Pedido-entrega`, `Apartar` y `Apartado-listo`.
- Trazabilidad: RF-30 · R-14 · Entregable 1 §6, §7 y §11 (Sprint 4).
- **Se cumple con lo que ya se construyó** en HU-23 (al pedir se eligen el edificio, con el de la carrera primero, el día y la hora), HU-24 (`Tu pedido` / `Tu venta` con la entrega) y HU-52 (apartar con hora y punto). Esta spec solo concilia la evidencia; no agrega código.

**Depende de:** `HU-23`, `HU-24`, `HU-52`.

## Requisitos
1. **R1 · Elegir:** al pedir (o apartar) se elige un punto de la lista del campus (`GET /orders/meeting-points`, con el edificio de la carrera sugerido), el día y la hora.
2. **R2 · Ver:** `Tu pedido` y `Tu venta` (y `Apartado-listo` / `Mis-apartados`) muestran el punto, el día y la hora a las dos partes.
3. **R3 · Límites:** solo en el campus; sin envíos a domicilio.

## Diseño
Sin cambios: `lib/features/orders/` (la hoja de entrega de HU-23, `OrderPaymentScreen` de HU-24 y `showReserveSheet` de HU-52).

## Contratos
Filas de HU-23 y HU-52 en [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`GET /orders/meeting-points`, `POST /orders`, `POST /reservations`).

## Tests
Los de HU-23, HU-24 y HU-52 (abajo, por criterio). No hay pruebas nuevas.

## Criterios
- [x] Al generar o confirmar un pedido se elige un punto de encuentro de una lista definida dentro de la universidad, junto con fecha y hora → `test/features/orders/order_flow_test.dart` (`el edificio de mi carrera sale primero`, `elegir entrega y fecha y crear el pedido abre Tu pedido`), `order_data_test.dart` (`los puntos de entrega traen el recomendado`, `crear manda el contrato y mapea el pedido`) y `reservations_test.dart` (`"Apartar" del producto elige hora y punto y abre el QR`).
- [x] El punto de encuentro y la fecha quedan registrados en el pedido y son visibles para ambas partes → `order_flow_test.dart` (`quien vende ve Tu venta y como le pagaran`, `quien vende acepta un pedido con el pago elegido`).
- [x] Los envíos a domicilio y la logística externa quedan fuera del alcance → la app solo ofrece los puntos del campus.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % (los de `main`) · critic PASS.

## Límites
- **Decisión (16-Nov-2026, la propuesta de Jira):** la lista la administrará HU-41; hoy la siembra la API (`db/014`).
- Cambiar el punto o la hora de un pedido ya creado se acuerda por el chat (no hay "reprogramar").

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 16-Nov-2026 (conciliada con HU-23, HU-24 y HU-52)
