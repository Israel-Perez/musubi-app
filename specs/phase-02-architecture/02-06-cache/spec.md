# 02-06 — Caché de la app (tercer nivel)

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) / SCRUM-91 / S4 / — / [musubi-api:02-02](https://github.com/Israel-Perez/musubi-api/tree/main/specs/phase-02-architecture/02-02-cache-paginacion)

## Contexto
El documento de la materia pide caché a nivel base de datos, backend y frontend (requisito 9). Los dos primeros niveles viven en la API: cache-aside y caché de salida. La API ya responde `ETag` y `304` en categorías, vitrina y carreras, así que la app puede reutilizar lo que ya tiene en lugar de volver a bajarlo.

**Depende de:** `02-01` (cliente HTTP) y `musubi-api:02-02` (`ETag` y `304`).

## Requisitos
1. Cada `GET` del cliente con sesión (`dioProvider`) manda el `If-None-Match` de su copia, si la tiene.
2. Si la API responde `304`, la app entrega la copia como un `200` y no vuelve a bajar la lista.
3. **Una cuenta nunca recibe la copia de otra:** la llave lleva la identidad de la sesión (el correo, que no cambia al renovar el token) y la URL.
4. **Solo se guardan respuestas `200` de un `GET` con `ETag`**, con un tope de 64 copias: al llenarse sale la menos usada.
5. **Las fotos** usan la caché de imágenes de Flutter, que guarda en memoria las ya decodificadas.

## Diseño
- `lib/core/network/etag_cache.dart`: `EtagCache` (mapa ordenado con tope) y `EtagCacheInterceptor`.
- **`dioProvider`:** el interceptor va antes de `AuthInterceptor`. Un `401` sigue su camino normal (renovar la sesión).
- **`etagCacheProvider`:** una caché por proceso, en memoria.

## Contratos
Las filas de categorías, vitrina y carreras de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`ETag`, `304`). Sin rutas nuevas.

## Tests
`test/core/network/etag_cache_test.dart` (5):
- la segunda lectura manda el `ETag` y el `304` entrega la copia;
- un cambio en la API llega y se guarda;
- otra cuenta no recibe la copia;
- un `POST` o una respuesta sin `ETag` no se guardan;
- el tope saca la copia menos usada.

## Criterios
- `flutter test test/core/network/etag_cache_test.dart` en verde.
- `flutter analyze` sin observaciones y critic PASS.

## Límites
- **Solo en memoria:** al cerrar la app se pierde.
- **Sin caché local de favoritos:** HU-53 decidió el 08-Nov-2026 no tener modo sin conexión; SQLite y la caché local quedan fuera del MVP (requisito 16).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 03-Nov-2026
- **Detalle:** tercer nivel de la caché de `musubi-api:02-02` (SCRUM-91).
