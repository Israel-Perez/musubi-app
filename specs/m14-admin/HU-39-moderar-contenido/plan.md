# plan.md — HU-39 Revisar reportes y moderar contenido (app, con HU-40)

## 1. Componentes
- Nuevo `lib/features/admin/` (ver `spec.md` → Diseño).
- `lib/core/session/session_tokens.dart`: `isAdmin` y `rolesOf`.
- `lib/core/network/api_paths.dart`: las 5 rutas de "M-14".
- `lib/app/router.dart`: `settingsAdmin` y `adminAccount(id)`, en `requiresSession` y con `startsWith` para la cuenta.
- `lib/features/profile/presentation/settings_screen.dart`: grupo "Administración" con "Reportes y cuentas".

## 2. Decisiones
- **El rol sale del token, no de lo guardado.** La app solo guarda los tokens (`SessionTokens`), y el `role` del JWT se renueva cada 15 minutos. Leerlo como el `sub` (sin verificar la firma: solo decide qué se muestra) evita guardar algo nuevo. La API responde 403 a quien no es administrador, así que mostrar la fila de más no abre nada.
- **Una pantalla con tres pestañas** ("Abiertos", "Revisados", "Suspendidas"), como `Notificaciones`. El reporte se abre en una hoja `UI.sheet`, como `reportSheet`, para que moderar se sienta igual que reportar.
- **"Procedente" según lo reportado.** Con una publicación es "Retirar publicación" y pide confirmación, porque no se deshace desde la app. Con una persona es "Es procedente" y con un problema general, "Marcar como atendido".
- **La nota es interna.** La hoja lo dice: quien reportó solo recibe "Revisamos tu reporte".

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
- Sin datos sensibles nuevos en el dispositivo (MASVS-STORAGE): el rol viaja en el token que ya existía.
- Errores con `ApiFailure.fromDio`, y el mensaje de la API se muestra tal cual.

## 5. Validación
- `flutter test` (ver `task.md`), `flutter analyze` y `dart format`.
- Prueba en el celular con una cuenta en `Admin:Emails` cuando se despliegue la API `0.5.0-alpha.38`.

## 6. Secuencia
1. Modelos, repositorio HTTP y rol del token.
2. Pantallas, rutas y fila de `Ajustes`.
3. Pruebas y documentación.
