# Trazabilidad HU ↔ specs ↔ tests — musubi-app

Matriz viva de las historias de usuario del MVP (55; HU-43 fuera de alcance). **La fuente de verdad del backlog es Jira** (proyecto `SCRUM`): sprint, prioridad y estado de gestión se consultan ahí. Esta tabla registra el lado técnico **de este repo**.

Reglas de mantenimiento (skill `traceability`; las verifica el sub-agente `traceability-clerk`):

- **Spec (este repo):** se llena al crear `specs/mNN-<modulo>/HU-NN-<slug>/` al iniciar el sprint de la HU.
- **Contraparte:** enlace a la spec de la misma HU en `musubi-api` (o `N/A` si la HU no toca el back).
- **Tests:** rutas de las pruebas que cubren la HU (p. ej. `test/features/auth/presentation/register_screen_test.dart`).
- **Estado (técnico, de este repo):** `Por iniciar` → `Spec en borrador` → `En desarrollo` → `Borrador con evidencia` → `Aprobado`.
- Una HU en `Borrador con evidencia` o `Aprobado` debe tener Spec y Tests distintos de "—".

| HU | Jira | Sprint | Módulo | Título | Spec (este repo) | Contraparte | Tests | Estado |
|---|---|---|---|---|---|---|---|---|
| HU-01 | SCRUM-19 | S2 | M-01 | Crear cuenta de estudiante | `specs/m01-auth/HU-01-crear-cuenta/` | [musubi-api:HU-01](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-01-crear-cuenta) | `test/features/auth/**` | Borrador con evidencia |
| HU-02 | SCRUM-20 | S2 | M-01 | Iniciar y cerrar sesión | `specs/m01-auth/HU-02-iniciar-cerrar-sesion/` | [musubi-api:HU-02](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-02-iniciar-cerrar-sesion) | `test/features/auth/presentation/session_flow_test.dart`, `test/core/session/session_api_test.dart` | Borrador con evidencia |
| HU-03 | SCRUM-21 | S2 | M-01 | Validar pertenencia con correo institucional | `specs/m01-auth/HU-03-validar-correo/` | [musubi-api:HU-03](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-03-validar-correo) | `test/features/auth/presentation/auth_flow_test.dart` | Borrador con evidencia |
| HU-04 | SCRUM-22 | S1 | M-02 | Editar mi perfil | — | — | — | Por iniciar |
| HU-05 | SCRUM-34 | S3 | M-02 | Consultar perfil y reputación de otro usuario | — | — | — | Por iniciar |
| HU-06 | SCRUM-23 | S2 | M-03 | Publicar un producto | — | — | — | Por iniciar |
| HU-07 | SCRUM-24 | S2 | M-03 | Editar o eliminar mis publicaciones | — | — | — | Por iniciar |
| HU-08 | SCRUM-25 | S2 | M-03 | Consultar el estado de mis productos | — | — | — | Por iniciar |
| HU-09 | SCRUM-26 | S2 | M-04 | Buscar productos por palabra clave | — | — | — | Por iniciar |
| HU-10 | SCRUM-27 | S2 | M-04 | Filtrar por categoría y precio | — | — | — | Por iniciar |
| HU-11 | SCRUM-28 | S2 | M-04 | Ver el detalle de un producto | — | — | — | Por iniciar |
| HU-12 | SCRUM-51 | S4 | M-04 | Guardar una búsqueda sin resultados | — | — | — | Por iniciar |
| HU-13 | SCRUM-35 | S3 | M-05 | Publicar una necesidad de compra | — | — | — | Por iniciar |
| HU-14 | SCRUM-36 | S3 | M-05 | Editar, cerrar o cancelar mi solicitud | — | — | — | Por iniciar |
| HU-15 | SCRUM-37 | S3 | M-05 | Explorar solicitudes publicadas | — | — | — | Por iniciar |
| HU-16 | SCRUM-38 | S3 | M-05 | Responder "Yo tengo este producto" | — | — | — | Por iniciar |
| HU-17 | SCRUM-39 | S3 | M-05 | Ver y elegir ofertas recibidas | — | — | — | Por iniciar |
| HU-18 | SCRUM-40 | S3 | M-06 | Ver coincidencias al publicar una solicitud | — | — | — | Por iniciar |
| HU-19 | SCRUM-41 | S3 | M-06 | Aviso al vendedor de solicitud compatible | — | — | — | Por iniciar |
| HU-20 | SCRUM-29 | S2 | M-07 | Iniciar una conversación con el vendedor | — | — | — | Por iniciar |
| HU-21 | SCRUM-30 | S2 | M-07 | Ver el contexto de la conversación | — | — | — | Por iniciar |
| HU-22 | SCRUM-31 | S2 | M-07 | Bandeja de conversaciones | — | — | — | Por iniciar |
| HU-23 | SCRUM-42 | S3 | M-08 | Confirmar la compra de un producto | — | — | — | Por iniciar |
| HU-24 | SCRUM-43 | S3 | M-08 | Aceptar y actualizar mis pedidos | — | — | — | Por iniciar |
| HU-25 | SCRUM-44 | S3 | M-08 | Consultar mis pedidos | — | — | — | Por iniciar |
| HU-26 | SCRUM-45 | S3 | M-08 | Consultar mi historial de ventas | — | — | — | Por iniciar |
| HU-27 | SCRUM-46 | S3 | M-13 | Calificar al vendedor al terminar un pedido | — | — | — | Por iniciar |
| HU-28 | SCRUM-57 | S5 | M-13 | Reportar contenido o usuarios sospechosos | — | — | — | Por iniciar |
| HU-29 | SCRUM-47 | S3 | M-09 | Aviso de producto buscado disponible | — | — | — | Por iniciar |
| HU-30 | SCRUM-48 | S3 | M-09 | Aviso de oferta en mi solicitud | — | — | — | Por iniciar |
| HU-31 | SCRUM-49 | S3 | M-09 | Avisos de mensajes y cambios de estado | — | — | — | Por iniciar |
| HU-32 | SCRUM-52 | S4 | M-10 | Pedir un resumen de la conversación con IA | — | — | — | Por iniciar |
| HU-33 | SCRUM-53 | S4 | M-10 | La IA identifica los datos del acuerdo | — | — | — | Por iniciar |
| HU-34 | SCRUM-54 | S4 | M-10 | Revisar y confirmar la propuesta de la IA | — | — | — | Por iniciar |
| HU-35 | SCRUM-58 | S5 | M-11 | Ver productos recomendados | — | — | — | Por iniciar |
| HU-36 | SCRUM-59 | S5 | M-12 | Ver mis productos con baja rotación | — | — | — | Por iniciar |
| HU-37 | SCRUM-60 | S5 | M-12 | Recibir sugerencias para vender | — | — | — | Por iniciar |
| HU-38 | SCRUM-61 | S5 | M-12 | Saber si hay demanda para mis productos | — | — | — | Por iniciar |
| HU-39 | SCRUM-62 | S5 | M-14 | Revisar reportes y moderar contenido | — | — | — | Por iniciar |
| HU-40 | SCRUM-63 | S5 | M-14 | Suspender y reactivar cuentas | — | — | — | Por iniciar |
| HU-41 | SCRUM-64 | S5 | M-14 | Gestionar categorías | — | — | — | Por iniciar |
| HU-42 | SCRUM-65 | Post-MVP | M-14 | Consultar indicadores de uso | — | — | — | Por iniciar |
| HU-43 | SCRUM-55 | — | M-08 | ~~Pagar un pedido con Mercado Pago~~ (reemplazada por HU-55) | — | — | — | Fuera de alcance (D-01) |
| HU-44 | SCRUM-56 | S4 | M-08 | Coordinar la entrega en un punto del campus | — | — | — | Por iniciar |
| HU-45 | SCRUM-50 | S3 | M-13 | Calificar al comprador al terminar un pedido | — | — | — | Por iniciar |
| HU-46 | SCRUM-32 | S2 | M-01 | Eliminar mi cuenta y mis datos | — | — | — | Por iniciar |
| HU-47 | SCRUM-33 | S2 | M-01 | Aceptar aviso de privacidad y términos de uso | `specs/m01-auth/HU-47-aviso-privacidad/` | [musubi-api:HU-47](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-47-aviso-privacidad) | `test/features/auth/legal_documents_test.dart`, `auth_flow_test.dart` | Borrador con evidencia |
| HU-48 | SCRUM-73 | S2 | M-04 | Explorar la app como visitante | `specs/m04-marketplace/HU-48-explorar-visitante/` | — (catálogo público con HU-06) | `test/features/marketplace/visitor_flow_test.dart`, `test/app/navigation_test.dart` | Borrador con evidencia (fase 1) |
| HU-49 | SCRUM-69 | Por asignar | M-04 | Ver populares y recién publicados | — | — | — | Por iniciar |
| HU-50 | SCRUM-67 | Por asignar | M-03 | Manejar la cantidad disponible de un producto | — | — | — | Por iniciar |
| HU-51 | SCRUM-70 | Por asignar | M-04 | Comparar opciones y pedir aviso de disponibilidad | — | — | — | Por iniciar |
| HU-52 | SCRUM-74 | Por asignar | M-08 | Apartar un producto y verificar la entrega con QR o código | — | — | — | Por iniciar |
| HU-53 | SCRUM-68 | Por asignar | M-04 | Guardar productos en favoritos | — | — | — | Por iniciar |
| HU-54 | SCRUM-71 | Por asignar | M-02 | Elegir modo noche y preferencias | — | — | — | Por iniciar |
| HU-55 | SCRUM-72 | Por asignar | M-08 | Pagar un pedido por transferencia o en efectivo | — | — | — | Por iniciar |
| HU-56 | SCRUM-78 | S2 | M-01 | Recuperar mi contraseña | `specs/m01-auth/HU-56-recuperar-contrasena/` | [musubi-api:HU-56](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-56-recuperar-contrasena) | `test/features/auth/presentation/session_flow_test.dart` | Borrador con evidencia |

