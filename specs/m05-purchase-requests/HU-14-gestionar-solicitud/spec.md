# HU-14 — Editar, cerrar o cancelar mi solicitud (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-14 / SCRUM-36 / Sprint 4 (9 – 20 nov 2026) / M-05 / [musubi-api:HU-14](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-14-gestionar-solicitud)

## Contexto
Jira (SCRUM-36): Como **comprador**, quiero **editar, cerrar o cancelar mi solicitud**, para **que refleje si todavía necesito el producto**.

- Maqueta: `Mis-solicitudes` ("Cambiar" sobre la solicitud elegida) y `Necesidad-1…3` para editar. La maqueta no dibuja estas acciones: se arman con sus piezas (hoja de opciones y diálogo de confirmación).
- Trazabilidad: RF-17, RF-18 · CU-09 · RN-10, RN-11, RN-15.

**Depende de:** `HU-13`, `HU-17` y las filas de `musubi-api:HU-14`.

## Requisitos
1. **R1 · "Tu solicitud":** en una solicitud activa, "Cambiar" abre una hoja con "Ver otra solicitud" (si hay más), "Editar solicitud", "Ya lo conseguí" y "Cancelar solicitud". En una que no está activa, "Cambiar" solo elige otra.
2. **R2 · Editar:** `Necesidad-1…3` con los datos de la solicitud y el título "Editar solicitud". "Guardar" y "Guardar cambios" mandan los cambios y vuelven a `Mis-solicitudes` con un aviso; la X vuelve sin guardar. Con ofertas, el producto y la categoría no cambian y un aviso lo explica.
3. **R3 · Cerrar y cancelar:** cada uno pide confirmar. Al confirmar, la solicitud pasa a "Cerradas" con su estado ("Cerrada" o "Cancelada") y sale un aviso. Si la API no deja (por ejemplo, ya venció), el aviso dice por qué.
4. **R4 · Solo activas deciden (RN-11):** en una cerrada, cancelada o vencida, las ofertas se ven sin "Rechazar" ni "Aceptar"; "Abrir chat" sigue.
5. **R5 · Vencida (RF-18):** la API la entrega como `expired` y la app la muestra en "Cerradas" como "Vencida" (desde HU-13).

## Diseño
- **Datos:** `WantedRepository.update`, `close` y `cancel`; `ApiPaths.wantedById` y `wantedAction`.
- **Borrador:** `NeedDraft.editingId` y `productLocked`; `NeedDraft.fromRequest(request, today)` devuelve la fecha a su opción rápida si coincide. Hay otro borrador para editar (`needEditDraftProvider`) y `needDraftFor(editing:)` elige cuál.
- **Pantallas:**
  - `MyWantedScreen._manage` y `_setStatus`;
  - `need_edit.dart` (`saveNeedEdit` y `leaveNeedEdit`);
  - `SellStepLayout.onClose`;
  - rutas `AppRoutes.editNeed`, `editNeedDetails` y `editNeedBudget`, con sesión.

## Contratos
Filas `PUT /api/v1/wanted/{id}`, `POST /api/v1/wanted/{id}/close` y `POST /api/v1/wanted/{id}/cancel` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), enlazadas desde `lib/core/network/api_paths.dart`.

## Tests
- `test/features/purchase_requests/manage_wanted_test.dart`: R1–R4 (la hoja, ver otra, cerrar, cancelar y "No, mantenerla", el error de la API, editar y guardar, "Guardar" y la X, con ofertas y una cerrada sin decisiones).
- `test/features/purchase_requests/wanted_data_test.dart`: el contrato de las 3 rutas y el borrador de editar.
- `test/features/purchase_requests/need_flow_test.dart`: "Cambiar" → "Ver otra solicitud".
- `tool/screenshots_test.dart`: escenas `mis-solicitudes-gestionar` y `editar-solicitud`.

## Criterios
- [x] El comprador puede editar, cerrar (ya consiguió el producto) o cancelar sus solicitudes (R1–R3).
- [x] Los estados son **Activa**, **Cerrada**, **Cancelada** y **Expirada**; solo las activas reciben ofertas (R4, RN-11).
- [x] La solicitud pasa a **Expirada** automáticamente al vencer su fecha límite o el periodo máximo (R5).
- [ ] Al completarse un pedido originado en la solicitud, el sistema propone cerrarla (RN-15): `NOTE (HU-25)`, todavía no hay pedidos.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- No se reabre una solicitud: se publica otra.
- `NOTE (HU-30)`: avisar a quienes ofrecieron.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador) · 09-Nov-2026 (implementación)
- **Detalle:** las acciones no están en la maqueta; van en la hoja de "Cambiar" para no tocar la tarjeta de `Mis-solicitudes`.
