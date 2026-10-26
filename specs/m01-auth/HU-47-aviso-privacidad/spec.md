# HU-47 — Aceptar aviso de privacidad y términos de uso (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-47 / SCRUM-33 / S2 / M-01 / [musubi-api:HU-47](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-47-aviso-privacidad)

## Contexto
El registro exige aceptar los dos documentos (HU-01). Ambos se consultan en la app en cualquier momento y en la landing (lineamientos 16 y 17). La maqueta muestra "Aviso de privacidad · Resumen".

## Requisitos
1. **Fuente única:** `assets/legal/aviso-de-privacidad.md` y `assets/legal/terminos-y-condiciones.md`, versión `2026-10`, la misma que guarda el back. La landing publica los mismos archivos.
2. **Aviso integral apegado a la LFPDPPP:**
   - responsable, datos, finalidades necesarias y adicionales, transferencias, derechos ARCO y revocación, cookies y cambios;
   - **IA solo a petición** de una de las personas de la conversación (RN-40);
   - **revisión por el administrador** de lo reportado (RN-22);
   - coherente con D-01: sin pagos ni tarjetas.
3. **Pantalla del aviso:** el resumen de la maqueta (Qué guardamos, Para qué, Qué no hacemos, Tus derechos, "Tu perfil solo lo ve gente de tu campus") y debajo el aviso completo, con el botón "Entendido".
4. **Pantalla de términos completa.**
5. **Rutas:** `/aviso-de-privacidad` y `/terminos`, abiertas a visitantes y a usuarios con sesión.

## Diseño
- `legal_screens.dart`: `PrivacyNoticeScreen`, `TermsScreen` y `LegalDocumentView`, que interpreta un Markdown mínimo (`#`, `##`, `-` y párrafos) para no agregar una dependencia.
- Los documentos se cargan con `rootBundle` (`legalDocumentProvider`).

## Contratos
Versiones `Legal:*` del back (`musubi-api:01-04`). La app no envía la versión: el back guarda la vigente al registrar.

## Tests
- `test/features/auth/legal_documents_test.dart` (4):
  - secciones del aviso integral;
  - RN-40 y RN-22;
  - coherencia con D-01;
  - el responsable es el equipo, sin nombres de personas.
- `auth_flow_test.dart`: el enlace del consentimiento abre el aviso con su resumen.

## Criterios
`flutter test` 99/99.

## Límites
- Es un **BORRADOR**, así lo dice el encabezado del documento. Falta definir el domicilio y el medio de contacto, y la revisión del equipo, del PO o de un asesor antes de publicarse en Google Play.
- Volver a pedir la aceptación tras un cambio queda en `NOTE (HU-47)`, en el back.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 21-Oct-2026
- **Detalle:** —
