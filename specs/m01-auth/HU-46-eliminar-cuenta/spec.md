# HU-46 — Eliminar mi cuenta y mis datos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-46 / SCRUM-32 / S3 / M-01 / [musubi-api:HU-46](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-46-eliminar-cuenta)

## Contexto
**Maqueta:**
- `Ajustes`, sección "Privacidad y seguridad" → `Privacidad`;
- en `Privacidad`: "Tus datos" y "Eliminar mi cuenta";
- el diálogo "¿Eliminar tu cuenta?".

Google Play exige poder pedir el borrado **dentro de la app**, además de la página web `https://musubiapp.com.mx/eliminar-cuenta` (SCRUM-84). Es requisito para pasar de la prueba cerrada a producción.

**Depende de:** `02-01`, `02-04` (piezas de la maqueta), `HU-02` (sesión) y el back de HU-46 (fila `POST /api/v1/account/delete`).

## Requisitos
1. **`Ajustes`:** muestra la sección "Privacidad y seguridad" con la fila "Privacidad", que abre `/ajustes/privacidad`.
2. **`Privacidad`**, igual a la maqueta:
   - el título junto a la flecha;
   - el resumen rojo "Tu perfil solo lo ve tu campus · No vendemos tus datos";
   - "TUS DATOS" con "Aviso de privacidad";
   - el botón con borde "Eliminar mi cuenta" en rojo de peligro.
3. **"Eliminar mi cuenta":** abre el diálogo de la maqueta ("Se borran tu perfil, tus publicaciones y tus chats. No se puede deshacer.", botón "Eliminar cuenta"). "Cancelar" no hace nada.
4. **Contraseña (agregado de seguridad):** la hoja "Confirma tu contraseña" pide la contraseña actual.
   - Sin contraseña: "Escribe tu contraseña." y no llama a la API.
   - Contraseña incorrecta: "La contraseña no es correcta." (código `auth.wrong_password`); la sesión sigue.
   - Mientras borra, el botón dice "Eliminando…".
5. **Al terminar:**
   - vuelve a Inicio como visitante;
   - borra los tokens del dispositivo (la API ya borró las sesiones);
   - avisa "Eliminamos tu cuenta y tus datos.".

## Diseño
- `features/auth/domain/account_repository.dart` y `data/http_account_repository.dart`, con `dioProvider` (con sesión). `accountRepositoryProvider` está en `auth_providers.dart`.
- `features/auth/presentation/delete_account.dart`: `DeleteAccountButton` y `ConfirmPasswordSheet`.
- `features/profile/presentation/privacy_screen.dart` (`PrivacyScreen`) y `settings_row.dart`: la fila de `Ajustes` pasó a un archivo compartido.
- `core/widgets/top_bar.dart`: opción `titleAtStart` (título de 20 junto a la flecha, como la maqueta).
- `MusubiColors.dangerText` (`#B42318`, en oscuro `#FF7A6E`) y el ícono `MusubiIcons.trash`.
- Ruta `AppRoutes.accountPrivacy` (`/ajustes/privacidad`), con sesión.
- **Pendientes:**
  - `NOTE (HU-04)`: "Quién te ve" y "Cambiar contraseña";
  - `NOTE (HU-28)`: "Usuarios bloqueados";
  - "Descargar mis datos" no tiene HU y queda oculto.

## Contratos
- Fila "M-01" `POST /api/v1/account/delete` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md).
- En código: `ApiPaths.accountDelete`.

## Tests
- `test/features/auth/data/http_account_repository_test.dart` (2): `POST` con la contraseña; `auth.wrong_password` → `ApiFailure`.
- `test/features/auth/presentation/delete_account_flow_test.dart` (5):
  - de `Ajustes` a `Privacidad`;
  - sin contraseña;
  - contraseña incorrecta;
  - borrado completo: visitante, almacén vacío, Inicio y el aviso;
  - cancelar el diálogo.
- `tool/screenshots_test.dart`: escena `privacidad`, comparada con la maqueta `#sesion.Privacidad`.

## Criterios
- [x] Existe "Eliminar mi cuenta" dentro de la app y borra la cuenta en la API (contraparte).
- [x] Con la contraseña incorrecta, la cuenta y la sesión siguen.
- [x] Al borrar, el dispositivo queda como visitante y sin tokens.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 224/224 · critic PASS.
- [ ] Probado en un teléfono desde la prueba cerrada de Google Play (versión `0.3.0+4`), contra la API desplegada.

## Límites
- **"Quién te ve"** de la maqueta llega con HU-04. La captura difiere de la maqueta solo en esa sección.
- **"Usuarios bloqueados"** (HU-28) y **"Descargar mis datos"** (sin HU) quedan ocultos: lo que no funciona no se muestra.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 30-Oct-2026
- **Detalle:** pedir la contraseña es un agregado de seguridad sobre la maqueta (lineamiento 4: agregar sí, quitar no).
