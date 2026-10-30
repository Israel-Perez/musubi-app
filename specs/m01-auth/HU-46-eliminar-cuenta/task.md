# HU-46 — Eliminar mi cuenta y mis datos (tareas)

## T1 — Datos
- **Qué:** `AccountRepository`, `HttpAccountRepository` y `ApiPaths.accountDelete`.
- **Verificar:** `http_account_repository_test.dart` (2).
- **Estado:** ✅ Hecho (30-Oct-2026).

## T2 — Pantalla y flujo
- **Qué:** `PrivacyScreen`, `DeleteAccountButton`, `ConfirmPasswordSheet`, la ruta `/ajustes/privacidad`, la fila en `Ajustes` y `MusubiTopBar.titleAtStart`.
- **Verificar:** `delete_account_flow_test.dart` (5) y la captura `privacidad` contra la maqueta.
- **Estado:** ✅ Hecho (30-Oct-2026).

## T3 — Versión y publicación
- **Qué:** `0.3.0+4` y su fila en `docs/versionado.md`. Subir a la prueba cerrada de Google Play después del despliegue del back.
- **Estado:** 🚧 La versión está lista; falta subirla.

## Pendientes
- `NOTE (HU-04)`: "Quién te ve" y "Cambiar contraseña".
- `NOTE (HU-28)`: "Usuarios bloqueados".
