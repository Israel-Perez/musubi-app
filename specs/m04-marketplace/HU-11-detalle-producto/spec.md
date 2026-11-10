# HU-11 — Ver el detalle de un producto (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-11 / SCRUM-28 / Sprint 2 (12 – 23 oct 2026) / M-04 / [musubi-api:HU-11](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-11-detalle-producto)

## Contexto
Jira (SCRUM-28): Como **comprador**, quiero **ver el detalle de un producto**, para **decidir si me interesa antes de contactar al vendedor**.

- Maqueta: `Inicio-visitante`, `Se-busca-visitante`, `Producto-visitante`, `Visitante-modal`, `Producto`, `Perfil-vendedor`, `Chat-Valeria`.
- Trazabilidad: RF-14 · CU-06 · RNF-19.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-06`.

## Requisitos
1. El detalle muestra fotografías, descripción, precio, estado, cantidad, datos del vendedor y su reputación.
2. Desde el detalle se puede contactar al vendedor (chat) o comprar.
3. La interfaz distingue visualmente los productos publicados de las solicitudes de compra (RNF-19).

RNF que aplican: RNF-19.

## Diseño
- `ProductScreen` (maqueta `Producto` y `Producto-visitante`) en `/producto/:id`, público como la vitrina (HU-48):
  - carrusel de 360 con regresar, el campus con su insignia, compartir, guardar, los puntos y "1 / 4"; si está agotado, "Ya no está disponible";
  - precio (tachado si está agotado) y la pastilla "Usado · Como nuevo";
  - título, "Categoría · Publicado hace…";
  - tarjetas Estado / Disponibles ("Último", "Quedan 2") / Entrega;
  - "Apártalo 24 h sin pagar", la descripción y la tarjeta de quien vende;
  - barra: "Mensaje", "Apartar" y "Comprar". Si está agotado: "Avísame" y "Ver parecidos". Si es mía: "Ver mis productos".
- **Quien vende:**
  - con sesión, nombre, calificación, ventas y carrera, desde `GET /profiles/{id}` (`ProfileRepository.publicProfile`; la pantalla `Perfil-vendedor` completa es de HU-05);
  - sin sesión, la API no lo dice (RNF-05): "Estudiante verificado · Crea tu cuenta para ver quién lo vende". La maqueta del visitante muestra el nombre, pero se mantiene la regla de privacidad de la vitrina.
- **"Mensaje" y "Comprar"** abren el chat con quien vende (HU-20), como la maqueta. Sin sesión abren "Crea tu cuenta" con su motivo.
- **Inicio:** tocar un producto, con o sin sesión, abre su detalle.

## Contratos
Fila `GET /api/v1/products/{id}` (musubi-api `docs/endpoints.md`, M-03) y `GET /api/v1/profiles/{id}` (M-02), enlazadas desde `lib/core/network/api_paths.dart`.

## Tests
- `test/features/marketplace/product_screen_test.dart`:
  - con sesión (todo el detalle y la tarjeta de quien vende);
  - visitante (sin quien vende, y "Mensaje" pide la cuenta);
  - agotado;
  - mi publicación;
  - inexistente;
  - el repositorio HTTP.
- `test/features/chat/chat_flow_test.dart`: Inicio → detalle → "Mensaje" → chat.
- Capturas `producto` y `producto-visitante`, comparadas con `Producto`.

## Criterios
- [x] El detalle muestra fotografías, descripción, precio, estado, cantidad, datos del vendedor y su reputación → "con sesion: todo el detalle y la tarjeta de quien vende".
- [x] Desde el detalle se puede contactar al vendedor (chat) o comprar → "del producto en Inicio a su detalle y de ahi al chat". "Comprar" abre el chat hasta los pedidos: `NOTE (HU-23)`.
- [x] La interfaz distingue los productos publicados de las solicitudes de compra (RNF-19): precio grande, la pastilla de estado y las tarjetas de piezas y entrega, contra los boletos "Se busca" de Inicio.
- [x] `flutter analyze` sin observaciones, `flutter test` 292/292 y critic PASS.

## Límites
- "Apártalo 24 h" y "Apartar": `NOTE (HU-52)`.
- "Compara antes de comprar" y "Ver parecidos": `NOTE (HU-51)`.
- Guardar: HU-53 (spec detallada el 09-Nov-2026). "Avísame": `NOTE (HU-51)`.
- Compartir: fuera de alcance por ahora.
- El perfil de quien vende: `NOTE (HU-05)`.
- "Responde en ~1 h": fuera de alcance.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 06-Nov-2026
- **Detalle:** 29-Oct-2026: spec ligera (SCRUM-86). 06-Nov-2026 (SCRUM-28): implementada con musubi-api `0.5.0-alpha.3`.
