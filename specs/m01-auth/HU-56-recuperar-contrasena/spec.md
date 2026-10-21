# HU-56 — Recuperar mi contraseña (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-56 / SCRUM-78 / S2 / M-01 / [musubi-api:HU-56](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-56-recuperar-contrasena)

## Contexto
La maqueta solo tiene el enlace "¿Olvidaste tu contraseña?" en `Iniciar-sesion`. Las pantallas siguen la guía de estilo y el patrón de `Verificacion`. **Depende de**: `HU-02`.

## Requisitos
1. **Paso 1, "Recupera tu cuenta":** correo institucional (llega prellenado si ya se escribió en "Iniciar sesión") y "Enviar código".
2. **Paso 2, "Crea tu contraseña nueva":**
   - "Si {correo} tiene cuenta en Musubi, te enviamos un código de 6 dígitos." No confirma que la cuenta exista;
   - código de 6 dígitos (solo números, autollenado);
   - "Reenviar código en m:ss" y después "Reenviar código" con el aviso "Te enviamos un código nuevo.";
   - "Cambiar correo" regresa al paso 1;
   - contraseña nueva con las reglas en vivo (las mismas de `Registro`);
   - "Al guardarla, cerramos tu sesión en todos tus dispositivos.";
   - "Guardar contraseña" se activa con 6 dígitos y una contraseña válida.
3. **Errores:** código inválido → error en el campo; código bloqueado, sin red o rate limit → aviso; contraseña débil → error en el campo.
4. **Al guardar:** vuelve a "Iniciar sesión" con el correo escrito y el aviso "Listo, tu contraseña cambió".

## Diseño
- `forgot_password_screen.dart`: una sola pantalla con dos pasos (estado local).
- `AuthRepository.requestPasswordReset` / `resetPassword`.
- `PasswordChanged` es el `extra` de la ruta de "Iniciar sesión".
- `PasswordRuleList` se movió a `password_rules.dart` para compartirla con `Registro`.

## Contratos
Filas `POST /api/v1/auth/password/forgot` y `POST /api/v1/auth/password/reset` de `musubi-api/docs/endpoints.md`.

## Tests
- `test/features/auth/presentation/session_flow_test.dart` (5 de esta HU):
  - flujo completo, de "Iniciar sesión" a entrar con la contraseña nueva;
  - código incorrecto;
  - contraseña débil;
  - reenvío al terminar la cuenta regresiva;
  - "Cambiar correo".
- `test/features/auth/data/http_auth_repository_test.dart`: pedir el código y el 204 sin cuerpo.

## Criterios
- Los de HU-02 (misma corrida): `flutter test` 124/124 · analyze 0 · critic PASS.

## Límites
- La entrega real del correo depende de SES y de un dominio propio (`NOTE (musubi-api:02-05)`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 21-Oct-2026
- **Detalle:** Pantallas propias (la maqueta solo tiene el enlace); por revisar con el equipo de diseño.
