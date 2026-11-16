# HU-67 — Pedir una reseña de la app en Google Play tras el primer pedido (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-67 / SCRUM-107 / Por asignar / M-08 / N/A (sin cambios en `musubi-api`; usa las filas de HU-23 y HU-27/45 de `docs/endpoints.md`)

## Contexto
Jira (SCRUM-107): como **equipo de Musubi**, queremos **pedir una reseña en Google Play cuando alguien completa su primer pedido**, para **tener más y mejores calificaciones en la tienda**.

- Trazabilidad: L-01 (descarga desde Google Play) · relacionada con HU-24 (pedido completado) y HU-27/45 (`Calificar`).
- Maqueta: **no tiene pantalla**. El aviso lo pinta Google Play (In-App Review API), no Musubi; el lineamiento 4 no aplica a una hoja del sistema.
- **Depende de:** `02-02` (publicación y pistas de Google Play), `HU-24` (completar el pedido), `HU-27/45` (`Calificar`) y `00-01` (excepción de plataforma por Play Core).

## Requisitos
1. **R1 · Momento:** al terminar `Calificar` de un pedido **completado**, se pide la reseña, tanto al enviar la calificación como al tocar "Ahora no" o la X.
2. **R2 · Una vez cada 90 días:** la fecha del último intento se guarda en el almacén cifrado del dispositivo; con menos de 90 días no se vuelve a pedir. A los 90 días exactos sí.
3. **R3 · Solo pedidos completados:** nunca en pendiente, confirmado o cancelado; tampoco si la calificación falló y la pantalla sigue abierta. La comprobación es local (`Order.status == OrderStatus.completed`).
4. **R4 · Silencio (RNF-15):** si Play no está disponible (sin Play Store, sideload, cuota de Google) o la llamada falla, no se muestra aviso, snack ni error, y la navegación sigue. Si no se pudo pedir, no se guarda la fecha: se puede reintentar en otra ocasión.
5. **R5 · Sin contrato nuevo:** no se agrega endpoint, no se envía PII (RNF-07) y no cambia el estado del pedido ni de la calificación.
6. **R6 · Probable sin Play:** la llamada vive detrás de `AppReview` y las pruebas usan un fake; el canal nativo se prueba en una pista de Play.
7. **R7 · Ambos roles:** comprador y vendedor reciben el aviso cuando su pedido se completa (decisión del 14-Nov-2026).

## Diseño
- `lib/core/platform/app_review.dart`:
  - `AppReview` (`Future<bool> request()`) y `PlatformAppReview` (`MethodChannel('musubi/review')`, método `requestReview`), como `email_inbox.dart`;
  - `ReviewAskStore` (`askedAt`/`markAsked`) y `SecureReviewAskStore` (`musubi.review_asked_at`, ISO-8601 UTC);
  - `ReviewPrompter.maybeAsk(now, orderCompleted)` y los providers `appReviewProvider`, `reviewAskStoreProvider` y `reviewPrompterProvider`.
- `MainActivity.kt`: canal `musubi/review`; `ReviewManagerFactory` de Play Core, `requestReviewFlow` → `launchReviewFlow`; devuelve `false` si no se puede.
- `android/app/build.gradle.kts`: `implementation("com.google.android.play:review:2.0.2")`; sin permisos nuevos.
- `rate_screen.dart`: en `_send` exitoso y en `_close` (X y "Ahora no"), captura el prompter y el reloj (`clockProvider`) antes de navegar y llama `unawaited(maybeAsk(...))`. En el cierre por `ratings.already_rated` o `ratings.expired` no pide.
- No hay pantalla nueva ni cambios en la maqueta; la UI es la hoja del sistema de Google Play.

## Contratos
N/A — no hay endpoint, DTO ni evento nuevos. Se usan las filas de HU-23 (`GET /orders/{id}`) y HU-27/45 (`POST /orders/{id}/rating`) de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), sin copiarlas. La interfaz de plataforma es Play Core `review:2.0.2` (licencia *Play Core SDK Terms of Service*).

