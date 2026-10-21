# 01-02 — Estructura de la app (shell)

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) · contraparte: `musubi-api:01-02`

## Contexto
Esqueleto de la app sobre el que se montan los 14 módulos: raíz, estado, navegación, tema e idioma. **Depende de**: `01-01`.

## Requisitos
1. Estructura feature-first: `lib/app/`, `lib/core/`, `lib/features/<modulo>/{domain,data,presentation}`, con la convención en `lib/features/README.md` y sin carpetas vacías.
2. Estado con Riverpod (`ProviderScope` en `main`); dependencias inyectadas por provider y sobrescribibles en pruebas.
3. Navegación con go_router (`routerProvider`), con la ruta inicial `/`.
4. Material 3 con tema claro y oscuro; idioma español `es-MX` (RNF-18).

## Diseño

| Archivo | Responsabilidad |
|---|---|
| `lib/main.dart` | Valida la configuración (01-04) y arranca `ProviderScope` con el override de `appConfigProvider` |
| `lib/app/musubi_app.dart` | `MaterialApp.router`: tema, `es-MX`, `GlobalMaterialLocalizations`, `routerConfig` |
| `lib/app/router.dart` | `AppRoutes` + `routerProvider` (se libera con `ref.onDispose`) |
| `lib/core/theme/app_theme.dart` | Tema de la maqueta (02-01): tokens, tipografía, componentes y contraste AA |
| `lib/features/README.md` | Convención de capas y reglas (UI → provider → interfaz de repositorio) |

Pendientes: guardas de sesión, navegación por módulos y componentes base, resueltos en `02-01`; Crashlytics (`NOTE (HU-31)`), FCM (`NOTE (HU-31)`), SignalR (`NOTE (HU-20)`).

## Contratos
N/A (sin endpoints nuevos; el contrato con el back está en 01-03).

## Tests
- `test/features/status/presentation/home_screen_test.dart` (3): la pantalla inicial se renderiza dentro de `ProviderScope` + `MaterialApp`.
- `integration_test/app_smoke_test.dart` (1, en dispositivo): `MusubiApp` completa arranca y muestra "Musubi".

## Criterios
- `flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`.
- `flutter test` → 18/18 (15-Oct-2026).
- Ninguna carpeta vacía en `lib/` (`find lib -type d -empty` → nada).

## Límites
Una sola ruta (`/`); los módulos agregan las suyas con su HU. El tema es provisional (`02-01`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 15-Oct-2026
- **Detalle:** Riverpod 3.4.3 sin codegen; go_router 18.1.0; localización `es-MX`.
