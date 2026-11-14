# HU-66 — Plan de implementación (app)

## Componentes
- Datos: `InterestsRepository` + `HttpInterestsRepository` (`dioProvider`, con sesión).
- Estado: `interestsRepositoryProvider` y `myInterestsProvider` (sin reintento automático).
- Pantalla: `InterestsScreen` con `onboarding` (después de verificar) o sin él (`Ajustes`).
- Entradas: "Empezar a explorar" de `WelcomeScreen` y la fila "Mis intereses" de `SettingsScreen`.

## Decisiones
- **Después de `Verificacion-lista`, no en su lugar:** la maqueta tiene esa pantalla y no se le quitan funciones (lineamiento 4); "¿Qué te interesa?" va en medio y luego sigue el camino de antes (`returnPathProvider`).
- **Piezas de la maqueta, sin componentes nuevos:** `AuthLayout`, `NeedChip`, `MusubiButton` (`quiet` para "Ahora no") y `SettingsRow` con el corazón.
- **Una sola pantalla para los dos casos:** cambia el título ("¿Qué te interesa?" / "Mis intereses"), el botón ("Continuar" / "Guardar") y que solo al entrar se puede saltar.
- **"Continuar" sin elegir no llama a la API:** sería guardar una lista vacía que ya está vacía.
- **La fila de Ajustes dice cuántas, no cuáles:** cabe en un teléfono angosto y no obliga a pedir las categorías para pintar Ajustes.

## Guardarraíles
- Pantalla → provider → repositorio; los errores de red llegan como `ApiFailure` con mensaje en español.
- critic, `dart format`, `flutter analyze` y `flutter test`.

## Secuencia
1. Datos y `ApiPaths` → 2. Providers → 3. Pantalla y rutas → 4. Entradas (bienvenida y Ajustes) → 5. Pruebas y capturas → 6. Memoria.
