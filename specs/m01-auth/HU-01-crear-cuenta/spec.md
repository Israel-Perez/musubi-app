# HU-01 — Crear cuenta de estudiante (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-01 / SCRUM-19 / S2 / M-01 / [musubi-api:HU-01](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-01-crear-cuenta)

## Contexto
Pantalla "Crea tu cuenta", según las pantallas `Registro` y `Registro-error` de la maqueta. **Depende de**: `02-01` (tema, navegación, sesión, errores) y `musubi-api:HU-01`.

## Requisitos
1. **Encabezado:** "Paso 1 de 2 · Crea tu cuenta · Usa el correo de tu universidad".
2. **Campos:** correo institucional, nombre completo y contraseña, con el botón de "ver contraseña".
3. **Campus mientras se escribe** (500 ms después de la última tecla):
   - "Campus detectado: UTTT" con el nombre del campus;
   - con un correo personal, "Este correo no es de tu universidad" y el ejemplo `tu.nombre@uttt.edu.mx`, igual que en la maqueta.
   - Sin red, el registro no se bloquea, porque el back valida de nuevo.
4. **Reglas de la contraseña:** "Al menos 8 caracteres" y "Una letra y un número", con ✓ en vivo. La regla es la misma que en el back.
5. **Consentimiento (HU-47):** "Acepto los Términos y condiciones y el Aviso de privacidad", con enlaces a cada documento. Sin aceptar, "Crear cuenta" queda deshabilitado.
6. **Errores por `code`:**
   - correo personal → error en el campo de correo;
   - contraseña débil → error en el campo de contraseña;
   - correo ya registrado → aviso con "Iniciar sesión";
   - sin red, error del servidor o rate limit → aviso, y el formulario se conserva.
7. **Al crear la cuenta** se pasa a la verificación (HU-03) con el correo y los tiempos del código.

## Diseño
- `lib/features/auth/`:
  - `domain/` (`AuthRepository`, `Campus`, `Registration`, `AuthUser`, `SignedInSession`);
  - `data/http_auth_repository.dart` (`publicDioProvider`; lanza `ApiFailure`, nunca `DioException`);
  - `presentation/sign_up_screen.dart` y `password_rules.dart`.
- **El formulario usa `SingleChildScrollView`**, no `ListView`: un `ListView` descarta los campos que salen de la vista.
- **Rutas** en `lib/app/router.dart`: `/registro` y `/registro/verificacion` son solo de visitante.

## Contratos
- Filas de `musubi-api/docs/endpoints.md` (M-01): `POST /api/v1/auth/campus` y `POST /api/v1/auth/register` (constantes en `ApiPaths`).
- Errores: `musubi-api/docs/errores.md`.

## Tests
- `test/features/auth/data/http_auth_repository_test.dart` (4): campus, registro con consentimientos, confirmación y error como `ApiFailure`.
- `test/features/auth/presentation/auth_flow_test.dart` (11), con la app completa y el router real:
  - campus detectado y correo personal;
  - reglas de la contraseña en vivo;
  - sin consentimiento no se puede crear;
  - enlace al aviso;
  - flujo completo;
  - correo ya registrado;
  - sin red;
  - con sesión, `/registro` redirige.
- Self-test (21-Oct-2026): si se quita el consentimiento de `_canSubmit`, falla "sin aceptar el aviso y los términos no se puede crear".

## Criterios
- `flutter analyze --fatal-infos --fatal-warnings` sin hallazgos · `flutter test` 99/99 · critic PASS.

## Límites
- Los íconos del campus y de las reglas son Material (decisión de 02-01).
- `UpcomingSection` sigue en "Iniciar sesión" hasta HU-02.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 21-Oct-2026
- **Detalle:** Mismo PR que HU-03 y HU-47 (flujo compartido), igual que en el back.
