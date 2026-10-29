# HU-04 — Editar mi perfil (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-04 / SCRUM-22 / S1 (se ejecuta en S3) / M-02 / [musubi-api:HU-04](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m02-profile/HU-04-editar-perfil)

## Contexto
**Maqueta:**
- `Perfil`;
- `Ajustes` y sus hojas "Datos personales", "Correo institucional" y "Cambiar contraseña";
- `Privacidad` ("Quién te ve").

Quien tiene sesión consulta y edita su perfil y decide qué ve su campus. Jira (SCRUM-22) pide tres cosas:
- consultar y editar;
- solo los datos necesarios (RNF-05);
- que los cambios se vean de inmediato en el perfil público.

**Decisiones del usuario (27-Oct-2026)**, detalladas en la spec del back:
- **Periodo:** cuatrimestre, configurable por campus.
- **Carrera:** se elige de una lista, no se escribe.
- **Alcance:** las cuatro piezas de la maqueta, más una **foto de perfil** (agregado permitido por el lineamiento 4).

**Depende de:** `02-01`, `02-04` (piezas de la maqueta), `HU-02` (sesión), `HU-06` (`PhotoPicker`) y el back de HU-04 (filas "M-02" y `POST /api/v1/auth/password/change` de `musubi-api/docs/endpoints.md`).

## Requisitos
1. **`Perfil`:**
   - foto, o las iniciales si no hay, con la insignia de verificado;
   - nombre y "UTTT · carrera · 6º cuatrimestre":
     - sin carrera ni periodo se ve solo "UTTT";
     - con "Mostrar mi carrera" apagado también, porque así ve la persona lo mismo que ve su campus;
   - "Verificada";
   - fila de estadísticas: calificación ("—" y "Sin calificaciones" mientras no haya), ventas y compras;
   - mosaicos "Mis publicaciones" (con "N activas") y "Privacidad" ("Tus datos");
   - el engrane abre `Ajustes`.
2. **`Ajustes`:**
   - la tarjeta de la cuenta (foto, nombre, correo y flecha) abre "Datos personales";
   - "Correo institucional · Verificado" abre su hoja;
   - en "Privacidad y seguridad": "Cambiar contraseña" y "Privacidad · Quién te ve";
   - en "Ayuda": aviso de privacidad y términos;
   - "Cerrar sesión" y, al pie, "Musubi 0.3.0", la versión real de la app.
3. **"Datos personales"** (hoja alta):
   - **Foto:** la foto de perfil con "Cambiar foto", que ofrece "Tomar foto", "Elegir de la galería" y "Quitar foto". Mientras se sube, el avatar muestra el avance; al terminar avisa "Actualizamos tu foto".
   - **Nombre:** deshabilitado, con "Viene de tu correo institucional verificado".
   - **Carrera:** abre una lista con buscador, agrupada en TSU, Ingeniería y Licenciatura, con "Sin carrera" al inicio.
   - **Cuatrimestre:** abre la lista de los periodos válidos para la carrera elegida (TSU del 1 al 6; ingeniería y licenciatura del 7 al 11). Si cambia la carrera y el periodo ya no cabe, se borra y se avisa.
   - **Botones:** "Guardar cambios" → "Guardando…" → aviso "Guardamos tus datos". "Cancelar" descarta.
4. **"Correo institucional":**
   - correo, "Verificado" en verde y "Desde" con el mes y año de la verificación ("oct 2026");
   - la nota "Tu correo de la universidad… No se puede cambiar";
   - el botón "Entendido".
5. **"Cambiar contraseña":**
   - contraseña actual y nueva, con las reglas de HU-01;
   - con la nueva corta, sacude y avisa "Necesita al menos 8 caracteres";
   - con la actual incorrecta, marca el campo;
   - al guardar, reemplaza la sesión sin volver a pedir el login y avisa "Actualizamos tu contraseña".
6. **`Privacidad`:**
   - el resumen "Tu perfil solo lo ve tu campus · No vendemos tus datos";
   - "Quién te ve" con tres interruptores (carrera, ventas y en línea):
     - cada uno se guarda al tocarlo y avisa, por ejemplo "Tu carrera se ve en tu perfil" u "Ocultamos tu carrera de tu perfil";
     - si falla, regresa a su estado anterior y lo explica;
   - en "Tus datos", el aviso de privacidad.
7. **Los cambios se ven al instante** en `Perfil`, en `Ajustes` y en el saludo de Inicio, sin recargar la app.
8. **Estados:**
   - carga con esqueleto;
   - error con "Reintentar";
   - sin red, los formularios conservan lo escrito.

