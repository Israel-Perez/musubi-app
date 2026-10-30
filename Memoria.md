# Memoria del proyecto — musubi-app

Bitácora viva: estado, decisiones con su porqué y errores a evitar. Reglas de mantenimiento en `AGENTS.md` §2. Las lecciones permanentes viven en `specs/phase-00-constitution/00-04-lessons-learned/spec.md`.

## Estado actual (29-Oct-2026)

- **En `main`:** `0.2.0+2` con `config/prod.example.json` apuntando a `https://api.musubiapp.com.mx`. Probado en el Galaxy A54 contra el dominio.
- **HU-04 Editar mi perfil** (rama `feature/SCRUM-22-editar-perfil`): spec, plan y tareas en `specs/m02-profile/HU-04-editar-perfil/` (🚧 Borrador). Siguiente: T1 (dominio y repositorio), en paralelo al back.
- **Guía del equipo** (SCRUM-83, PR #15): `docs/guia-equipo.md` y los agentes de OpenCode.

## T15 — Specs en borrador de todo el backlog (29-Oct-2026, SCRUM-86)

**Qué se hizo**
- 47 HU pendientes con spec ligera (🚧 Borrador) en los dos repos: 94 carpetas en `specs/mNN-*/HU-NN-*/` con `spec.md`, `plan.md` y `task.md`.
- Las generó un script con datos de cuatro fuentes:
  - Jira: historia, criterios, RF/RNF y decisiones pendientes;
  - la maqueta: las pantallas de cada HU;
  - `docs/modelo-datos.md`: las colecciones;
  - `docs/modulos.md`: la carpeta de cada módulo.
- Specs técnicas en borrador:
  - musubi-api: 02-02 caché y `outbox`, 02-04 rendimiento HTTP, 02-06 observabilidad y 02-07 moderación;
  - musubi-app: 02-02 Google Play.
- `docs/trazabilidad.md` en "Spec en borrador", y la regla de `specs/README.md` (sección compartida) actualizada.

**Decisiones (con su porqué)**
- **Spec ligera para todo y detalle al iniciar cada HU:** el docente pide las specs desde el inicio. Detallar diseño y contratos semanas antes los desactualiza; así lo hacen Spec Kit y Kiro (constitución al inicio, specs por funcionalidad).
- **HU-43 sin spec** (fuera de alcance, D-01). **HU-42** con spec, marcada como posterior al MVP. **HU-48** en la API se cubre con HU-06 (vitrina pública).

**Errores a evitar**
- Una spec ligera **no** es una spec aprobada. Antes de programar una HU, completa su `plan.md` y resuelve las decisiones pendientes de su sección Límites.

## T12 — HU-04 Editar mi perfil: spec (27-Oct-2026, SCRUM-22)

**Qué se hizo**
- Se concilió Jira con la maqueta: `Perfil`, `Ajustes` con sus hojas "Datos personales", "Correo institucional" y "Cambiar contraseña", y `Privacidad` ("Quién te ve").

**Decisiones (con su porqué)**
- **El usuario pidió el módulo de perfil completo más una foto.** La foto se sube al elegirla, con el `PhotoPicker` de HU-06.
- **Carrera y cuatrimestre con selectores**, no con texto libre (usuario): datos uniformes y un periodo siempre válido para la carrera.
- **Lo que depende de otra HU se oculta**, no se pinta deshabilitado: mosaicos, filas de `Ajustes` y de `Privacidad` (cada uno con su `NOTE`).
- **Versión al pie de `Ajustes`** desde una constante verificada contra `pubspec.yaml`, sin `package_info_plus`.

## T14 — Dominio propio: aviso de privacidad y configuración de la nube (29-Oct-2026, SCRUM-84/85)

**Qué se hizo**
- **Aviso de privacidad:** el contacto es `contacto@musubiapp.com.mx` (antes decía "por definir"), y se agregó el enlace a https://musubiapp.com.mx/eliminar-cuenta. El sitio `musubi-landing` lo genera desde este archivo.
- **`config/prod.example.json`** apunta a `https://api.musubiapp.com.mx`, una URL fija y pública. Para compilar contra la nube basta copiarlo a `prod.json`.

**Decisiones (con su porqué)**
- **Sin domicilio físico en el aviso, solo el correo** (decisión del usuario). Las solicitudes ARCO se atienden por correo.
- **La URL real va en el ejemplo versionado:** ya no cambia al recrear la infraestructura y es pública, porque viaja dentro del APK. Así un compañero que clona el repo ya no ve "sin conexión".
## T13 — Guía del equipo y agentes de OpenCode (27-Oct-2026, SCRUM-83)

**Qué se hizo**
- `docs/guia-equipo.md`, idéntica en los dos repos (sección compartida): accesos, herramientas, cómo lee el proyecto cada herramienta, el flujo de una HU en 9 pasos, prompts para copiar, recursos que chocan entre personas, cómo probar en el celular y reglas del CI.
- `.opencode/agents/` con `security-reviewer`, `traceability-clerk` y `slice-scaffolder`. Remiten a `.claude/agents/`, que sigue siendo la fuente única.

**Decisiones (con su porqué)**
- **Mismas reglas para Claude Code y OpenCode:** OpenCode lee `AGENTS.md` y las skills de `.claude/skills/` (verificado en su documentación), pero no `.claude/agents/`. Por eso los agentes tienen una versión corta en `.opencode/agents/`.
- **La solo lectura en OpenCode se impone por `permission`:** `edit: deny` y bash solo para `git diff`, `git log` y `git show`, con la última regla que coincide ganando. Los hooks de Claude Code no corren en OpenCode.
- **Una sesión de IA por repo:** abierta en la carpeta `musubi/`, ninguna de las dos herramientas carga el `AGENTS.md` de los repos.

**Errores a evitar**
- **Números compartidos entre ramas:** `db/NNN`, `ExpectedVersion`, versiones, "T" de esta memoria y totales de `endpoints.md`. Quien fusiona segundo rebasa y renumera (guía §5).

## T11 — HU-06 Publicar un producto (27-Oct-2026, SCRUM-23)

**Qué se hizo**
- `features/listings`: `HttpListingsRepository`, `PhotoPicker` (`image_picker`), `SellDraftNotifier` (sube cada foto al agregarla), pantallas `sell_*`, `PublishOverlay` y `MyProductsScreen`.
- `HttpCatalogRepository` reemplaza a `PendingCatalogRepository`; las fotos se arman con `API_BASE_URL` porque CloudFront sirve `/media/*` en el mismo dominio.
- Íconos nuevos de la maqueta con el generador de 02-04. `PopIn` pasó a `core/widgets` con escala y curva configurables.
- Pruebas: 195 → 217 (flujo de venta, repositorios HTTP, borrador e Inicio sin "Populares").

**Decisiones (con su porqué)**
- **`image_picker` como excepción al stack** (aprobada por el usuario): es de flutter.dev, no agrega permisos y reduce la foto antes de subirla.
- **"Publicar" es una capa en el marco de pestañas:** en la maqueta la barra sigue encima y su botón cambia a "Cerrar".
- **"Populares" oculto sin vistas** (HU-11/49), por decisión del usuario.

**Errores a evitar**
- **`Image.file` en pruebas:** la lectura del archivo empieza dentro del reloj falso y nunca termina, así que `precacheImage` en `runAsync` se cuelga. Precargar las fotos antes de que la pantalla las pida.
- **Adaptador falso de Dio:** debe consumir `requestStream`. Si no, el archivo de un multipart queda abierto y Windows no deja borrarlo.
- **`CustomPaint(painter:)` se pinta debajo del hijo:** un borde punteado sobre un fondo va en `foregroundPainter`.
- **Flex en CSS:** un `width: 32px` dentro de un flex se encoge (`flex-shrink`). Medir en el DOM antes de copiar el número.
- **Chrome parte las palabras después del guion** ("fx-/991ES") y Flutter no: diferencia aceptada en las tarjetas.

## T10 — 02-04 Fidelidad con la maqueta (26/27-Oct-2026, SCRUM-82)

**Qué se hizo**
- **Componentes** de la maqueta en `lib/core/widgets/`, sin onda al tocar (`Pressable`): botón, campo, código de 6, casilla, switch, hojas, diálogo, aviso breve, esqueleto, barra superior y avatares.
- **Íconos Lucide** pintados desde el `d` de los SVG de la maqueta (`svg_path.dart`, `musubi_icons.dart`); licencia ISC en la pantalla de licencias.
- **Pantallas:**
  - cuenta: iniciar sesión, registro, verificación, bienvenida, recuperar contraseña, aviso y términos;
  - Inicio visitante y con sesión, con carga, error y "Filtrar";
  - hoja "Crea tu cuenta" con 9 ilustraciones;
  - Perfil, y Ajustes con "¿Cerrar sesión?".
- **Sesión y demo:**
  - `SessionProfile` en la sesión ("Hola, Ana");
  - "Abrir mi correo" por el canal `musubi/email`;
  - `DEMO_CATALOG` (solo dev) con los productos de la maqueta.
- **Herramienta:** `tool/screenshots_test.dart` captura a 390×844 @3x y con `RECTS=true` imprime las cajas de texto. La maqueta se midió con Edge sin ventana (capturas y `getBoundingClientRect` vía `--dump-dom`).
- **Pruebas:** 144 → 195.

**Decisiones (con su porqué)**
- **Íconos propios desde el SVG, sin paquete:** un paquete de íconos está fuera del stack (00-01) y no garantiza el mismo trazo.
- **Botones siempre habilitados que explican qué falta**, como la maqueta. En `Registro-error`, "Crear cuenta" se ve gris (`dimmed`) pero responde, como su `aria-disabled`: sacude el aviso y vuelve al correo.
- **Vitrina de muestra solo en dev:** `AppConfig.parse` la rechaza fuera de dev, para que un APK de producción nunca muestre datos inventados.
- **Animaciones sin fin de la maqueta con vueltas contadas** (onda de la bienvenida, sobre que flota): una animación infinita no deja asentar la pantalla en las pruebas y gasta batería.
- **"Publicaciones recientes" de la más nueva a la más vieja** (`HomeFeed.newestFirst`), como en `Inicio`.

**Errores a evitar**
- **Material cambia el texto:** inyecta `letterSpacing: 0.25` y su propia altura de línea. Fija las dos en cada texto (`MusubiType.style`); sin eso, los textos quedaban 3.6 % más anchos.
- **Redondeo de línea:** Flutter (SkParagraph) redondea cada línea a un entero, y Chrome a 3x redondea por separado el ascenso y el descenso (a 13 px: 16 contra 16.333). En columnas (etiqueta → campo) usa `CssLineBox`; si no, se acumula ~0.33 pt por texto.
- **Punteado:** Chrome pinta `1.5px dashed` a 3x con guion de 8 y hueco de 4 px del dispositivo, y ajusta el hueco para terminar en guion (`cssDashSegments`). Con 4.5/4.5 el boleto se veía distinto.
- **Barra inferior:** la de la maqueta es `box-sizing: border-box`. El borde de 1 px va dentro y el contenido empieza debajo.
- **Fuente Ahem de las pruebas:** sus textos son más anchos. Usa `Flexible`/ellipsis y prueba con letra al 130 %.
- **`find.bySemanticsLabel`** no encuentra nada sin semántica activa: busca por llaves o tipos.
- **Capturas a media animación:** las de la maqueta pueden salir así (la ilustración de la hoja en oscuro, el sobre que flota). Antes de "corregir", revisa la animación.
- **Mide la maqueta en el DOM**, no a ojo: la deriva de 1.7 pt de `Registro` solo apareció al comparar posiciones exactas.

## T9 — HU-48 fase 1 y 02-03 Marca y arranque (25-Oct-2026, SCRUM-73/81)

**Qué se hizo**
- `lib/features/marketplace/`: Inicio igual a la maqueta (encabezado, Populares Hoy/Semana, Recién publicados, Se busca, banner) con sus estados de carga, error y vacío. `PendingCatalogRepository` hasta HU-06.
- Hoja "Crea tu cuenta" (9 motivos del `GATE` del prototipo), pestañas Mensajes/Perfil/Publicar con la hoja, chip del campus y regreso a donde estabas (`returnPathProvider` + `?desde=`).
- Logotipo (`MusubiRingsPainter`), ícono adaptable + monocromo + PNG de Android 7, splash nativo (Android 12+ y anteriores) y splash animado de ~1.5 s.
- Pruebas: `visitor_flow_test.dart` (14), `brand_splash_test.dart` (4), `musubi_logo_test.dart` (4) → 144/144.

**Decisiones (con su porqué)**
- **Splash animado aunque la maqueta dice "sin splash":** lo pidió el usuario (lineamiento 4: agregar sí, quitar no). Va sobre la app ya construida y respeta "reducir animaciones".
- **Registro e inicio de sesión con `go`:** con `push`, la guardia del router no regresaba a `?desde=` al entrar.
- **Sin el reintento automático de Riverpod 3 en Inicio:** el error se ve al instante y la maqueta trae "Reintentar".
- **Módulo `marketplace` y no `home`:** así lo fija `docs/modulos.md` (M-04).

**Self-tests**
- Pestañas sin la hoja → falla "el visitante que toca Perfil ve Crea tu perfil".
- La bienvenida sin el regreso → falla "Crear cuenta: tras la bienvenida vuelve a donde estaba".

**Errores a evitar**
- **Riverpod 3 reintenta solo** los proveedores que fallan (con espera creciente): un estado de error nunca se ve si no se pasa `retry: (_, _) => null`.
- `scrollUntilVisible` con listas horizontales dentro de una vertical: pasar `scrollable: find.byType(Scrollable).first`; `ensureVisible` mueve la horizontal.
- `headlineSmall` no está en el tema: cae en el estilo de Material (peso normal). Usar `titleLarge` y los estilos de `MusubiType`.
- En el logotipo, el arco de hueco y el de color no deben terminar juntos: el suavizado deja una costura clara.
- Las capturas de la maqueta en modo headless se hacen con Edge (`--headless=new --screenshot`) sobre una copia del HTML con `#flujo.Pantalla`; las hojas no abren con clics simulados.

## T8 — Prueba en un celular por USB (25-Oct-2026, SCRUM-79)

- La PC no tiene emulador (6 GB de RAM, sin hipervisor): se probó HU-01/02/03/47/56 en un Galaxy A54 por USB contra la API local.
- `adb reverse tcp:5080 tcp:5080` + `config/usb.example.json` (`http://localhost:5080`); `localhost` se agregó a la excepción de HTTP de debug/profile (release sigue solo HTTPS; `test/security/android_config_test.dart` lo verifica).
- **Error a evitar:** si el cable se mueve, el celular se desconecta y `adb reverse` se pierde; la app queda "sin conexión" hasta repetirlo.

## T7 — HU-02 + HU-56 Iniciar y cerrar sesión, recuperar la contraseña (21-Oct-2026, SCRUM-20/78)

**Qué se hizo**
- `core/session/session_api.dart`: `HttpSessionApi` (`refresh`, `revoke`) sobre `publicDioProvider`; `sessionRefresherProvider` ya renueva de verdad.
- `SessionController.logOut` (revoca y borra; sin red borra igual); `SessionTokens.fromApi` compartido.
- Pantallas `SignInScreen` (maqueta `Iniciar-sesion`/`-error`), `ForgotPasswordScreen` (dos pasos), `SignOutButton` (confirmación de `Ajustes`) y `ProfileScreen` provisional.
- `PasswordRuleList` pasó a `password_rules.dart` (la comparten `Registro` y la recuperación).
- Pruebas: `session_flow_test.dart` (13), `session_api_test.dart` (8) y 4 del repositorio → 124/124.

**Decisiones (con su porqué)**
- **Después del login navega la guardia**, no la pantalla: el regreso a `?desde=` vive en un solo lugar.
- **El refresh solo termina la sesión con 400/401**: sin red o con un 5xx se conserva (L-16g, sesión siempre viva).
- **Cerrar sesión: primero a Inicio, después el logout**, para que la guardia no mande a "Iniciar sesión".
- **`auth.email_not_verified` → código nuevo + `Verificacion`**; si el reenvío responde `auth.resend_too_soon`, sirve el código que ya llegó.

**Self-tests**
- Refresh que devuelve `null` ante cualquier error → fallan "sin red" y "500".
- `logOut` sin revocar → falla "confirma, revoca en la API y vuelve a Inicio".

**Errores a evitar**
- Los scripts largos con comillas de Dart dentro de un heredoc de bash fallan al parsear: escribirlos con Write en el scratchpad.
- Al pasar a una pantalla con `context.go`, no hay botón de regreso: "Iniciar sesión" necesita su X hacia Inicio.

## T6 — HU-01/03/47 Registro, verificación y aviso de privacidad (21-Oct-2026, SCRUM-19/21/33)

**Qué se hizo**
- `lib/features/auth/`: `AuthRepository` (lanza `ApiFailure` tipado), `HttpAuthRepository` (`publicDioProvider`), `SignUpScreen` (campus en vivo, reglas de contraseña, consentimiento con enlaces), `VerificationScreen` (código, cuenta regresiva para reenviar), `WelcomeScreen` y pantallas legales.
- `assets/legal/{aviso-de-privacidad,terminos-y-condiciones}.md`: borradores (LFPDPPP, RN-40, RN-22, D-01), fuente única para la app y la landing; `LegalDocumentView` interpreta un Markdown mínimo.
- Pruebas: 4 del repositorio, 11 del flujo con la app completa y el router real, y 4 de contenido legal → 99/99.

**Decisiones (con su porqué)**
- **Navegar a `/bienvenida` antes de guardar la sesión**: así la guardia de visitante no redirige a Inicio antes de mostrar la bienvenida.
- **`SingleChildScrollView` + `Column` en formularios**, no `ListView` (que descarta los campos fuera de la vista; las pruebas no encontraban el botón).
- **`clockProvider`** inyectable para la cuenta regresiva.
- Los textos de las pantallas salen literalmente de la maqueta.

**Self-tests**
- Si se quita el consentimiento de `_canSubmit`, falla "sin aceptar el aviso y los términos no se puede crear".

**Errores a evitar**
- Riverpod 3 exporta `FutureProviderFamily` desde `package:flutter_riverpod/misc.dart`, no desde el archivo principal.
- Una prueba "sin nombres de personas" que busca nombres reales con una regex mete esos nombres al repo público: comprobar lo positivo (el responsable es el equipo).

## T5 — 02-01 Base de la app (21-Oct-2026, SCRUM-79)

**Qué se hizo**
- Tema de la maqueta: `MusubiColors` (ThemeExtension claro/oscuro con el mapa `dc-meta.dark`), `MusubiSizes`, `MusubiType`, Plus Jakarta Sans 400–800 empaquetada (TTF de `tokotype/PlusJakartaSans@18d1cd2`, OFL, registrada en `LicenseRegistry`).
- Navegación: `StatefulShellRoute` con Inicio, Se busca, Mensajes y Perfil + botón central Publicar (`MusubiBottomBar`); guardia pura `sessionRedirect` y regreso seguro (`AppRoutes.safeReturn`).
- Sesión: `SessionTokens`, `SecureTokenStore` (flutter_secure_storage 11.2.0), `SessionController` (Visitor/SignedIn; se lee en `main()` antes de pintar), `AuthInterceptor` (token solo hacia la API; una renovación por ola de 401).
- Errores: `ApiFailure.fromDio` (problem+json con `code`, `title` y `errors` por campo; `network.*` propios).
- Componentes: `MusubiButton`, `MusubiTextField`, `InlineMessage`, `LoadingView`, `EmptyView`, `ErrorView`.
- Seguridad (L-07): `test/security/android_config_test.dart` (backup, permisos, tráfico en claro, archivos sensibles).

**Decisiones (con su porqué)**
- **Fuente empaquetada** (no `google_fonts`): nada se descarga en tiempo de ejecución y la versión queda fija.
- **Sesión leída en `main()`**: sin pantalla "cargando sesión" ni redirecciones dobles.
- **Dos clientes HTTP**: `publicDioProvider` (sin sesión; renovación y `/auth`) y `dioProvider` (con interceptor).
- **Íconos Material outlined** en lugar de un paquete Lucide (sin dependencia nueva).
- **Sin SQLite en el MVP** (lineamiento 16 dice "si se requiere"); se revisa en HU-53.

**Self-tests**
- Interceptor que acepta cualquier host → "nunca envía el token a otro host" en rojo.

**Errores a evitar**
- **Deadlock en `QueuedInterceptor`**: reintentar con el mismo Dio dentro de `onError` deja el error del reintento esperando en la fila bloqueada (la prueba se colgó 30 s). El reintento sale por un cliente sin el interceptor.
- `FakeHttpAdapter.requests` guarda la misma `RequestOptions` que luego se modifica: para afirmar headers, capturarlos en el momento del envío.
- `flutter_secure_storage` 11 pide la plataforma Android 35 y Gradle se atora al instalarla (el mismo problema del `sdkmanager.bat` de T1): `android sdk install "platforms;android-35"` a mano. El APK de debug queda con `INTERNET` + `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (lo agrega AndroidX, con nivel de firma; no es peligroso).
- very_good_analysis exige tipo explícito en `static final` no obvios (`specify_nonobvious_property_types`) y no acepta `[Texto]` en dartdoc si no es un símbolo (`comment_references`).

## T4 — Backlog alineado con la maqueta (21-Oct-2026, SCRUM-75)

- **D-01 decidido por el usuario:** el pago es solo el de la maqueta (transferencia a la CLABE del vendedor o efectivo con código de entrega, sin comisión). HU-43 (Mercado Pago, SCRUM-55) queda fuera de alcance (etiqueta `fuera-de-alcance` + comentario en Jira) y la reemplaza **HU-55** (SCRUM-72). Constitución §1 (compartida) y §6/§11, 01-04 (`Payments:*` en lugar de `MercadoPago:*`), AGENTS, skills y Semgrep actualizados.
- **HU nuevas de la maqueta** (Historias en SCRUM con épica y etiqueta `maqueta`, sin sprint): HU-48 visitante (SCRUM-73), HU-49 populares (SCRUM-69), HU-50 inventario (SCRUM-67), HU-51 comparar/Avísame (SCRUM-70), HU-52 apartados QR (SCRUM-74), HU-53 favoritos (SCRUM-68), HU-54 modo noche (SCRUM-71), HU-55 pago (SCRUM-72). `docs/trazabilidad.md` pasa a 55 HU.
- Dependabot: `mongo` solo recibe parches de la línea 8.0 (`ignore` de minor/major); se cerró el PR que subía a 8.3.11.
- **Error a evitar:** el MCP de Atlassian da timeout en `createJiraIssue`/`editJiraIssue` aunque la operación sí se aplique. Antes de reintentar, buscar con JQL (`key > SCRUM-NN`): un reintento ciego duplicó HU-48 (la copia SCRUM-74 se reutilizó para HU-52).

## T3 — Maqueta, versionamiento y lineamientos (20-Oct-2026, SCRUM-66)

**Qué se hizo**
- Maqueta HTML del equipo en `docs/maqueta/musubi-prototipo.html` (60 pantallas en 10 secciones + guía de estilo; SHA-256 en su README). En `.gitattributes` va como `-text -diff linguist-documentation` para conservar los bytes.
- `docs/maqueta/README.md`: tokens de diseño, pantallas ↔ HU (propuesta), 7 funciones sin HU (G-01…G-07) y la decisión D-01 (pago).
- Constitución §1 (compartida, copiada del back): evaluación el **02-Dic-2026**; los lineamientos de la materia mandan; la app es igual a la maqueta. §6: diseño visual y datos locales → `NOTE (02-01)`.
- `docs/versionado.md` (sección compartida) + `test/versioning_test.dart` (la `version` de `pubspec.yaml`, hoy `0.1.0+1`, debe coincidir con la última fila de la matriz).
- 00-03: RNF-20/RNF-27 con la paleta y el área táctil de la maqueta; filas L-04 (fidelidad a la maqueta) y Versionamiento.

**Decisiones (con su porqué)**
- **Los lineamientos viven en el back y aquí se enlazan** (como `endpoints.md`): una sola tabla viva.
- **La maqueta se versiona en el repo** (y no solo en Drive): las specs citan pantallas por ID y el evaluador revisa el proyecto con prompts.
- La maqueta solo trae personas y correos ficticios (comparados contra los usuarios de Jira el 20-Oct-2026); su contraseña de demo no es una credencial.

**Pendientes / decisiones del usuario**
- **D-01:** la maqueta paga por transferencia (CLABE) o efectivo y "no cobra comisión"; HU-43 (Mercado Pago) no aparece. El lineamiento 4 impide quitar lo de la maqueta.
- **G-01…G-07** (visitante, populares, inventario, comparar/Avísame, apartados con QR, favoritos, modo noche) necesitan HU en Jira.
- Riesgo de calendario: una cuenta personal nueva de Google Play exige 14 días de prueba cerrada con 12 testers antes de producción; desde el 09-Nov el margen hacia el 02-Dic es corto.

## T2 — Publicación en GitHub (15-Oct-2026)

- Repos **públicos**: `https://github.com/Israel-Perez/musubi-app` (y `musubi-api`). En GitHub gratuito, público habilita la protección de rama, minutos de Actions ilimitados y secret scanning sin costo. La plantilla ya parte de que no hay nada secreto en el repo.
- **Sin nombres de personas en el repo público** (decisión del usuario): se quitaron del §1 de la constitución (sección compartida, los dos repos), del crédito del README y del prompt archivado. Los nombres viven en Jira y Confluence.
- **Commit inicial sin clave Jira** (decisión del usuario: la tarea de plantilla no tiene clave). Desde la primera HU, cada commit y PR empieza con `SCRUM-NN`.
- Protección de `main`: ver el README (sección "Protección de rama recomendada") y la configuración aplicada con `gh`.

## T1 — Plantilla inicial SDD + DevSecOps (15-Oct-2026)

**Qué se hizo**
- Proyecto creado con `flutter create --org com.musubi --project-name musubi_app --platforms android`; applicationId/namespace definitivos **`com.musubi.app`** (confirmados por el usuario antes de crear) y `MainActivity` movida a `com/musubi/app`.
- Arquitectura feature-first: `lib/app/` (MusubiApp, router), `lib/core/` (config, network, errors, theme), `lib/features/status/` (ping a la API: domain/data/presentation), convención en `lib/features/README.md`.
- Primera conexión con el back: `HttpStatusRepository` → `GET /api/v1/ping` (fila de `musubi-api/docs/endpoints.md`), con fake y una pantalla inicial que no se rompe sin API.
- Config por ambiente con `--dart-define-from-file` (`config/*.example.json` versionados; los reales, ignorados) + `AppConfig.parse` (HTTPS fuera de dev) + `network_security_config` (release sin tráfico en claro; debug/profile solo `10.0.2.2`). `allowBackup=false`.
- Gobernanza: constitución (§1–§5 copiadas byte a byte de `musubi-api`), plantilla, `docs/modulos.md` (compartidos), specs 00-01…00-04 y 01-01…01-05, `AGENTS.md`, `CLAUDE.md`, `docs/trazabilidad.md` (47 HU).
- Guardarraíles: `analysis_options.yaml` estricto (`todo: error`), critic B1–B4, Semgrep (5 reglas generic), CI de 5 jobs, Dependabot (pub/actions con `cooldown`), plantilla de PR.
- Claude Code: 3 agentes (revisores con solo lectura forzada por `disallowedTools` + hook PowerShell idéntico al del back) y 9 skills (8 comunes + `api-contract`).
- El prompt original de la plantilla está archivado en `musubi-api/docs/bitacora/prompt-plantilla-inicial.md`.

**Versiones medidas (15-Oct-2026)**
- Flutter 3.47.7 (stable, rev abaf9c5237) · Dart 3.13.5 · DevTools 2.60.0.
- Android: platform `android-36`, build-tools 36.1.0, NDK 28.2.13676358, AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, JDK 17.0.20 (Microsoft OpenJDK); `minSdk` 24, `targetSdk`/`compileSdk` 36 (de `FlutterExtension.kt`, verificado en el APK con aapt2).
- Paquetes: flutter_riverpod 3.4.3 (MIT), go_router 18.1.0 (BSD-3), dio 5.11.1 (MIT), very_good_analysis 11.0.0 (MIT); licencias leídas del pub cache.
- CI: checkout v7.0.1, subosito/flutter-action v2.23.0, setup-java v6.1.0, setup-python v7.0.0, upload-artifact v7.0.2 (SHAs en `ci-pr.yml`); Semgrep 1.181.0.

**Decisiones (con su porqué)**
- **Riverpod** (sin codegen), **go_router** y **dio**: aprobados por el usuario. Riverpod por los overrides en pruebas y por tener menos código repetitivo que Bloc.
- **very_good_analysis 11**: exige `const new(...)` (sintaxis de Dart 3.13). Se mantiene y `dart fix --apply` la corrige. **Revisar con el equipo:** los tutoriales usan la forma clásica.
- **Repositorio que no lanza** (devuelve `ApiStatus` sealed): la UI no necesita `try/catch` y nunca se rompe por la red.
- **`appConfigProvider` sin valor por defecto**: obliga a configurar en `main` (fail-fast) y en cada prueba.
- **`targetSdk` desde el plugin de Flutter** (no fijado a mano): hoy vale 36; se verifica en el APK con cada actualización de Flutter.
- **Firebase** (HU-31/02-01): `firebase_options.dart` y `google-services.json` ignorados desde ya; en CI se regeneran desde secretos en los jobs que compilan (política completa en la skill `critic-guardrails`). Pedido del usuario.
- **`build-apk` solo en push a `main`** con la condición exacta `github.event_name == 'push' && github.ref == 'refs/heads/main'` (pedido del usuario).
- Textos de la UI con acentos correctos (RNF-18); comentarios en ASCII por consistencia con los scripts.
- Se quitaron `cupertino_icons` (solo Android) y `flutter_lints` (reemplazado).

**Self-tests (los guardarraíles muerden)**
- critic con un scratch → `FAIL (7 bloqueantes, 1 aviso)`: B1, B2 (APP_USR-, `--dart-define …TOKEN`, `fromEnvironment('…KEY')`), B3, B4 (`catch (e) {}` y `catch (_)` sin uso); el `catch` de control que traduce el error **no** se marcó.
- Semgrep con un scratch → 5/5 reglas; sobre el repo, con `--config=auto`, 0.
- Hook `readonly-git-guard.ps1`: mismo archivo y mismos 12 casos que en el back.
- `flutter analyze` con un archivo de prueba: `todo: error` solo marca "TODO"; `flutter_style_todos` marca "Todo"/"todo" al inicio de un comentario.

**Errores a evitar**
- `sdkmanager.bat` (obsoleto) parte `platforms;android-36` en el `;` → "Package not found". Usar `android sdk install`. AGP tampoco pudo autoinstalar el NDK por la misma causa → instalarlo a mano.
- `flutter build … | tail` dio "exit 0" con FAILURE de Gradle: revisar el exit de Flutter o "√ Built".
- `flutter pub add --dev "integration_test:{sdk: flutter}"` falla en Git Bash: editar `pubspec.yaml`.
- En Riverpod 3, leer un provider `autoDispose` en `ProviderContainer.test` sin `listen` lo destruye entre lecturas.

**Confluence (15-Oct-2026)**
- Publicado con confirmación del usuario en el espacio `DDS` ("Desarrollo de software") de `uttt-startup-musubi.atlassian.net`: página padre "MUSUBI · Documentación técnica" (id 4947970) con las hijas "00 · Constitución y gobernanza SDD", "01 · Fundación musubi-api", "01 · Fundación musubi-app", "Catálogo de endpoints" y "Trazabilidad HU ↔ specs".
- Regla: las páginas resumen y **enlazan** al repo; nunca copian tablas vivas. Los enlaces a GitHub funcionan después del primer push. Al cerrar una fase o HU relevante, actualizar el resumen de la página correspondiente.

**Pendientes con dueño**
- `02-01`: navegación por módulos, componentes base, paleta y contraste (RNF-20), tamaños (RNF-27), Crashlytics (`NOTE (02-01)`), timeouts medidos, cobertura con umbral.
- `02-02`: firma de subida (`NOTE (02-02)`), ficha de Google Play, prueba cerrada (09-Nov-2026), despliegue desde GitHub y tag de versión (`docs/versionado.md`).
- `HU-02`: sesión, `flutter_secure_storage`, interceptor del token (`NOTE (HU-02)`). `HU-20`: SignalR. `HU-31`: FCM + secretos de Firebase en el CI.
- Equipo: roles PO/SM, revisores, umbrales "Por definir con el PO", protección de `main` en GitHub y la clave Jira de la tarea de plantilla (commit `SCRUM-XX`).
