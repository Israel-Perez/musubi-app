# HU-04 — Editar mi perfil (tareas)

## T1 — Dominio y datos
- **Crear:**
  - `features/profile/domain/*` y `data/http_profile_repository.dart`;
  - `test/helpers/fake_profile_repository.dart`.
- **Cambiar:** `api_paths.dart`.
- **Verificar:** `http_profile_repository_test.dart` (6) y `profile_models_test.dart` (5).
- **Estado:** ✅ Hecho (03-Nov-2026).

## T2 — Perfil y Ajustes
- **Crear:**
  - `profile_providers.dart`;
  - `settings_screen.dart`;
  - `ProfileAvatar`;
  - `app_version.dart`.
- **Cambiar:** `profile_screen.dart` (maqueta `Perfil`) y el saludo de Inicio.
- **Verificar:** `profile_flow_test.dart` (Perfil y Ajustes) y `versioning_test.dart`.
- **Estado:** ✅ Hecho (03-Nov-2026).

## T3 — Datos personales y foto
- **Crear:** `personal_data_sheet.dart` (carrera, periodo y las opciones de la foto) y `email_sheet.dart`.
- **Verificar:** `profile_flow_test.dart` (guardar, buscador, periodo que no cabe, foto, sin cámara y correo).
- **Estado:** ✅ Hecho (03-Nov-2026).

## T4 — Privacidad
- **Cambiar:** `privacy_screen.dart` ("Quién te ve"); la ruta `/ajustes/privacidad` ya existía (HU-46).
- **Verificar:** `profile_flow_test.dart` (interruptores con aviso y reversión).
- **Estado:** ✅ Hecho (03-Nov-2026).

## T5 — Cambiar contraseña
- **Crear:**
  - `AccountRepository.changePassword`;
  - `change_password_sheet.dart` (la sesión nueva se guarda con `SessionController.signIn`).
- **Verificar:** `profile_flow_test.dart`, grupo "Cambiar contraseña".
- **Estado:** ✅ Hecho (03-Nov-2026).

## T6 — Evidencia y documentación
- **Capturas:** `tool/screenshots_test.dart`, comparadas con la maqueta en claro y oscuro.
- **Actualizar:**
  - `docs/trazabilidad.md`;
  - `docs/versionado.md` (`0.4.0+5`, también en musubi-api);
  - `Memoria.md`;
  - la constitución si cambia algo del stack (no se espera).
- **Verificar:** format, analyze, test, critic y APK de debug; después del despliegue del back, la prueba en el Galaxy A54.
- **Estado:** 🚧 En curso: capturas, docs y pruebas listas; falta el Galaxy A54 contra AWS.

## Pendientes
- `NOTE (HU-05)`: `Perfil-vendedor` con `GET /api/v1/profiles/{id}`.
- `NOTE (HU-14)`, `NOTE (HU-53)`, `NOTE (HU-52)`, `NOTE (HU-25)`: mosaicos y secciones de `Perfil`.
- `NOTE (HU-28)`, `NOTE (HU-46)`, `NOTE (HU-54)`, `NOTE (HU-55)`: filas de `Ajustes` y `Privacidad`.
