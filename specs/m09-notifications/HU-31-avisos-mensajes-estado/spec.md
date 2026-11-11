# HU-31 — Avisos de mensajes y cambios de estado (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-31 / SCRUM-49 / Sprint 4 (9 – 20 nov 2026) / M-09 / [musubi-api:HU-31](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m09-notifications/HU-31-avisos-mensajes-estado)

## Contexto
Jira (SCRUM-49): Como **usuario**, quiero **recibir notificaciones de mensajes nuevos y de cambios de estado en mis solicitudes y pedidos**, para **dar seguimiento a mis tratos**.

- Maqueta: `Notificaciones` y la campana de `Inicio` ("Notificaciones, 3 nuevas").
- Trazabilidad: RF-41, RF-42, RF-43 · CU-14 · L-16c, L-16f · RNF-15.
- Decisión de la usuaria (10-Nov-2026): FCM directo desde la API.

**Depende de:** `musubi-api:HU-31`, `02-01` (sesión), `HU-20` (chat).

## Requisitos
1. **R1 · Registro del teléfono:** con sesión y permiso, la app registra el ID de instalación de Firebase (FID: `register()` y `onRegistered`; el token de registro quedó obsoleto) en `PUT /notifications/devices`, también cada vez que cambia. Al cerrar sesión, `unregister()`.
2. **R2 · Permiso en contexto (L-16f):** no se pide al abrir la app. La primera vez que la persona manda un mensaje o publica una solicitud, "¿Te avisamos?" explica para qué; "Activar avisos" pide el permiso de Android 13+ y "Ahora no" no vuelve a preguntar.
3. **R3 · Tocar un push:** abre el chat, el pedido o "Mis solicitudes" y marca leído el aviso.
4. **R4 · Con la app abierta:** el aviso sale como snack con "Ver", salvo en el chat que ya está abierto.
5. **R5 · `Notificaciones` (RF-43):** pestañas Todas, Coincidencias, Pedidos y Solicitudes; "Marcar leídas"; grupos Hoy, Ayer y Antes; los no leídos con fondo rosa y punto rojo; tocar uno lo abre y lo marca leído. La campana de `Inicio` cuenta los no leídos.
6. **R6 · Sin Firebase (RNF-15):** sin `google-services.json` la app compila y funciona igual, sin push.

## Diseño
- Feature `lib/features/notifications/`: `domain/` (`AppNotification`, `PushOpen`, `NotificationRepository`), `data/` (`HttpNotificationRepository`, `PushService` con `FirebasePushService`) y `presentation/` (`PushCoordinator`, `NotificationsScreen`, `askForPushInContext`).
- `MusubiApp` enciende el coordinador y le da un `scaffoldMessengerKey` para el snack.
- Android: canal "musubi" (`MainActivity`), `POST_NOTIFICATIONS`, `firebase_messaging_installation_id_enabled` y el plugin de Google Services solo si existe `google-services.json`. En GitHub, el archivo sale del secreto `GOOGLE_SERVICES_JSON_B64`.
- Paquetes nuevos: `firebase_core` y `firebase_messaging` (ya previstos en 00-01: "Firebase Messaging → HU-31").

## Contratos
Filas "M-09" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), enlazadas desde `lib/core/network/api_paths.dart`.

## Tests
`test/features/notifications/notification_flow_test.dart`, `test/features/notifications/notification_data_test.dart`: mapeo y rutas; la lista agrupada y por pestaña; tocar un aviso; "Marcar leídas"; sin avisos; la campana; registrar con permiso y al cambiar el ID; sin permiso no pregunta al abrir; sin Firebase; la pregunta en contexto ("Activar avisos" y "Ahora no"); tocar un push; el snack con la app abierta y en el mismo chat; cerrar sesión. `test/security/android_config_test.dart`: `POST_NOTIFICATIONS` aprobado.

## Criterios
- [x] Se notifica cada mensaje nuevo (RF-42; R1, R3, R4).
- [x] Se notifican los cambios de estado de solicitudes y pedidos (RF-41; la API los da, R3 y R5 los muestran).
- [x] El centro de notificaciones muestra el historial; al seleccionar uno se abre el elemento relacionado (RF-43, R5).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- La prueba real del push necesita el proyecto de Firebase (`google-services.json` y la llave de la cuenta de servicio en la API).
- `NOTE (HU-54)`: apagar avisos por tipo en Ajustes.
- `NOTE (HU-29/30)`: la pestaña "Coincidencias" se llena con esas HU.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 11-Nov-2026 (detallado e implementado)
- **Detalle:** FID en lugar del token obsoleto, permiso en contexto y la pantalla de la maqueta.
