---
name: api-contract
description: Cómo consumir en musubi-app una fila del catálogo canónico del back (musubi-api/docs/endpoints.md) sin duplicarlo, y cuándo usar un repositorio fake porque el endpoint aún no existe. Úsala al agregar o cambiar una llamada a la API.
---

## Propósito
Un solo contrato HTTP para los dos repos: el back es dueño del catálogo y el front lo **enlaza**, nunca lo copia.

## Cuándo usarla
Al consumir un endpoint nuevo, al cambiar uno existente o cuando la HU del front llega antes que la del back.

## Precondiciones
Acceso a `musubi-api` (repo hermano: <https://github.com/Israel-Perez/musubi-api>) y a la spec de la contraparte.

## Pasos
1. **Buscar la fila** del endpoint en `musubi-api/docs/endpoints.md` (método, ruta, auth, response, códigos, consumidor).
2. **Si existe:**
   - agregar la ruta a `lib/core/network/api_paths.dart` con un comentario que cite la fila y la spec (`musubi-api:HU-NN`);
   - en la spec del front, la sección `Contratos` **enlaza** la fila;
   - el modelo de `domain/` tiene solo los campos que la UI usa, y `data/` valida los tipos al parsear (forma inesperada → estado de error, no un crash);
   - cubrir en las pruebas de data cada código que la fila declara (2xx, 4xx relevantes, 5xx, sin red).
3. **Si no existe todavía:**
   - acordar la forma con el back en la spec de la contraparte (el back agrega la fila con el consumidor = esta HU);
   - crear `Fake<Recurso>Repository` en `lib/features/<modulo>/data/` con datos de ejemplo claramente ficticios y `NOTE (musubi-api:HU-NN)`;
   - el provider de producción usa el fake hasta que el endpoint exista; las pruebas fijan su contrato (skill `deferred-scope-fakes`).
4. **Al llegar el endpoint:** `grep -rn "NOTE (musubi-api:HU-NN)"`, cambiar el provider a `Http<Recurso>Repository`, borrar el fake de `lib/` (el de `test/helpers/` se queda) y actualizar las 4 capas.
5. **Si el back cambia una fila** (ruta, forma o códigos), el PR del back avisa al front; el front ajusta `ApiPaths`, el parseo y las pruebas en un PR con la misma clave Jira.

## Checklist
Fila citada en `ApiPaths` · contrato enlazado en la spec · pruebas por código · fake con `NOTE` si el endpoint no existe.

## Criterios de done
El agente `traceability-clerk` reporta OK en "Contrato"; `flutter test` en verde.

## Límites/trampas
- No copiar tablas, DTOs completos ni códigos del back a las specs del front: se pudren.
- El front no decide la autorización: muestra lo que el back permite y maneja el 401/403 que llegue.
- JSON camelCase (lo define el back); no asumir campos que la fila no declara.
- El fixture de `musubi-api/ContractTest/Fixtures/` es la evidencia de la forma JSON; si el front depende de un campo nuevo, pedir que se agregue al fixture.

## Referencias
`musubi-api/docs/endpoints.md`, `lib/core/network/api_paths.dart`, `lib/features/status/` (precedente 01-03), skills `deferred-scope-fakes`, `vertical-slice`.
