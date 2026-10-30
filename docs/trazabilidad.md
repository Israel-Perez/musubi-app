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
| HU-04 | SCRUM-22 | S1 | M-02 | Editar mi perfil | `specs/m02-profile/HU-04-editar-perfil/` | [musubi-api:HU-04](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m02-profile/HU-04-editar-perfil) | — | Spec en borrador |
| HU-05 | SCRUM-34 | S3 | M-02 | Consultar perfil y reputación de otro usuario | `specs/m02-profile/HU-05-perfil-publico/` | [musubi-api:HU-05](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m02-profile/HU-05-perfil-publico) | — | Spec en borrador |
| HU-06 | SCRUM-23 | S2 | M-03 | Publicar un producto | `specs/m03-listings/HU-06-publicar-producto/` | [musubi-api:HU-06](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-06-publicar-producto) | `test/features/listings/**`, `test/features/marketplace/http_catalog_repository_test.dart` | Borrador con evidencia |
| HU-07 | SCRUM-24 | S2 | M-03 | Editar o eliminar mis publicaciones | `specs/m03-listings/HU-07-editar-eliminar-publicaciones/` | [musubi-api:HU-07](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-07-editar-eliminar-publicaciones) | — | Spec en borrador |
| HU-08 | SCRUM-25 | S2 | M-03 | Consultar el estado de mis productos | `specs/m03-listings/HU-08-estado-mis-productos/` | [musubi-api:HU-08](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-08-estado-mis-productos) | — | Spec en borrador |
| HU-09 | SCRUM-26 | S2 | M-04 | Buscar productos por palabra clave | `specs/m04-marketplace/HU-09-buscar-productos/` | [musubi-api:HU-09](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-09-buscar-productos) | — | Spec en borrador |
| HU-10 | SCRUM-27 | S2 | M-04 | Filtrar por categoría y precio | `specs/m04-marketplace/HU-10-filtrar-categoria-precio/` | [musubi-api:HU-10](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-10-filtrar-categoria-precio) | — | Spec en borrador |
| HU-11 | SCRUM-28 | S2 | M-04 | Ver el detalle de un producto | `specs/m04-marketplace/HU-11-detalle-producto/` | [musubi-api:HU-11](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-11-detalle-producto) | — | Spec en borrador |
| HU-12 | SCRUM-51 | S4 | M-04 | Guardar una búsqueda sin resultados | `specs/m04-marketplace/HU-12-guardar-busqueda/` | [musubi-api:HU-12](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-12-guardar-busqueda) | — | Spec en borrador |
| HU-13 | SCRUM-35 | S3 | M-05 | Publicar una necesidad de compra | `specs/m05-purchase-requests/HU-13-publicar-necesidad/` | [musubi-api:HU-13](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-13-publicar-necesidad) | — | Spec en borrador |
| HU-14 | SCRUM-36 | S3 | M-05 | Editar, cerrar o cancelar mi solicitud | `specs/m05-purchase-requests/HU-14-gestionar-solicitud/` | [musubi-api:HU-14](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-14-gestionar-solicitud) | — | Spec en borrador |
| HU-15 | SCRUM-37 | S3 | M-05 | Explorar solicitudes publicadas | `specs/m05-purchase-requests/HU-15-explorar-solicitudes/` | [musubi-api:HU-15](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-15-explorar-solicitudes) | — | Spec en borrador |
| HU-16 | SCRUM-38 | S3 | M-05 | Responder "Yo tengo este producto" | `specs/m05-purchase-requests/HU-16-yo-tengo-este-producto/` | [musubi-api:HU-16](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-16-yo-tengo-este-producto) | — | Spec en borrador |
| HU-17 | SCRUM-39 | S3 | M-05 | Ver y elegir ofertas recibidas | `specs/m05-purchase-requests/HU-17-elegir-ofertas/` | [musubi-api:HU-17](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-17-elegir-ofertas) | — | Spec en borrador |
| HU-18 | SCRUM-40 | S3 | M-06 | Ver coincidencias al publicar una solicitud | `specs/m06-matching/HU-18-coincidencias-solicitud/` | [musubi-api:HU-18](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m06-matching/HU-18-coincidencias-solicitud) | — | Spec en borrador |
| HU-19 | SCRUM-41 | S3 | M-06 | Aviso al vendedor de solicitud compatible | `specs/m06-matching/HU-19-aviso-solicitud-compatible/` | [musubi-api:HU-19](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m06-matching/HU-19-aviso-solicitud-compatible) | — | Spec en borrador |
| HU-20 | SCRUM-29 | S2 | M-07 | Iniciar una conversación con el vendedor | `specs/m07-chat/HU-20-iniciar-conversacion/` | [musubi-api:HU-20](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m07-chat/HU-20-iniciar-conversacion) | — | Spec en borrador |
| HU-21 | SCRUM-30 | S2 | M-07 | Ver el contexto de la conversación | `specs/m07-chat/HU-21-contexto-conversacion/` | [musubi-api:HU-21](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m07-chat/HU-21-contexto-conversacion) | — | Spec en borrador |
| HU-22 | SCRUM-31 | S2 | M-07 | Bandeja de conversaciones | `specs/m07-chat/HU-22-bandeja-conversaciones/` | [musubi-api:HU-22](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m07-chat/HU-22-bandeja-conversaciones) | — | Spec en borrador |
| HU-23 | SCRUM-42 | S3 | M-08 | Confirmar la compra de un producto | `specs/m08-orders/HU-23-confirmar-compra/` | [musubi-api:HU-23](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-23-confirmar-compra) | — | Spec en borrador |
| HU-24 | SCRUM-43 | S3 | M-08 | Aceptar y actualizar mis pedidos | `specs/m08-orders/HU-24-actualizar-pedidos/` | [musubi-api:HU-24](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-24-actualizar-pedidos) | — | Spec en borrador |
| HU-25 | SCRUM-44 | S3 | M-08 | Consultar mis pedidos | `specs/m08-orders/HU-25-mis-pedidos/` | [musubi-api:HU-25](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-25-mis-pedidos) | — | Spec en borrador |
| HU-26 | SCRUM-45 | S3 | M-08 | Consultar mi historial de ventas | `specs/m08-orders/HU-26-historial-ventas/` | [musubi-api:HU-26](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-26-historial-ventas) | — | Spec en borrador |
| HU-27 | SCRUM-46 | S3 | M-13 | Calificar al vendedor al terminar un pedido | `specs/m13-reputation/HU-27-calificar-vendedor/` | [musubi-api:HU-27](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m13-reputation/HU-27-calificar-vendedor) | — | Spec en borrador |
| HU-28 | SCRUM-57 | S5 | M-13 | Reportar contenido o usuarios sospechosos | `specs/m13-reputation/HU-28-reportar-contenido/` | [musubi-api:HU-28](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m13-reputation/HU-28-reportar-contenido) | — | Spec en borrador |
| HU-29 | SCRUM-47 | S3 | M-09 | Aviso de producto buscado disponible | `specs/m09-notifications/HU-29-aviso-producto-buscado/` | [musubi-api:HU-29](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m09-notifications/HU-29-aviso-producto-buscado) | — | Spec en borrador |
| HU-30 | SCRUM-48 | S3 | M-09 | Aviso de oferta en mi solicitud | `specs/m09-notifications/HU-30-aviso-oferta-solicitud/` | [musubi-api:HU-30](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m09-notifications/HU-30-aviso-oferta-solicitud) | — | Spec en borrador |
| HU-31 | SCRUM-49 | S3 | M-09 | Avisos de mensajes y cambios de estado | `specs/m09-notifications/HU-31-avisos-mensajes-estado/` | [musubi-api:HU-31](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m09-notifications/HU-31-avisos-mensajes-estado) | — | Spec en borrador |
| HU-32 | SCRUM-52 | S4 | M-10 | Pedir un resumen de la conversación con IA | `specs/m10-genai/HU-32-resumen-ia/` | [musubi-api:HU-32](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m10-genai/HU-32-resumen-ia) | — | Spec en borrador |
| HU-33 | SCRUM-53 | S4 | M-10 | La IA identifica los datos del acuerdo | `specs/m10-genai/HU-33-ia-datos-acuerdo/` | [musubi-api:HU-33](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m10-genai/HU-33-ia-datos-acuerdo) | — | Spec en borrador |
| HU-34 | SCRUM-54 | S4 | M-10 | Revisar y confirmar la propuesta de la IA | `specs/m10-genai/HU-34-confirmar-propuesta-ia/` | [musubi-api:HU-34](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m10-genai/HU-34-confirmar-propuesta-ia) | — | Spec en borrador |
| HU-35 | SCRUM-58 | S5 | M-11 | Ver productos recomendados | `specs/m11-recommendations/HU-35-productos-recomendados/` | [musubi-api:HU-35](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m11-recommendations/HU-35-productos-recomendados) | — | Spec en borrador |
| HU-36 | SCRUM-59 | S5 | M-12 | Ver mis productos con baja rotación | `specs/m12-seller-support/HU-36-baja-rotacion/` | [musubi-api:HU-36](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m12-seller-support/HU-36-baja-rotacion) | — | Spec en borrador |
| HU-37 | SCRUM-60 | S5 | M-12 | Recibir sugerencias para vender | `specs/m12-seller-support/HU-37-sugerencias-venta/` | [musubi-api:HU-37](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m12-seller-support/HU-37-sugerencias-venta) | — | Spec en borrador |
| HU-38 | SCRUM-61 | S5 | M-12 | Saber si hay demanda para mis productos | `specs/m12-seller-support/HU-38-demanda-productos/` | [musubi-api:HU-38](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m12-seller-support/HU-38-demanda-productos) | — | Spec en borrador |
| HU-39 | SCRUM-62 | S5 | M-14 | Revisar reportes y moderar contenido | `specs/m14-admin/HU-39-moderar-contenido/` | [musubi-api:HU-39](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-39-moderar-contenido) | — | Spec en borrador |
| HU-40 | SCRUM-63 | S5 | M-14 | Suspender y reactivar cuentas | `specs/m14-admin/HU-40-suspender-cuentas/` | [musubi-api:HU-40](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-40-suspender-cuentas) | — | Spec en borrador |
| HU-41 | SCRUM-64 | S5 | M-14 | Gestionar categorías | `specs/m14-admin/HU-41-gestionar-categorias/` | [musubi-api:HU-41](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-41-gestionar-categorias) | — | Spec en borrador |
| HU-42 | SCRUM-65 | Post-MVP | M-14 | Consultar indicadores de uso | `specs/m14-admin/HU-42-indicadores-uso/` | [musubi-api:HU-42](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-42-indicadores-uso) | — | Spec en borrador |
| HU-43 | SCRUM-55 | — | M-08 | ~~Pagar un pedido con Mercado Pago~~ (reemplazada por HU-55) | — | — | — | Fuera de alcance (D-01) |
| HU-44 | SCRUM-56 | S4 | M-08 | Coordinar la entrega en un punto del campus | `specs/m08-orders/HU-44-coordinar-entrega/` | [musubi-api:HU-44](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-44-coordinar-entrega) | — | Spec en borrador |
| HU-45 | SCRUM-50 | S3 | M-13 | Calificar al comprador al terminar un pedido | `specs/m13-reputation/HU-45-calificar-comprador/` | [musubi-api:HU-45](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m13-reputation/HU-45-calificar-comprador) | — | Spec en borrador |
| HU-46 | SCRUM-32 | S2 | M-01 | Eliminar mi cuenta y mis datos | `specs/m01-auth/HU-46-eliminar-cuenta/` | [musubi-api:HU-46](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-46-eliminar-cuenta) | — | Spec en borrador |
| HU-47 | SCRUM-33 | S2 | M-01 | Aceptar aviso de privacidad y términos de uso | `specs/m01-auth/HU-47-aviso-privacidad/` | [musubi-api:HU-47](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-47-aviso-privacidad) | `test/features/auth/legal_documents_test.dart`, `auth_flow_test.dart` | Borrador con evidencia |
| HU-48 | SCRUM-73 | S2 | M-04 | Explorar la app como visitante | `specs/m04-marketplace/HU-48-explorar-visitante/` | — (catálogo público con HU-06) | `test/features/marketplace/visitor_flow_test.dart`, `test/features/marketplace/home_screen_test.dart`, `test/app/navigation_test.dart` | Borrador con evidencia (fase 1) |
| HU-49 | SCRUM-69 | Por asignar | M-04 | Ver populares y recién publicados | `specs/m04-marketplace/HU-49-populares-recientes/` | [musubi-api:HU-49](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-49-populares-recientes) | — | Spec en borrador |
| HU-50 | SCRUM-67 | Por asignar | M-03 | Manejar la cantidad disponible de un producto | `specs/m03-listings/HU-50-cantidad-disponible/` | [musubi-api:HU-50](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-50-cantidad-disponible) | — | Spec en borrador |
| HU-51 | SCRUM-70 | Por asignar | M-04 | Comparar opciones y pedir aviso de disponibilidad | `specs/m04-marketplace/HU-51-comparar-avisame/` | [musubi-api:HU-51](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-51-comparar-avisame) | — | Spec en borrador |
| HU-52 | SCRUM-74 | Por asignar | M-08 | Apartar un producto y verificar la entrega con QR o código | `specs/m08-orders/HU-52-apartar-producto/` | [musubi-api:HU-52](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-52-apartar-producto) | — | Spec en borrador |
| HU-53 | SCRUM-68 | Por asignar | M-04 | Guardar productos en favoritos | `specs/m04-marketplace/HU-53-favoritos/` | [musubi-api:HU-53](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-53-favoritos) | — | Spec en borrador |
| HU-54 | SCRUM-71 | Por asignar | M-02 | Elegir modo noche y preferencias | `specs/m02-profile/HU-54-modo-noche-preferencias/` | [musubi-api:HU-54](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m02-profile/HU-54-modo-noche-preferencias) | — | Spec en borrador |
| HU-55 | SCRUM-72 | Por asignar | M-08 | Pagar un pedido por transferencia o en efectivo | `specs/m08-orders/HU-55-pago-transferencia-efectivo/` | [musubi-api:HU-55](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-55-pago-transferencia-efectivo) | — | Spec en borrador |
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
| 02-02 | Publicación en Google Play (SCRUM-86) | 🚧 Borrador | `specs/phase-02-architecture/02-02-google-play/` |
| 02-03 | Marca y arranque (SCRUM-81) | 🚧 Borrador con evidencia | `test/core/widgets/musubi_logo_test.dart`, `test/app/brand_splash_test.dart` |
| 02-04 | Fidelidad con la maqueta (SCRUM-82) | 🚧 Borrador con evidencia | `test/core/widgets/`, `tool/screenshots_test.dart` |

## Tareas transversales

| Jira | Qué | Specs tocadas | Evidencia | Estado |
|---|---|---|---|---|
| SCRUM-66 | Maqueta versionada, matriz de versionamiento, fecha de evaluación y lineamientos | 00-01, 00-03 | `docs/maqueta/`, `test/versioning_test.dart` | En revisión (PR) |

## Lineamientos de la materia y maqueta

- Checklist canónico (L-01…L-19) en [`musubi-api/docs/bitacora/lineamientos-materia.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/bitacora/lineamientos-materia.md) (se enlaza, no se copia).
- Pantallas de la maqueta ↔ HU: [`docs/maqueta/README.md`](maqueta/README.md). El lineamiento 4 exige que la app sea igual a la maqueta; cada spec de HU del front cita sus pantallas por ID.
