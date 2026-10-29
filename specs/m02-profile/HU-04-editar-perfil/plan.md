# plan.md — HU-04 Editar mi perfil (app)

## 1. Componentes
- `features/profile/{domain,data,presentation}` (ver el diseño de `spec.md`).
- `features/auth`: `AuthRepository.changePassword` y `ChangePasswordSheet`.
- `core/session`: `SessionController.replaceTokens(SessionTokens)`.
- `core/widgets/avatars.dart`: `ProfileAvatar` con foto y caída a iniciales.
- `core/network/api_paths.dart`: `profileMe`, `profileVisibility`, `profilePhoto`, `careers` y `passwordChange`.
- `app/router.dart`: `/ajustes/privacidad` dentro de `requiresSession`.
- `lib/app/app_version.dart`: la versión que se muestra en `Ajustes`. `test/versioning_test.dart` la compara con `pubspec.yaml`.

## 2. Estado
- **`myProfileProvider`** (`AsyncNotifier<MyProfile>`):
  - `save(career, term)`;
  - `setVisibility(...)`, optimista y con reversión si falla;
  - `uploadPhoto(XFile)`, con el avance en `photoUploadProvider`;
  - `removePhoto()`.
  - Lo leen `Perfil`, `Ajustes`, `Privacidad` e Inicio (saludo y avatar). Por eso un cambio se ve al instante en todas.
- **`careersProvider`** (`FutureProvider`): se pide una vez por sesión y se invalida al cerrar sesión.
- **Sin el reintento automático de Riverpod 3** (`retry: (_, _) => null`), como en Inicio: el error se ve al instante con "Reintentar".

## 3. Decisiones
- **Selectores en lugar de campos de texto** para la carrera y el periodo (decisión del usuario): los datos quedan uniformes y el periodo no puede salir del rango. Visualmente son la misma caja de la maqueta, con una flecha.
- **Foto con el `PhotoPicker` de HU-06:**
  - mismo permiso y misma reducción;
  - se sube al elegirla, sin esperar a "Guardar cambios", como las fotos de `Vender-1`;
  - el resto del formulario sí espera a "Guardar".
- **La línea del perfil propio respeta "Mostrar mi carrera":** así la persona ve lo mismo que su campus, como en la maqueta (`hide(career)`).
- **Lo pendiente se oculta, no se pinta deshabilitado.** Un botón que no hace nada se ve poco profesional y confunde en la prueba cerrada de Google Play.
- **La versión al pie de `Ajustes`** sale de una constante verificada contra `pubspec.yaml`, sin el paquete `package_info_plus` (fuera del stack).

## 4. Guardarraíles
- La foto se ve solo con `API_BASE_URL` + `/media/...`: nunca una URL arbitraria del servidor.
- La contraseña nunca se registra ni se guarda. Los campos van con `obscureText`, sin autocorrección ni sugerencias.
- Las respuestas de error se traducen con `ApiFailure.fromDio` y su `code`, nunca por el texto.

## 5. Validación
Las pruebas de `spec.md`, las capturas contra la maqueta, el APK de debug y la prueba en el celular contra AWS.

## 6. Secuencia
1. Dominio y repositorio con su fake.
2. Providers.
3. `Perfil`.
4. `Ajustes` y sus hojas.
5. `Privacidad`.
6. Cambiar contraseña.
7. Capturas.
8. Documentación.
9. Prueba en el celular (después del despliegue del back).
