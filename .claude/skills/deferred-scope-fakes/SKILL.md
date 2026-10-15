---
name: deferred-scope-fakes
description: Avanzar una HU del front sin esperar endpoints o infraestructura futura (endpoint del back aún no listo, sesión, FCM, SignalR, Crashlytics) usando una interfaz con un fake reemplazable y NOTE (ID) trazables. Úsala cuando el alcance completo de una HU depende de otra spec aún no ejecutada.
---

## Propósito
Que ningún slice se bloquee por una dependencia pesada y que ningún pendiente se pierda.

## Cuándo usarla
- El endpoint del back aún no existe: repositorio fake con `NOTE (musubi-api:HU-NN)` (skill `api-contract`).
- La HU necesita un servicio que llega después (push → HU-31, chat en tiempo real → HU-20, Crashlytics → 02-01).
- La sesión aún no existe (token seguro → HU-02).

## Precondiciones
Acuerdo de alcance mínimo con el equipo y spec dueña del reemplazo identificada.

## Pasos
1. **Interfaz reemplazable** en `domain/` (`ListingsRepository`, `PushRegistrar`); el provider la expone y la UI solo ve el provider.
2. **Fake** (`Fake<Nombre>`) en `test/helpers/` para pruebas; si el endpoint aún no existe, otro fake en `lib/` es el que usa el provider de producción, con su `NOTE`. Precedente: `test/helpers/fake_status_repository.dart`.
3. Marcar cada diferido con `NOTE (ID)`, donde ID es la spec dueña (`NOTE (HU-31)`, `NOTE (02-01)`, `NOTE (musubi-api:HU-06)`). **Nunca `TODO`** (`todo: error` + critic B1 + Semgrep).
4. Registrar en las 4 capas (skill `traceability`).
5. **Pruebas que fijan el contrato del fake** (p. ej. "publica una vez", "si el proveedor falla, la HU degrada sin 5xx": RNF-15), para que la spec dueña las rompa a propósito al reemplazarlo.
6. **Al llegar a la spec dueña:** `grep -rn "NOTE (ID)"`, cambiar la implementación (el fake se queda para pruebas), volver a correr las suites y quitar los NOTE consumidos de las 4 capas.

## Checklist
Fake detrás de interfaz · `NOTE` con dueño · 0 `TODO` · pruebas del contrato del fake · 4 capas actualizadas.

## Criterios de done
El slice cierra en "🚧 Borrador con evidencia" en su alcance y nada queda pendiente sin dueño.

## Límites/trampas
- Solo se fakea **infraestructura** futura, nunca la lógica de negocio de la HU.
- Los fakes jamás contienen secretos, ni siquiera de prueba que parezcan reales.
- Un fake de producción debe ser visible para el usuario como "en construcción" o quedar detrás de una bandera de `config/`; nunca simular datos reales de otros usuarios.

## Referencias
Skill `traceability`; patrón `lib/features/status/` + `test/helpers/` (01-03); `00-04` (regla 5).
