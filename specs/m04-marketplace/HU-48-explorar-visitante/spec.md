# HU-48 — Explorar la app como visitante (app, fase 1)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-48 / SCRUM-73 / S2 / M-04 / musubi-api: catálogo público con HU-06 (fase 2)

## Contexto
Maqueta, sección 1: `Inicio-visitante`, `Se-busca-visitante`, `Producto-visitante` y `Visitante-modal`. La app abre directo en la vitrina del campus, sin cuenta. Las acciones de miembro piden crear la cuenta **sin sacar a la persona de la pantalla** y, al terminar, la regresan a donde estaba.

- **Fase 1 (esta spec):** vitrina, hoja "Crea tu cuenta", campus y regreso a donde estabas.
- **Fase 2 (con HU-06):** el catálogo público (`GET /api/v1/products`, sin datos personales del vendedor, RNF-05) llena la vitrina, el detalle del producto y "Se busca".

**Depende de**: `02-01`, `HU-01`, `HU-02` y `HU-03`.

## Requisitos
1. **Inicio** (`/`, la app abre aquí):
   - encabezado: logotipo, chip "UTTT" y "Entrar" (solo visitantes);
   - "Populares" con Hoy / Semana;
   - "Recién publicados" (si hay productos);
   - "Se busca" con "Ver todo";
   - banner "La UTTT ya está en Musubi · Crear cuenta" (solo visitantes).
2. **Estados de la maqueta:**
   - cargando (`Inicio-cargando`: la forma de la vitrina);
   - error de red (`Inicio-error`: "Sin conexión a internet", "No pudimos cargar las publicaciones", "Reintentar");
   - vacío: dice por qué está vacío y qué hacer ("Vender algo", "Pedir algo").
3. **Hoja "Crea tu cuenta"** (`GATE` del prototipo), con 9 motivos, cada uno con su ilustración y su texto: comprar, chatear, guardar, ofrecer ("Yo tengo este producto"), pedir, publicar, mensajes, perfil y campus.
   - Lleva el chip "Solo con tu correo @uttt.edu.mx".
   - Botones: "Crear cuenta", "Ya tengo cuenta" y "Seguir explorando".
   - Pie: "Al entrar, vuelves justo aquí."
4. **Pestañas:** para el visitante, Mensajes, Perfil y Publicar abren la hoja y no navegan. Un enlace directo a esas rutas sigue yendo a "Iniciar sesión" (guardia de 02-01).
5. **Regreso:** al iniciar sesión (`?desde=`) o al terminar el registro ("Empezar a explorar"), se vuelve a la pantalla desde la que se abrió la hoja. Solo se aceptan rutas internas conocidas (`AppRoutes.safeReturn`).
6. **Chip del campus:**
   - visitante: la hoja "Crea tu cuenta" con el motivo del campus ("Estás explorando la UTTT");
   - con sesión: lleva la insignia de verificado y no abre nada (maqueta `Inicio`).
7. La barra inferior muestra la etiqueta "Publicar" debajo del botón central, como en la maqueta.

## Diseño
- `lib/features/marketplace/`:
  - `domain/` (`HomeFeed`, `ProductSummary`, `WantedSummary`, `CatalogRepository`);
  - `data/pending_catalog_repository.dart`, que distingue "sin red" (ping) de "vacío". `NOTE (HU-06)`: `HttpCatalogRepository`;
  - `presentation/` (`HomeScreen`, `CampusChip`, tarjetas de la vitrina).
- `lib/features/auth/presentation/account_gate.dart`: `AccountGateMotive`, `showAccountGate` y `continueToAccount`. Las ilustraciones están en `account_gate_art.dart` (02-04).
- `lib/app/return_path.dart` (`returnPathProvider`). `sessionRedirect` usa `rememberedReturn` si no hay `?desde=`.
- El registro y el inicio de sesión se abren con `go`, no con `push`. Así la guardia del router saca de la pantalla de visitante al entrar.
- `homeFeedProvider` **sin el reintento automático de Riverpod 3**: el error se ve de inmediato y la persona reintenta.
- Las filas horizontales toman el alto de su contenido; no se desbordan con la letra grande del sistema.

## Contratos
Ninguno todavía. El catálogo público llega con HU-06 y su fila en `musubi-api/docs/endpoints.md`.

## Tests
- `test/features/marketplace/visitor_flow_test.dart` (14):
  - abre en Inicio con el encabezado;
  - estados vacío, cargando y error (con reintento);
  - tarjetas con datos (lugar, vistas, "Quedan 2", "Último", "Agotado", "PAGA HASTA", "lun 5 oct");
  - Hoy / Semana;
  - con sesión, sin "Entrar" ni banner;
  - hojas de guardar, ofrecer, Mensajes y Publicar sin navegar;
  - "Ya tengo cuenta" y "Crear cuenta" regresan a "Se busca";
  - chip del campus;
  - "Entrar";
  - los 9 motivos.
- `test/app/navigation_test.dart`: el visitante que toca Perfil ve "Crea tu perfil"; un enlace directo a Perfil va a "Iniciar sesión".
- Self-tests (25-Oct-2026):
  - sin la hoja en las pestañas, falla "el visitante que toca Perfil ve Crea tu perfil";
  - si la bienvenida no usa el regreso, falla "Crear cuenta: tras la bienvenida vuelve a donde estaba".

## Criterios
- `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 144/144 · critic PASS · Semgrep 0 · APK probado en un Galaxy A54 contra AWS.

## Límites
- Hasta HU-06 la vitrina está vacía: no hay productos que mostrar. La excepción es la vitrina de muestra de dev (`DEMO_CATALOG`, 02-04).
- El detalle del producto (`Producto-visitante`), "Recién publicados" con filtro de categorías y "Se busca" completo llegan en la fase 2.
- Campus único (UTTT) para visitantes. `NOTE (HU-48)`: elegir campus cuando haya más comunidades (RNF-21).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 25-Oct-2026
- **Detalle:** Fase 1 por decisión del usuario (25-Oct-2026): primero la experiencia del visitante y después el catálogo con HU-06.
- **26-Oct-2026 (SCRUM-82, `02-04`):**
  - la hoja, el chip del campus y los textos quedan iguales a la maqueta;
  - el motivo "seguir" se cambió por "campus", que es el que trae el `GATE` del prototipo.
