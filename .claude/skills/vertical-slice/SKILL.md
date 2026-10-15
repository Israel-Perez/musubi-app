---
name: vertical-slice
description: Entregar el lado front de una HU de MUSUBI como un slice vertical completo (modelo, repositorio, estado, pantalla, ruta y pruebas) dentro de lib/features/<modulo>. Úsala al implementar cualquier pantalla o flujo.
---

## Propósito
Que cada HU se entregue completa en un solo PR, dentro de su módulo, siguiendo el patrón probado en `lib/features/status/` (01-03).

## Cuándo usarla
En cada HU con UI, y al revisar si un PR está completo.

## Precondiciones
- Spec de la HU en Borrador con sus Contratos enlazados (skill `spec-first-writing`).
- Fila del endpoint en `musubi-api/docs/endpoints.md` o decisión de usar un fake (skill `deferred-scope-fakes`).

## Pasos
1. **Domain:** modelos inmutables (`final class`/`sealed` con `==`/`hashCode` o records) + la interfaz `<Recurso>Repository`. Sin Flutter UI ni Dio.
2. **Ruta de la API:** constante en `lib/core/network/api_paths.dart` que cita su fila (skill `api-contract`).
3. **Data:** `Http<Recurso>Repository` con `dioProvider`; parsea con tolerancia (valida tipos) y traduce `DioException` a estados de dominio con `networkErrorMessage` (RNF-18). Nunca deja escapar excepciones de red a la UI.
4. **Presentation / estado:** providers de Riverpod (`Provider` para el repositorio, `FutureProvider`/`Notifier` para el estado); reintentar = `ref.invalidate`.
5. **Presentation / UI:** pantalla con los estados cargando (indicador, RNF-12), datos, vacío y error (mensaje + reintentar); textos en español; productos y solicitudes visualmente distintos (RNF-19).
6. **Ruta** en `lib/app/router.dart`.
7. **Pruebas:** data (con `FakeHttpAdapter`), providers (`ProviderContainer.test` + override), widget test por estado (con un fake del repositorio).
8. **Conciliar** `spec/plan/task`, `docs/trazabilidad.md` (con la contraparte) y `Memoria.md`.

## Checklist
Domain + data + presentation + ruta de la API + ruta de navegación + pruebas de las 3 capas.

## Criterios de done
- `dart format` sin cambios, `flutter analyze --fatal-infos --fatal-warnings` sin observaciones, `flutter test` en verde.
- critic PASS y `security-reviewer` PASS.

## Límites/trampas
- No dividir en PRs por capa; no commitear la Fase A sin su Fase B.
- La UI nunca importa `dio`; un widget no decide autorización (el back responde 403).
- Comentarios que empiezan con "todo" en español rompen el análisis (`flutter_style_todos`).

## Referencias
`lib/features/README.md`, `lib/features/status/`, agente `slice-scaffolder`, skills `api-contract`, `deferred-scope-fakes`, `testing-strategy`, `critic-guardrails`.
