# 00-03 — Requerimientos no funcionales (musubi-app)

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) · contraparte: `musubi-api:00-03`

## Contexto
Umbrales medibles de los RNF del MVP que aplican al front, más los NFR técnicos de calidad. La columna **Aplica** indica si el RNF también está en `musubi-api:00-03`, donde cada repo verifica su lado. **Depende de**: `00-01`.

## Requisitos
1. Cada NFR tiene métrica o umbral, estado, herramienta y comando de verificación.
2. Los umbrales no medidos se declaran como "🎯 Objetivo (Por medir)" o "🎯 Objetivo (Por definir con el PO)", con su spec dueña.
3. Los umbrales se fijan midiendo (principio 6).

## Diseño

### RNF del MVP que aplican al front

| NFR | Categoría | Aplica | Métrica / Umbral | Estado del umbral | Herramienta | Comando / verificación |
|---|---|---|---|---|---|---|
| RNF-01 Credenciales cifradas | Seguridad | Ambos | El token de sesión solo en almacenamiento seguro; la contraseña nunca se guarda en el dispositivo | 🎯 Objetivo (Por medir) — HU-02 | `flutter_secure_storage` + unit test | `NOTE (HU-02)` |
| RNF-02 Comunicación cifrada | Seguridad | Ambos | HTTPS fuera de dev; release sin tráfico en claro; en dev, HTTP solo a `10.0.2.2` | 📈 Medido real (configuración) | `AppConfig.parse` + `network_security_config` | `test/core/config/app_config_test.dart`; `aapt2 dump xmltree` del APK |
| RNF-05 Datos mínimos y aviso de privacidad | Privacidad | Ambos | Aviso aceptado antes de crear la cuenta; formularios sin campos innecesarios | 🎯 Objetivo (Por medir) — HU-47 | Widget test | Pruebas de HU-47 |
| RNF-06 IA solo a petición | Privacidad | Ambos | El resumen de IA solo se solicita con una acción explícita del usuario | 🎯 Objetivo (Por medir) — HU-32 | Widget test | Pruebas de HU-32 |
| RNF-08 Eliminación de cuenta y datos | Privacidad | Ambos | Flujo de eliminación con confirmación; se borra el token local | 🎯 Objetivo (Por medir) — HU-46 | Widget + unit test | Pruebas de HU-46 |
| RNF-09 Búsquedas en tiempo aceptable | Rendimiento | Ambos | Resultados visibles ≤ N s (por definir) con indicador de carga | 🎯 Objetivo (Por definir con el PO) | `integration_test` + medición en el dispositivo | `NOTE (HU-09)` |
| RNF-10 Chat casi en tiempo real | Rendimiento | Ambos | Mensaje visible en el otro dispositivo ≤ N s (por definir) | 🎯 Objetivo (Por definir con el PO) | Cliente SignalR | `NOTE (HU-20)` |
| RNF-12 Indicador durante la IA | Rendimiento | Front | Indicador visible mientras se genera el resumen | 🎯 Objetivo (Por medir) — HU-32 | Widget test | Pruebas de HU-32 (el patrón ya existe en `home_screen_test.dart`: estado "Conectando") |
| RNF-13 Fotos optimizadas antes de subir | Rendimiento | Ambos | Foto comprimida ≤ N KB antes de enviarla (por definir); el back rechaza más de 10 MB | 🎯 Objetivo (Por definir con el PO) — HU-06 | Unit test del compresor | Pruebas de HU-06 |
| RNF-15 Degradación de IA/ML | Disponibilidad | Ambos | Con la IA o el ML caídos, la pantalla muestra un mensaje y el resto sigue usable | 🎯 Objetivo (Por medir) — HU-32, HU-35 | Widget test con un fake que falla | Pruebas de HU-32/HU-35; patrón probado en `home_screen_test.dart` (API caída → mensaje + reintentar) |
| RNF-17 Publicar en pocos pasos | Usabilidad | Front | Publicar un producto en ≤ N pantallas/pasos (por definir) | 🎯 Objetivo (Por definir con el PO) — HU-06 | Revisión de UX + `integration_test` | Pruebas de HU-06 |
| RNF-18 Interfaz en español con errores claros | Usabilidad | Ambos | Localización `es-MX`; errores de red traducidos sin detalle técnico | 📈 Medido real (base) | `flutter_localizations` + `networkErrorMessage` | `test/features/status/data/http_status_repository_test.dart` |
| RNF-19 Distinguir productos de solicitudes | Usabilidad | Front | Productos y solicitudes con un estilo visual distinto (color/ícono/etiqueta) | 🎯 Objetivo (Por medir) — HU-15 | Widget/golden test | Pruebas de HU-15 |
| RNF-20 Legibilidad y contraste | Usabilidad | Front | Contraste WCAG AA (≥ 4.5:1 en el texto) con la paleta de la maqueta en modo claro y oscuro; soporte de escala de fuente | 📈 Medido real (9 pares × 2 modos, 21-Oct-2026) / 🎯 escala de fuente — por HU | Cálculo de contraste + `meetsGuideline(textContrastGuideline)` | `test/core/theme/app_theme_test.dart`, `test/core/widgets/widgets_test.dart` |
| RNF-21 Más universidades | Escalabilidad | Ambos | Ningún dominio ni nombre de universidad fijo en `lib/` | 🎯 Objetivo (Por medir) — HU-03 | Revisión + critic | Pruebas de HU-03 |
| RNF-23 Organización por módulos | Mantenibilidad | Ambos | `lib/features/<modulo>/` según `docs/modulos.md` | 📈 Medido real (estructura) | `lib/features/README.md` | Revisión de la estructura en cada PR |
| RNF-24 Versiones, estándares y documentación | Mantenibilidad | Ambos | CI verde en cada PR; specs con la plantilla | 📈 Medido real | GitHub Actions | `.github/workflows/ci-pr.yml` |
| RNF-25 Pruebas en auth, coincidencias y pedidos | Mantenibilidad | Ambos | Cada HU de M-01, M-06 y M-08 con unit + widget tests | 🎯 Objetivo (Por medir) | `flutter_test` | Suites por HU |
| RNF-26 Plataformas | Compatibilidad | Front | Android primero: `minSdk` 24, `targetSdk` 36 | 📈 Medido real | `aapt2 dump badging` | `targetSdkVersion:'36'` (15-Oct-2026) |
| RNF-27 Distintos tamaños de pantalla | Compatibilidad | Front | Sin overflow de 360×640 dp a tablets de 10" (la maqueta está a 390×844); área táctil ≥ 44 dp | 📈 Medido real (área táctil en los componentes base) / 🎯 tamaños — por HU | Widget test con varios `physicalSize` + `meetsGuideline(androidTapTargetGuideline)` | `test/core/widgets/widgets_test.dart` |
| L-04 Fidelidad a la maqueta | Usabilidad | Front | Cada pantalla de `docs/maqueta/` implementada en su HU, sin funciones eliminadas | 🎯 Objetivo (Por medir) — por HU | Golden/widget test por pantalla + índice de `docs/maqueta/README.md` | Por HU |
| Versionamiento | Mantenibilidad | Front | `version` de `pubspec.yaml` SemVer con `versionCode` y alineada con `docs/versionado.md` | 📈 Medido real (20-Oct-2026) | `flutter_test` | `test/versioning_test.dart` |

