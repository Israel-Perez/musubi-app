# HU-67 — Pedir una reseña de la app en Google Play tras el primer pedido (plan, app)

## 1. Componentes
- **`lib/core/platform/app_review.dart`:** interfaz `AppReview`, `PlatformAppReview` con `MethodChannel('musubi/review')`, `ReviewAskStore`, `SecureReviewAskStore` y `ReviewPrompter`, más sus providers. Sigue el patrón de `lib/core/platform/email_inbox.dart`.
- **`android/app/src/main/kotlin/com/musubi/app/MainActivity.kt`:** segundo canal `musubi/review` con `ReviewManagerFactory` de Play Core.
- **`android/app/build.gradle.kts`:** `implementation("com.google.android.play:review:2.0.2")`.
- **`lib/features/reputation/presentation/rate_screen.dart`:** aviso al enviar la calificación, a "Ahora no" y a la X.
- **Pruebas:** `test/core/platform/app_review_test.dart`, `test/features/reputation/rate_flow_test.dart`, `test/features/orders/order_flow_test.dart` y `test/helpers/fake_app_review.dart`.

## 2. Decisiones
- **D1 · Canal nativo, no paquete:** se descarta `in_app_review` 2.0.12 (MIT, 160/160 puntos, 2,460 likes, 1.47M descargas/30 días al 14-Nov-2026) porque su `android/build.gradle` usa un buildscript con AGP 8.7.3, Kotlin 2.1.0 y `kotlinOptions`, contra AGP 9.1.0, Gradle 9.3.1 y Kotlin 2.4.0 de la app; además agregaría un paquete Dart fuera del stack y el mismo Play Core por debajo. El canal sigue el precedente de `musubi/email`.
- **D2 · Ambos roles:** la reseña es de la app, no del papel en el pedido; comprador y vendedor completan la transacción (decisión de la usuaria, 14-Nov-2026).
- **D3 · La X cuenta como "Ahora no":** cerrar sin calificar es una negativa; el pedido ya está completado (decisión de la usuaria, 14-Nov-2026).
- **D4 · 90 días por dispositivo:** la fecha vive en `flutter_secure_storage` (`musubi.review_asked_at`), como el aviso de IA y el permiso de push. Se guarda solo si Play aceptó el flujo, para poder reintentar si el teléfono no tenía Play.
- **D5 · Sin conteo en la API:** "primer pedido" es el primer aviso en este dispositivo. Evita una petición extra (`GET /orders/mine`) y una dependencia de red en un momento de celebración; queda `NOTE (HU-67)` con la ruta de mejora.
- **D6 · Sin pantalla ni versión:** no se toca la maqueta ni `pubspec.yaml`; la app se publica en el lote del sprint.

## 3. Excepciones al stack
- **Paquete:** `com.google.android.play:review:2.0.2` (Maven de Google; última versión al 18-Oct-2024; licencia *Play Core SDK Terms of Service*, <https://developer.android.com/guide/playcore/license>). Es una dependencia de Android, no un paquete Dart: no cambia `pubspec.yaml` ni los criterios de 00-01 sobre paquetes pub.
- **Mantenimiento:** Google publica Play Core; la API de In-App Review es la vía oficial de Play. Sin permisos nuevos y sin llaves privadas en el cliente.
- **Alternativa descartada:** `in_app_review` 2.0.12 (ver D1). También se descartó abrir la ficha con un `Intent` (`market://`), porque no es la In-App Review API y no cumple el criterio de Jira.
- **Remoción:** borrar el canal `musubi/review` de `MainActivity.kt`, la línea de Gradle y `lib/core/platform/app_review.dart`; el único dato persistido es la fecha de `musubi.review_asked_at`, que deja de leerse.

## 4. Guardarraíles
- Sin `catch` vacío: la falla de Play se traga con `debugPrint` sin PII y la app sigue (RNF-15).
- Sin permisos nuevos, sin tráfico en claro, sin datos de la persona a Google (la API de Play no recibe nada de Musubi).
- La UI no espera el resultado: `unawaited`; la navegación y el aviso de "¡Gracias!" no se bloquean.
- Pantalla → `reviewPrompterProvider`; el canal nativo solo lo usa `PlatformAppReview`.
- No se agrega nada a `pubspec.yaml` ni a `docs/versionado.md`.

## 5. Validación
- `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos --fatal-warnings`, `flutter test`, `pwsh scripts/critic-guardrails.ps1`, Semgrep.
- `flutter build apk --debug --dart-define-from-file=config/dev.example.json` y `aapt2 dump badging`: paquete, `targetSdkVersion:'36'` y permisos sin cambios.
- Prueba manual en una pista interna o cerrada de Play: el sheet aparece una vez y no en local (documentado en `docs/play/README.md`).
- `security-reviewer` antes del push y `traceability-clerk` al cerrar.

## 6. Secuencia
1. **T1 — Plataforma:** Gradle + canal + build. Si el build falla por AGP/Gradle, documentar y evaluar el plan B antes de seguir.
2. **T2 — Servicio y política:** `app_review.dart` + unit tests.
3. **T3 — Pantalla:** `rate_screen.dart` + widget tests.
4. **T4 — Documentación:** specs, `docs/trazabilidad.md`, `00-01`/§6, `AGENTS.md` §5, `docs/play/README.md` y `Memoria.md`.
5. **T5 — Gates y prueba manual.**
6. **T6 — PR y cierre.**

## 7. Subagentes
- `slice-scaffolder` no aplica: no hay pantalla, modelo ni repositorio nuevos; el cambio es un efecto de plataforma sobre `Calificar`.
- `security-reviewer`: revisión de solo lectura antes del push.
- `traceability-clerk`: al cerrar, para verificar spec ↔ código ↔ test ↔ Jira.

## 8. Estado
- 15-Nov-2026: T1–T4 hechos. `flutter test` 711/711 (16 nuevas, rebasado sobre `origin/main` con HU-12), analyze 0, format 0, critic PASS (19 archivos), APK debug `√ Built` y `aapt2` sin permisos nuevos. `security-reviewer` PASS (0 bloqueantes; W1/W2 corregidos, W3 endurecido, W4 documentado).
- Pendientes: prueba manual en pista interna y PR.
