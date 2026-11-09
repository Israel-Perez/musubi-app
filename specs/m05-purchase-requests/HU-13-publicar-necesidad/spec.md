# HU-13 — Publicar una necesidad de compra (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-13 / SCRUM-35 / Sprint 3 / M-05 / [musubi-api:HU-13](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-13-publicar-necesidad)

## Contexto
Jira (SCRUM-35): Como **comprador**, quiero **publicar una solicitud indicando el producto, la descripción, las características, el presupuesto, la cantidad y la fecha en que lo necesito**, para **que otros usuarios sepan lo que busco**.

- Maqueta: `Necesidad-1`, `Necesidad-2`, `Necesidad-3`, `Necesidad-publicada` y `Mis-solicitudes`.
- Trazabilidad: RF-16, RF-22 · CU-08 · Flujo B · RN-09, RN-10, RN-12.

**Depende de:** `02-01`, `02-04` (piezas de la maqueta), `HU-01`, `HU-06` (pasos de Vender) y la API `musubi-api:HU-13`.

## Requisitos
1. **R1 · Producto (`Necesidad-1`):**
   - "Así funciona" con los tres pasos;
   - "Producto que buscas" (3 a 80, con la palomita al ser válido);
   - categorías del campus más "Otro".
   - Al escribir (500 ms después) avisa "Ya hay N publicaciones parecidas. Te las mostramos al publicar." con la búsqueda de HU-09.
2. **R2 · Detalles (`Necesidad-2`):**
   - descripción opcional (hasta 300, con contador);
   - hasta 5 características de hasta 40, con chips que se quitan.
3. **R3 · Presupuesto (`Necesidad-3`):**
   - presupuesto máximo con la pista del rango del campus (`PriceRange` de HU-06);
   - cantidad de 1 a 10;
   - "Esta semana", el próximo viernes o "Elegir fecha" (lunes, miércoles y viernes de la semana que entra y el lunes siguiente, como `NEED_DATES`).
   - La vista previa "Así la verá tu comunidad" es el boleto "Se busca".
4. **R4 · Campos pendientes (RN-09):** sin producto, categoría o presupuesto, la app señala el campo y no avanza. Si la API rechaza (moderación, `wanted.invalid_*`, `too_many_active`), avisa con su mensaje y se queda en el paso 3.
5. **R5 · Publicada (`Necesidad-publicada`):**
   - el boleto con "Activa";
   - "Avisando a vendedores con productos parecidos…";
   - "Ya coinciden con lo que buscas": primero lo que cabe en el presupuesto y luego lo de arriba;
   - "Inicio" y "Ver mi solicitud".
6. **R6 · Mis solicitudes (`Mis-solicitudes`):**
   - pestañas "Activas (N)" y "Cerradas (N)";
   - la solicitud elegida, con "Cambiar" (hoja con las demás);
   - "Compara las ofertas" vacío hasta HU-16.
   - Va con la barra de pestañas y Perfil activo; sin nada atrás, "Regresar" lleva a Perfil.
7. **R7 · Perfil:** el renglón "Mis solicitudes" con "N activas · N ofertas" (o "Ninguna activa").

## Diseño
- `lib/features/purchase_requests/` (M-05):
  - `domain/`: `WantedRequest`, `WantedStatus`, `NewWanted` y la interfaz `WantedRepository`;
  - `data/`: `HttpWantedRepository`;
  - `presentation/`: `NeedDraft` + `needDraftProvider`, `myWantedProvider`, `needMatchesProvider`, `need_widgets.dart` y las cinco pantallas.
- `SellStepLayout` se reutiliza con `steps`, `heading`, `onSave` y `top` (los pasos de Vender no cambian).
- Ícono nuevo `target` (aviso de coincidencias); `longDate` ("Lunes 12 de octubre") junto a `shortDate`.
- **Diferencias con la maqueta:**
  - la vista previa del paso 3 dice "vie 9 oct · 1 pieza", como el HTML de la maqueta (su script quita la cantidad al redibujar);
  - en `Mis-solicitudes`, "Recomendadas" y las tarjetas de oferta llegan con HU-16 y HU-17.

## Contratos
Filas "M-05" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md): `POST /api/v1/wanted` (`ApiPaths.wanted`) y `GET /api/v1/wanted/mine` (`ApiPaths.myWanted`). Las coincidencias usan `GET /api/v1/products?q=` (HU-09).

## Tests
- `test/features/purchase_requests/wanted_data_test.dart`: la petición (título recortado, descripción vacía como `null`, fecha `yyyy-MM-dd`), el estado de cada solicitud, el error como `ApiFailure` y las fechas rápidas.
- `test/features/purchase_requests/need_flow_test.dart`: el flujo completo, el rechazo de la API, "Elegir fecha", Mis solicitudes (pestañas, Cambiar, vencidas, vacío) y Perfil.
- Capturas `necesidad-1`…`necesidad-3`, `necesidad-publicada` y `mis-solicitudes` (`tool/screenshots_test.dart`) comparadas con la maqueta.

## Criterios
- [x] El formulario captura producto, categoría, descripción, características, presupuesto, cantidad y fecha (R1–R3).
- [x] Si falta un dato obligatorio, se señala el campo; los rechazos de la API se avisan (R4).
- [x] La solicitud queda activa y se ve en Mis solicitudes y en Perfil (R5–R7).
- [x] `dart format` sin cambios · `flutter analyze` sin observaciones · `flutter test` 100 % · critic PASS.

## Límites
- `NOTE (HU-14)`: editar, cerrar y cancelar ("Guardar" del encabezado solo avisa).
- `NOTE (HU-15)`: el tablero "Se busca".
- `NOTE (HU-16)` y `NOTE (HU-17)`: ofertas, "Recomendadas", aceptar y rechazar.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador) · 09-Nov-2026 (implementación)
- **Detalle:** clases `Wanted*` como en la API (`Modules/PurchaseRequests`); fechas de "Elegir fecha" como la maqueta en lugar de un calendario.