Total: 56 HU (S1: 1 · S2: 16 · S3: 17 · S4: 5 · S5: 8 · Post-MVP: 1 · Por asignar: 7 · Fuera de alcance: 1). HU-48 entró a S2 (25-Oct-2026). HU-02 pasó de S1 a S2 y HU-56 entró a S2 (21-Oct-2026). HU-48…HU-55 nacen de la maqueta (21-Oct-2026, SCRUM-75); HU-43 sale por la decisión D-01.

## Specs técnicas (sin HU)

| Spec | Título | Estado | Evidencia |
|---|---|---|---|
| 00-01 | Principios y stack | 🚧 Borrador con evidencia | `specs/phase-00-constitution/00-01-principles-stack/` |
| 00-02 | Gobernanza SDD y DoD | 🚧 Borrador con evidencia | `specs/phase-00-constitution/00-02-sdd-governance/` |
| 00-03 | Requerimientos no funcionales | 🚧 Borrador con evidencia | `specs/phase-00-constitution/00-03-nfr/` |
| 00-04 | Lecciones aprendidas | 🚧 Borrador con evidencia | `specs/phase-00-constitution/00-04-lessons-learned/` |
| 01-01 | Setup y toolchain | 🚧 Borrador con evidencia | `flutter build apk --debug` (targetSdk 36) |
| 01-02 | Estructura de la app (shell) | 🚧 Borrador con evidencia | `lib/app/`, `lib/features/README.md` |
| 01-03 | Cliente de API y ping | 🚧 Borrador con evidencia | `test/features/status/` |
| 01-04 | Configuración por ambiente | 🚧 Borrador con evidencia | `test/core/config/app_config_test.dart` |
| 01-05 | Estructura, calidad y CI | 🚧 Borrador con evidencia | `scripts/critic-guardrails.ps1`, `.github/workflows/ci-pr.yml` |
| 02-01 | Base de la app: tema, navegación, sesión y errores (SCRUM-79) | 🚧 Borrador con evidencia | `test/{app,core,security}/` |

## Tareas transversales

| Jira | Qué | Specs tocadas | Evidencia | Estado |
|---|---|---|---|---|
| SCRUM-66 | Maqueta versionada, matriz de versionamiento, fecha de evaluación y lineamientos | 00-01, 00-03 | `docs/maqueta/`, `test/versioning_test.dart` | En revisión (PR) |

## Lineamientos de la materia y maqueta

- Checklist canónico (L-01…L-19) en [`musubi-api/docs/bitacora/lineamientos-materia.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/bitacora/lineamientos-materia.md) (se enlaza, no se copia).
- Pantallas de la maqueta ↔ HU: [`docs/maqueta/README.md`](maqueta/README.md). El lineamiento 4 exige que la app sea igual a la maqueta; cada spec de HU del front cita sus pantallas por ID.
