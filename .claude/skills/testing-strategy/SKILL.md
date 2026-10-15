---
name: testing-strategy
description: Qué pruebas cubren qué en musubi-app (unit, widget, integration_test), cómo aislar la red y Riverpod, y reglas anti-flakiness. Úsala al planear las pruebas de una HU o al auditar cobertura.
---

## Propósito
Que cada capa tenga su prueba, sin red real y con conteos reales.

## Cuándo usarla
Al escribir la sección `Tests` de una spec, al crear pruebas y al auditar.

## Precondiciones
`flutter pub get`; análisis limpio.

## Pasos
1. **Matriz capa → prueba:**

| Capa | Prueba | Herramienta | Ejemplo |
|---|---|---|---|
| `core/config` | Unit: validación de cada regla y ambas ramas | `flutter_test` | `test/core/config/app_config_test.dart` |
| `features/*/data` | Unit: parseo y traducción de errores (2xx, otra forma, 5xx, sin red, timeout) | `FakeHttpAdapter` (sin red) | `test/features/status/data/http_status_repository_test.dart` |
| `features/*/presentation` (estado) | Unit: providers con overrides | `ProviderContainer.test` | `status_providers_test.dart` |
| `features/*/presentation` (UI) | Widget: un caso por estado (cargando, datos, vacío, error + reintentar) | `ProviderScope(overrides: …)` + fakes | `home_screen_test.dart` |
| Flujos de punta a punta | `integration_test/` en un emulador o dispositivo | `integration_test` | `integration_test/app_smoke_test.dart` |

2. **Sin red real:** las pruebas de data usan `test/helpers/fake_http_adapter.dart`; las de UI usan fakes del repositorio (`test/helpers/`).
3. **Riverpod 3:** en `ProviderContainer.test`, agregar `..listen(provider, (_, _) {})` antes de leer un provider `autoDispose` (00-04 #17).
4. **Estados de carga:** un fake que nunca completa (`FakeStatusRepository.pending()`) en lugar de `Future.delayed` (evita timers pendientes).
5. **Frontera y ambas ramas:** p. ej. HTTPS obligatorio fuera de dev **y** HTTP permitido en dev hacia 10.0.2.2.
6. **Accesibilidad (RNF-20):** `expect(tester, meetsGuideline(textContrastGuideline))` en las pantallas nuevas desde `02-01`.
7. **Tamaños (RNF-27):** `tester.view.physicalSize` con un teléfono pequeño y una tablet en las pantallas principales (`02-01`).
8. **RNF-25:** las HU de M-01, M-06 y M-08 llevan pruebas de data, estado y UI obligatoriamente.

## Checklist
Las 3 capas probadas · sin red · fakes en `test/helpers/` · conteos reales en spec y PR.

## Criterios de done
`flutter test` en verde (conteo citado); cobertura generada con `flutter test --coverage` (umbral "🎯 Por medir", `02-01`).

## Límites/trampas
- `integration_test` no corre en el CI de PR (requiere un dispositivo).
- No usar `pumpAndSettle` con indicadores infinitos (`CircularProgressIndicator` nunca "se asienta"): usar `pump()`.

## Referencias
`00-03`, `00-04`, `test/helpers/`, `lib/features/status/`.
