# HU-60 — Encontrar coincidencias por significado y no solo por palabras

**HU / Jira / Sprint / Módulo / Contraparte:** HU-60 / SCRUM-100 / Sprint 5 (14 nov – 1 dic 2026) / M-06 / [musubi-api:HU-60](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m06-matching/HU-60-coincidencias-por-significado) (la lógica, el modelo y su evaluación)

## Contexto
Jira (SCRUM-100): Como **comprador o vendedor**, quiero **que las coincidencias entiendan lo que busco aunque use otras palabras**, para **que "calculadora científica" encuentre una "Casio fx-991"**.

- Pantallas: `Necesidad-publicada` ("Ya coinciden con lo que buscas", HU-18) y `Notificaciones` → "Coincidencias" (HU-19, HU-29). **No cambian:** la API devuelve las mismas formas, solo encuentra más.
- **Decisión (25-Nov-2026, para que la usuaria la revise):** los textos públicos (el nombre y la descripción de las publicaciones y lo que dicen las solicitudes) van a Gemini sin que nadie lo pida, sin datos de contacto. Se declaran en el aviso de privacidad y en Play.

**Depende de:** musubi-api HU-60 (`0.5.0-alpha.47`).

## Requisitos
1. **R1 · Sin cambios en la app:** ni pantallas ni llamadas nuevas; `GET /wanted/{id}/matches` y los avisos `wanted_match`/`product_match` conservan su forma.
2. **R2 · Aviso de privacidad (HU-47):** la sección "Inteligencia artificial" dice qué se envía para las coincidencias, que va sin contacto y que los vectores se borran con la cuenta.
3. **R3 · Play:** `docs/play/README.md` anota "Otro contenido generado por el usuario" como **compartido** con Google en el siguiente lote.

## Diseño
`assets/legal/aviso-de-privacidad.md` y `docs/play/README.md`.

## Contratos
Fila `GET /api/v1/wanted/{id}/matches` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (misma forma; "exacta" también por significado).

## Tests
- `test/features/auth/legal_documents_test.dart`: el aviso menciona las coincidencias por significado y el borrado de los vectores.
- Las pruebas de "Ya coinciden" (HU-18) y de los avisos siguen igual: la forma no cambió.

## Criterios
- [x] Las coincidencias entienden otras palabras → musubi-api `BySense_FindsMuchMoreThanByWords_WithBetterPrecision` (por palabras 4 de 21, por significado 18 de 21).
- [x] El aviso de privacidad lo dice → `aviso: IA solo a petición (RN-40) y revisión de reportes (RN-22)`.
- [x] "Seguridad de los datos" anotado para el siguiente lote → `docs/play/README.md`.

## Límites
- La landing muestra el aviso nuevo cuando se vuelve a desplegar después de fusionar.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 25-Nov-2026 (detallada e implementada)
