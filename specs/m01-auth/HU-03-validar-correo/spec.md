# HU-03 — Validar pertenencia con correo institucional (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-03 / SCRUM-21 / S2 / M-01 / [musubi-api:HU-03](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-03-validar-correo)

## Contexto
Pantallas `Verificacion` ("Revisa tu correo institucional") y `Verificacion-lista` ("Correo verificado") de la maqueta. **Depende de**: `HU-01`.

## Requisitos
1. **Verificación:**
   - textos: "Paso 2 de 2", "Te enviamos un código de 6 dígitos a {correo}", "¿No lo ves? Revisa tu carpeta de spam…" y "¿Por qué tu correo de la universidad?";
   - un campo de 6 dígitos (solo números, con autollenado de código);
   - "Verificar correo" se activa con 6 dígitos.
2. **Reenvío:** "Reenviar código en m:ss" hasta `resendAvailableAt`; después, "Reenviar código" con el aviso "Te enviamos un código nuevo."
3. **"Cambiar correo"** regresa al registro.
4. **Errores:** código inválido → error en el campo; código bloqueado o reenvío antes de tiempo → aviso.
5. **Al verificar:**
   - se guarda la sesión (`SessionController.signIn`, almacenamiento seguro);
   - se muestra "¡Listo, {nombre}! Ya eres parte de Musubi", con iniciales, correo y "Campus {siglas}";
   - "Empezar a explorar" lleva a Inicio.

## Diseño
- `verification_screen.dart` (`Timer.periodic` + `clockProvider`) y `welcome_screen.dart`.
- **Primero se navega a `/bienvenida`** (no es ruta de visitante) y **después se guarda la sesión**, para que la guardia no redirija antes de mostrar la bienvenida.
- Si se entra sin datos del registro, se muestra "Primero crea tu cuenta".

## Contratos
Filas `POST /api/v1/auth/verification/resend` y `POST /api/v1/auth/verification/confirm` de `musubi-api/docs/endpoints.md`.

## Tests
`test/features/auth/presentation/auth_flow_test.dart`:
- flujo completo con la sesión guardada en el almacén;
- código incorrecto deja la sesión como visitante;
- reenvío al terminar la cuenta regresiva.

## Criterios
`flutter test` 99/99.

## Límites
- En Development el código se lee en el log de la API (`LogEmailSender`).
- En la nube depende de SES y de un dominio propio (`NOTE (musubi-api:02-05)`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 21-Oct-2026
- **Detalle:** —
