# HU-67 — Pedir una reseña de la app en Google Play tras el primer pedido (tareas app)

## T1 — Plataforma
- [x] Agregar `implementation("com.google.android.play:review:2.0.2")` en `android/app/build.gradle.kts`.
- [x] Agregar el canal `musubi/review` en `MainActivity.kt` (`requestReviewFlow` → `launchReviewFlow`; `false` si no se puede).
- [x] Verificar `flutter build apk --debug --dart-define-from-file=config/dev.example.json` y `aapt2 dump badging` (sin permisos nuevos).
- **Verificación:** APK `√ Built` (15-Nov-2026); `com.musubi.app`, `targetSdkVersion:'36'`, sin permisos nuevos; `test/security/android_config_test.dart` en verde.
- **Resultado:** Play Core 2.0.2 compila con AGP 9.1.0/Gradle 9.3.1; no hizo falta el plan B.

## T2 — Servicio y política
- [x] `lib/core/platform/app_review.dart`: `AppReview`, `PlatformAppReview`, `ReviewAskStore`, `SecureReviewAskStore`, `ReviewPrompter` y providers.
- [x] `test/helpers/fake_app_review.dart` (fake de `AppReview` y store en memoria).
- [x] `test/core/platform/app_review_test.dart`: nunca pedido; 89 días no; 90 sí; servicio `false` no marca; excepción no propaga; pedido no completado no pide.
- **Verificación:** 6/6 en verde.
- **Hecho:** `NOTE (HU-67)` en `ReviewPrompter` por el "primer pedido" medido por dispositivo.

## T3 — Pantalla
- [x] En `rate_screen.dart`, pedir la reseña al enviar la calificación, a "Ahora no" y a la X; no pedir en `ratings.already_rated` ni en `ratings.expired`.
- [x] `test/features/reputation/rate_flow_test.dart`: envío, "Ahora no", X, una sola vez en 90 días, fallo al enviar (ni al cerrar después), fallo del servicio, vendedor, pedido cancelado y "mientras envía, X y Ahora no no cierran" (W2).
- [x] `test/features/orders/order_flow_test.dart`: completar un pedido y "Ahora no" pide la reseña (también quien vende).
- **Verificación:** 10 casos nuevos de UI en verde; la navegación y el aviso de gracias siguen ante una falla del servicio.
- **Pendiente:** confirmar que la hoja no se abre durante `flutter run` local (es normal; ver `docs/play/README.md`).

## T4 — Documentación y trazabilidad
- [x] `specs/m08-orders/HU-67-resena-primer-pedido/` con `spec.md`, `plan.md` y `task.md`.
- [x] Fila HU-67 en `docs/trazabilidad.md` (total 59, "Por asignar: 4") y nota de nacimiento.
- [x] Excepción de Play Core en `specs/phase-00-constitution/00-01-principles-stack/spec.md` y `.specify/memory/constitution.md` §6.
- [x] Línea de HU-67 en `AGENTS.md` §5 y nota de prueba en pista interna en `docs/play/README.md`.
- [x] Entrada en `Memoria.md` (T55) con la implementación y la evidencia.

## T5 — Gates y prueba manual
- [x] `dart format --output=none --set-exit-if-changed .` sin cambios (282 archivos).
- [x] `flutter analyze --fatal-infos --fatal-warnings` 0.
- [x] `flutter test` 711/711 (16 nuevas; rebasado sobre `origin/main` con HU-12).
- [x] `pwsh scripts/critic-guardrails.ps1` PASS (18 archivos, 0 avisos); Semgrep queda para el CI (no está instalado en local).
- [x] `security-reviewer` PASS (0 bloqueantes; W1/W2 corregidos, W3 endurecido, W4 documentado).
- [ ] Prueba manual en pista interna/cerrada: el sheet aparece una vez; en local no aparece.
- **Pendiente:** la prueba manual la hace la usuaria; sin ella no se marca "Aprobado".

## T6 — Cierre
- [x] Conciliar `spec.md`, `plan.md` y `task.md` con lo implementado (estado "Borrador con evidencia").
- [x] `traceability-clerk` OK (segunda pasada, sin drift bloqueante).
- [ ] PR `feature/SCRUM-107-resena-primer-pedido` con la clave Jira, los conteos reales y el checklist de la plantilla.
