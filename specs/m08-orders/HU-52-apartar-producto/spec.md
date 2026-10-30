# HU-52 — Apartar un producto y verificar la entrega con QR o código (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-52 / SCRUM-74 / por asignar / M-08 / [musubi-api:HU-52](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-52-apartar-producto)

## Contexto
Jira (SCRUM-74): Como **comprador**, quiero **apartar un producto por 24 horas y recibir un QR o un código**, para **que el vendedor me lo guarde y verifique que soy yo al entregarlo**.

- Maqueta: `Apartar`, `Apartado-listo`, `Mis-apartados`, `Verificar-comprador`, `Apartado-verificado`.
- Trazabilidad: sin RF/RNF en Jira (historia que nació de la maqueta, SCRUM-75).
- Origen: maqueta (sección 4, G-05).

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-11`, `HU-44`.

## Requisitos
1. Al apartar se eligen la fecha, la hora y el punto de entrega (relación con HU-44); el apartado vence a las 24 horas.
2. El comprador recibe un QR y un código de 6 dígitos de un solo uso.
3. El vendedor escanea el QR o escribe el código; solo el vendedor de ese apartado puede verificarlo (RNF-03).
4. "Mis apartados" muestra lo que yo aparté y lo que me apartaron.
5. El código no se puede adivinar por fuerza bruta (intentos limitados).

RNF que aplican: RNF-03.

## Diseño
- Feature `lib/features/orders/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-52. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-52)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-52, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Al apartar se eligen la fecha, la hora y el punto de entrega (relación con HU-44); el apartado vence a las 24 horas.
- [ ] El comprador recibe un QR y un código de 6 dígitos de un solo uso.
- [ ] El vendedor escanea el QR o escribe el código; solo el vendedor de ese apartado puede verificarlo (RNF-03).
- [ ] "Mis apartados" muestra lo que yo aparté y lo que me apartaron.
- [ ] El código no se puede adivinar por fuerza bruta (intentos limitados).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): cuántos apartados activos puede tener un comprador a la vez.
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
