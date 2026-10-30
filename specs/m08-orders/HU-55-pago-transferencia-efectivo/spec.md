# HU-55 — Pagar un pedido por transferencia o en efectivo (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-55 / SCRUM-72 / por asignar / M-08 / [musubi-api:HU-55](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-55-pago-transferencia-efectivo)

## Contexto
Jira (SCRUM-72): Como **comprador**, quiero **pagar un pedido por transferencia a la cuenta verificada del vendedor o en efectivo al recibirlo**, para **cerrar la compra sin comisiones**.

- Maqueta: `Pedido-pago`, `Pago-transferencia`, `Pago-validando`, `Pago-vendedor`, `Pedido-entrega`, `Pedido-efectivo`, `Cuenta-pagos`.
- Trazabilidad: sin RF/RNF en Jira (historia que nació de la maqueta, SCRUM-75).
- Origen: maqueta (secciones 9 y 10). Decisión D-01 (21-Oct-2026): se sigue el modelo de pago de la maqueta y **reemplaza a HU-43** (Mercado Pago, fuera de alcance)..

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-23`, `HU-44`.

## Requisitos
1. El vendedor registra su cuenta para recibir pagos (CLABE), que se valida y se guarda cifrada; solo se muestra enmascarada.
2. Por **transferencia**, el comprador ve la cuenta del vendedor y una referencia; el vendedor valida el pago y el pedido pasa a "Confirmado".
3. En **efectivo**, el comprador recibe un código de entrega de 4 dígitos que el vendedor captura al entregar; el pedido pasa a "Completado".
4. Musubi no cobra comisión ni procesa el dinero (se indica en la pantalla).
5. Solo las partes del pedido ven los datos de pago (RNF-03, RNF-05).

RNF que aplican: RNF-03, RNF-05.

## Diseño
- Feature `lib/features/orders/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-55. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-55)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-55, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] El vendedor registra su cuenta para recibir pagos (CLABE), que se valida y se guarda cifrada; solo se muestra enmascarada.
- [ ] Por **transferencia**, el comprador ve la cuenta del vendedor y una referencia; el vendedor valida el pago y el pedido pasa a "Confirmado".
- [ ] En **efectivo**, el comprador recibe un código de entrega de 4 dígitos que el vendedor captura al entregar; el pedido pasa a "Completado".
- [ ] Musubi no cobra comisión ni procesa el dinero (se indica en la pantalla).
- [ ] Solo las partes del pedido ven los datos de pago (RNF-03, RNF-05).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): el plazo para validar una transferencia antes de cancelar el pedido.
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
