# 01-03 — Cliente de API y ping

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) · contraparte: [`musubi-api:01-03`](https://github.com/Israel-Perez/musubi-api/blob/main/specs/phase-01-foundation/01-03-startup-health/spec.md)

## Contexto
Primera conexión con el back: un repositorio detrás de una interfaz que consume `GET /api/v1/ping`, con un fake para pruebas, y una pantalla inicial que muestra el estado sin romperse si la API no responde. **Depende de**: `01-02`, `01-04`, `musubi-api:01-03`.

## Requisitos
1. `StatusRepository` (interfaz de `domain/`) con `check()` que **nunca** lanza por fallas de red.
2. `HttpStatusRepository` (`data/`) consume `ApiPaths.ping` con Dio: `pong` + versión → `ApiOnline`; otra forma, HTTP 5xx, sin conexión o timeout → `ApiOffline` con un mensaje en español (RNF-18).
3. `apiStatusProvider` (Riverpod) expone el estado; reintentar = invalidar el provider.
4. `HomeScreen` "Musubi" muestra tres estados: conectando (indicador), conectado (versión) y sin conexión (motivo + "Reintentar").
5. Cliente Dio con la URL de `AppConfig`, `Accept: application/json` y timeouts explícitos.

## Diseño
- `lib/core/network/api_paths.dart`: `ApiPaths.ping` cita su fila de `musubi-api/docs/endpoints.md` (skill `api-contract`).
- `lib/core/network/api_client.dart`: `createApiClient` + `dioProvider` (connect 5 s, receive 10 s — `NOTE (02-05)`: ajustar con mediciones; el interceptor del token llegó en `02-01`).
- `lib/core/errors/network_error_message.dart`: `DioExceptionType` → mensaje en español (switch exhaustivo).
- `lib/features/status/{domain,data,presentation}/`: `ApiStatus` (sealed: `ApiOnline` | `ApiOffline`), `StatusRepository`, `HttpStatusRepository`, `status_providers.dart`, `home_screen.dart`.
- El `catch` del repositorio **traduce** la excepción (no la traga): critic B4.

## Contratos
- Consume la fila `GET /api/v1/ping` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) — sección Plataforma. No se duplica la forma aquí; la verifica `ContractTest/PingContractTests.cs` del back con su fixture.

## Tests
- `test/features/status/data/http_status_repository_test.dart` (5): pong → `ApiOnline` + ruta y verbo del catálogo; otra forma → offline; 500 → mensaje de servidor; sin conexión → offline sin lanzar; timeout → mensaje de demora. Usa `test/helpers/fake_http_adapter.dart` (sin red).
- `test/features/status/presentation/status_providers_test.dart` (3): el provider expone el resultado; invalidar reintenta; sin override se usa `HttpStatusRepository` con la URL de `AppConfig`.
- `test/features/status/presentation/home_screen_test.dart` (3): conectando; conectado con versión; caído con motivo, y "Reintentar" vuelve a consultar sin excepciones.
- Fake: `test/helpers/fake_status_repository.dart`.

## Criterios
- `flutter test` → 18/18 (11 de esta spec).
- `pwsh scripts/critic-guardrails.ps1` → PASS (B4 no marca el `catch` traductor; el self-test confirma que sí marca un `catch` vacío).
- Con la API apagada, la app muestra "Sin conexión con el servidor" y no se cierra (widget test `API caida…`).

## Límites
Sin autenticación (`HU-02`) ni reintentos automáticos con backoff (`02-01`). La prueba contra la API real en un emulador queda en `integration_test` cuando haya un entorno compartido.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 15-Oct-2026
- **Detalle:** Patrón de referencia para los repositorios de cada módulo (interfaz + implementación Dio + fake + provider + estados de UI).