## Diseño
- **`lib/features/profile/`:**
  - `domain/`: `MyProfile`, `Career`, `AcademicTerm`, `ProfileVisibility`, `ProfileStats`, `ProfileRepository` y `termLabel(6)` → "6º cuatrimestre";
  - `data/`: `HttpProfileRepository`;
  - `presentation/`:
    - `myProfileProvider` (AsyncNotifier con cambios optimistas en la visibilidad) y `careersProvider`;
    - pantallas: `profile_screen.dart`, `settings_screen.dart` (sale de `profile_screen.dart`) y `privacy_screen.dart`;
    - hojas: `personal_data_sheet.dart` (con las listas de carrera y periodo), `email_sheet.dart`, `change_password_sheet.dart` y `profile_photo_sheet.dart`.
- **`core/widgets/avatars.dart`:** `ProfileAvatar` muestra la foto de red y cae en las iniciales si no hay o si falla.
- **Cambiar contraseña** vive en `features/auth` (`AuthRepository.changePassword`). `SessionController.replaceTokens` guarda la sesión nueva.
- **Ruta nueva:** `/ajustes/privacidad`, con sesión.
- **Íconos nuevos de la maqueta** con el generador de 02-04 (cámara y candado, si faltan).
- **Lo que no funciona todavía no se muestra.** Se agrega con su HU, como "Populares" en HU-06. Pendientes:
  - `NOTE (HU-14)`: "Mis solicitudes";
  - `NOTE (HU-53)`: "Favoritos";
  - `NOTE (HU-52)`: "Mis apartados";
  - `NOTE (HU-25)`: "Mis pedidos";
  - `NOTE (HU-55)`: "Cuenta para recibir pagos";
  - `NOTE (HU-54)`: modo noche y avisos;
  - `NOTE (HU-28)`: usuarios bloqueados y "Reportar un problema";
  - `NOTE (HU-46)`: "Descargar mis datos" y "Eliminar mi cuenta".

## Contratos
- **Filas "M-02"** de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md):
  - `GET /api/v1/profiles/me`;
  - `PUT /api/v1/profiles/me`;
  - `PUT /api/v1/profiles/me/visibility`;
  - `PUT /api/v1/profiles/me/photo`;
  - `DELETE /api/v1/profiles/me/photo`;
  - `GET /api/v1/careers`.
- **Fila "M-01":** `POST /api/v1/auth/password/change`.
- **Rutas en código:** `lib/core/network/api_paths.dart`, cada una citando su fila (skill `api-contract`).
- `GET /api/v1/profiles/{id}` lo consume HU-05 (`Perfil-vendedor`).

## Tests
- `test/features/profile/http_profile_repository_test.dart`:
  - mapeo de mi perfil y de las carreras;
  - multipart de la foto;
  - visibilidad;
  - errores `profiles.*` traducidos al español.
- `test/features/profile/profile_flow_test.dart`, con la app completa y el router real:
  - `Perfil` con y sin carrera;
  - estadísticas en cero;
  - "Datos personales": elegir carrera y periodo, guardar y ver "UTTT · … · 8º cuatrimestre";
  - cambiar de carrera borra un periodo que ya no cabe;
  - foto: subir, ver y quitar;
  - "Correo institucional";
  - `Privacidad`: interruptor con aviso y regreso si falla;
  - errores con "Reintentar".
- `test/features/auth/change_password_test.dart`:
  - nueva corta;
  - actual incorrecta;
  - éxito: reemplaza los tokens y avisa.
- `test/features/profile/profile_models_test.dart`: `termLabel`, periodos por carrera y línea del perfil.
- `tool/screenshots_test.dart`: escenas `perfil`, `ajustes`, `datos-personales`, `correo`, `cambiar-contrasena` y `privacidad`.

## Criterios
- `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 100 % · critic PASS.
- Capturas lado a lado con la maqueta (`Perfil`, `Ajustes`, sus hojas y `Privacidad`) en claro y oscuro. Diferencias aceptadas:
  - lo que la spec oculta hasta su HU;
  - la foto;
  - los campos de carrera y periodo, que son selectores.
- Probado en el Galaxy A54 contra la API en AWS después del despliegue.

## Límites
- **Sin recorte manual de la foto:** la API la recorta cuadrada al centro. Un recortador necesita un paquete fuera del stack (00-01).
- **El nombre no se edita** (maqueta).
- **La lista de carreras** viene del back y la valida el equipo (`musubi-api` plan §4).
- **Fuera de alcance:**
  - el perfil de otra persona (HU-05);
  - bloquear (HU-28);
  - descargar y eliminar mis datos (HU-46);
  - preferencias (HU-54);
  - cuenta para cobrar (HU-55).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 27-Oct-2026
- **Detalle:**
  - alcance acordado con el usuario el 27-Oct-2026;
  - desviaciones de la maqueta documentadas: selectores en lugar de campos de texto, foto de perfil y lo oculto hasta su HU;
  - sin paquetes nuevos.