## Tests
- `test/core/platform/app_review_test.dart`: nunca pedido; 89 días no pide; 90 exactos sí; servicio `false` no marca; excepción no propaga; pedido no completado no pide.
- `test/features/reputation/rate_flow_test.dart`: enviar la primera calificación pide una vez; "Ahora no" pide; X pide; una segunda calificación dentro de 90 días no pide; si falla el envío no pide, ni al cerrar después con la X; si el servicio falla, el aviso de gracias y la navegación siguen; un pedido no completado no pide; ya calificado (error de la API) no pide; quien vende también la recibe; un pedido cancelado no pide; mientras envía, X y "Ahora no" no cierran ni piden.
- `test/features/orders/order_flow_test.dart`: el flujo completo "completar el pedido → Calificar → Ahora no" pide la reseña (R7, lado de quien vende).
- `test/helpers/fake_app_review.dart`: fake de `AppReview` y store en memoria.
- Sin red; el sheet real no se prueba en `flutter test` (solo en una pista de Play).

## Criterios
- [x] `dart format --output=none --set-exit-if-changed .` sin cambios (282 archivos, 15-Nov-2026).
- [x] `flutter analyze --fatal-infos --fatal-warnings` 0.
- [x] `flutter test` 765/765 (16 nuevas; rebasado sobre `origin/main` con HU-55 y HU-52) al 16-Nov-2026.
- [x] `pwsh scripts/critic-guardrails.ps1` PASS (18 archivos, 0 avisos); Semgrep lo corre el CI (no está instalado en local).
- [x] `flutter build apk --debug --dart-define-from-file=config/dev.example.json` → `√ Built`; `aapt2 dump badging` con `com.musubi.app`, `targetSdkVersion:'36'` y sin permisos nuevos; `test/security/android_config_test.dart` en verde.
- [x] 89 días no pide / 90 sí, con reloj fijo.
- [x] Pedido pendiente o cancelado no pide.
- [x] Play no disponible o error: sin aviso, sin excepción, la app sigue.
- [ ] Prueba manual en pista interna/cerrada: el sheet aparece una vez; en local no aparece (documentado en `docs/play/README.md`).
- [x] `security-reviewer` PASS (0 bloqueantes; W1/W2 corregidos, W3 endurecido, W4 documentado).
- [x] `traceability-clerk` OK (segunda pasada, sin drift bloqueante).

## Límites
- Google decide si muestra el sheet; no se puede automatizar ni saber si la persona calificó (solo que se pidió).
- "Primer pedido" se mide por el primer aviso en el dispositivo (o 90 días), no por un conteo de la API: no se agrega una petición ni se depende de la red. Si alguien ya tenía pedidos completados al instalar esta versión, el aviso sale en su siguiente calificación y luego espera 90 días.
- Es por dispositivo, no por cuenta (igual que el aviso de IA y el permiso de push).
- El canal nativo no se prueba en `flutter test`; la prueba real es en Play.
- Play Core se agregó como excepción de plataforma en `00-01` y la constitución §6 (licencia, mantenimiento, alternativa descartada y remoción).
- Sin cambio de versión de la app: se publica en el lote del sprint.
- `NOTE (HU-67)`: si se quiere el conteo exacto de "primer pedido", una HU posterior puede consultar `GET /orders/mine?tab=completed` (solo comprador) o agregar un contador en la API.
- La X cuenta como "Ahora no" (decisión del 14-Nov-2026).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 revisor distinto del autor)
- **Fecha:** 14-Nov-2026 (spec) · 15-Nov-2026 (implementación)
- **Detalle:** decisiones del 14-Nov-2026: canal nativo + Play Core, ambos roles, la X cuenta; sin cambio de API. Implementación del 15-Nov-2026: `ReviewPrompter` con 90 días por dispositivo, enganche en `RateScreen`; `flutter test` 711/711 (16 nuevas, rebasado sobre `origin/main` con HU-12), analyze 0, format 0, critic PASS, APK debug `√ Built` y `aapt2` sin permisos nuevos. `security-reviewer` PASS (0 bloqueantes; W1/W2 corregidos, W3 endurecido, W4 documentado) y `traceability-clerk` OK. Pendientes: prueba manual en pista interna y PR. La app no sube de versión (se publica en lote).
