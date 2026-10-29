# HU-04 — Editar mi perfil (tareas)

## T1 — Dominio y datos
- **Crear:**
  - `features/profile/domain/*` y `data/http_profile_repository.dart`;
  - `test/helpers/fake_profile_repository.dart`.
- **Cambiar:** `api_paths.dart`.
- **Verificar:** `http_profile_repository_test.dart` y `profile_models_test.dart`.
- **Estado:** ⏳ Por hacer.

## T2 — Perfil y Ajustes
- **Crear:**
  - `profile_providers.dart`;
  - `settings_screen.dart`;
  - `ProfileAvatar`;
  - `app_version.dart`.
- **Cambiar:** `profile_screen.dart` (maqueta `Perfil`) y el saludo de Inicio.
- **Verificar:** `profile_flow_test.dart` (Perfil y Ajustes) y `versioning_test.dart`.
- **Estado:** ⏳ Por hacer.

## T3 — Datos personales y foto
- **Crear:** `personal_data_sheet.dart` (carrera y periodo), `profile_photo_sheet.dart` y `email_sheet.dart`.
- **Verificar:** `profile_flow_test.dart` (guardar, foto y correo).
- **Estado:** ⏳ Por hacer.

## T4 — Privacidad
- **Crear:** `privacy_screen.dart` y la ruta `/ajustes/privacidad`.
- **Verificar:** `profile_flow_test.dart` (interruptores con aviso y reversión).
- **Estado:** ⏳ Por hacer.

## T5 — Cambiar contraseña
- **Crear:**
  - `AuthRepository.changePassword`;
  - `change_password_sheet.dart`;
  - `SessionController.replaceTokens`.
- **Verificar:** `change_password_test.dart`.
- **Estado:** ⏳ Por hacer.

## T6 — Evidencia y documentación
- **Capturas:** `tool/screenshots_test.dart`, comparadas con la maqueta en claro y oscuro.
- **Actualizar:**
  - `docs/trazabilidad.md`;
  - `docs/versionado.md` (`0.3.0+3`);
  - `Memoria.md`;
  - la constitución si cambia algo del stack (no se espera).
- **Verificar:** format, analyze, test, critic y APK de debug; después del despliegue del back, la prueba en el Galaxy A54.
- **Estado:** ⏳ Por hacer.

## Pendientes
- `NOTE (HU-05)`: `Perfil-vendedor` con `GET /api/v1/profiles/{id}`.
- `NOTE (HU-14)`, `NOTE (HU-53)`, `NOTE (HU-52)`, `NOTE (HU-25)`: mosaicos y secciones de `Perfil`.
- `NOTE (HU-28)`, `NOTE (HU-46)`, `NOTE (HU-54)`, `NOTE (HU-55)`: filas de `Ajustes` y `Privacidad`.
