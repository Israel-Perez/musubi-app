# plan.md — 01-02 Estructura de la app

1. **Componentes:** `lib/main.dart`, `lib/app/`, `lib/core/theme/`, `lib/features/README.md`.
2. **Decisiones:**
   - Feature-first con 3 capas por módulo (`domain` sin dependencias de UI ni de Dio) para reflejar los módulos del back y poder probar cada capa por separado.
   - Riverpod con providers simples (sin codegen) para reducir la curva de aprendizaje del equipo.
   - `appConfigProvider` sin valor por defecto (lanza si no se sobrescribe): obliga a configurar en `main` y en las pruebas.
3. **Guardarraíles:** la UI no importa `dio`; `lib/` sin `http://`, `print` ni `TODO`.
4. **Validación:** analyze + widget tests.
5. **Secuencia:** tema → router → app → main → README de features.