No aplican al front (viven en `musubi-api:00-03`): RNF-03, RNF-04, RNF-07, RNF-11, RNF-14, RNF-16 y RNF-22 (el front solo los refleja en la UI).

### NFR técnicos

| NFR | Categoría | Métrica / Umbral | Estado del umbral | Herramienta | Comando / verificación |
|---|---|---|---|---|---|
| Formato | Calidad | 0 archivos por formatear | 📈 Medido real (15-Oct-2026) | `dart format` | `dart format --output=none --set-exit-if-changed .` |
| Análisis estático | Calidad | 0 observaciones (infos y warnings fatales) | 📈 Medido real | very_good_analysis 11 + modos estrictos | `flutter analyze --fatal-infos --fatal-warnings` |
| Pruebas | Calidad | 100 % en verde | 📈 Medido real (18/18) | `flutter_test` | `flutter test` |
| Cobertura | Mantenibilidad | ≥ N % de líneas en `lib/` | 🎯 Objetivo (Por medir) — 02-01 | `flutter test --coverage` (artefacto `coverage-lcov`) | job `test` del CI |
| Build Android | Compatibilidad | APK de debug compila con `targetSdk` 36 | 📈 Medido real | Gradle (AGP 9.1.0) + JDK 17 | `flutter build apk --debug --dart-define-from-file=config/dev.example.json` |
| Secretos fuera del APK | Seguridad | 0 secretos en el código, `config/` y CI | 📈 Medido real | critic B2 + Semgrep | `pwsh scripts/critic-guardrails.ps1`; `semgrep scan --config=auto --config=.semgrep/semgrep.yaml --error` |
| Dependencias | Seguridad | Actualizaciones semanales con `cooldown` de 7 días | 📈 Configurado | Dependabot (pub, github-actions) | `.github/dependabot.yml` |
| Monitoreo de fallos | Disponibilidad | Crash-free sessions ≥ N % en el piloto | 🎯 Objetivo (Por definir con el PO) | Firebase Crashlytics | `NOTE (HU-31)` |
| Seguridad del móvil (L-07) | Seguridad | Sin backup, solo permisos aprobados, sin tráfico en claro en release, token solo hacia la API | 📈 Medido real (21-Oct-2026) | flutter_test | `test/security/android_config_test.dart`, `test/core/session/auth_interceptor_test.dart` |
| Pruebas en dispositivo | Calidad | Flujos críticos en un emulador | 🎯 Objetivo (Por medir) | `integration_test` | `flutter test integration_test` (en un emulador o dispositivo) |

## Contratos
N/A — spec constitucional de umbrales.

## Tests
Los de la columna de verificación. Hoy hay pruebas reales para RNF-02, RNF-18, RNF-26 y los NFR técnicos de formato, análisis, pruebas y build.

## Criterios
- Cada fila cita una herramienta y un comando o una prueba (sin celdas vacías).
- Las filas "📈 Medido real" se pueden ejecutar hoy y están en verde (DoD de la plantilla inicial, Memoria.md, 15-Oct-2026).
- Las filas "🎯" declaran su spec dueña o "Por definir con el PO".

## Límites
Los umbrales "Por definir con el PO" esperan a que se designe el Product Owner. Las pruebas de rendimiento en dispositivo no corren en el CI de PR.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 20-Oct-2026
- **Detalle:** RNF-01…RNF-27 filtrados al front, más los NFR técnicos de Flutter. 20-Oct-2026 (SCRUM-66): fidelidad a la maqueta (L-04), área táctil de 44 dp y versionamiento medido.
