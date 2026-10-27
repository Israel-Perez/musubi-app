# 02-04 — Fidelidad con la maqueta: componentes, pantallas y vitrina de muestra

**HU / Jira / Sprint / Módulo / Contraparte:** — / SCRUM-82 / S2 / App / — (usa `SessionResponse.user`, ya en `musubi-api/docs/endpoints.md`)

## Contexto
El 26-Oct-2026 el equipo pidió que la app se vea **igual** a la maqueta en botones, hojas, diálogos y demás. La referencia es `docs/maqueta/musubi-prototipo.html`, el mismo archivo que publica `musubi-mockup.netlify.app` (mismo SHA-256).

Las pantallas de 02-01, HU-01/02/03/47/56 y HU-48 fase 1 usaban piezas de Material y se notaba la diferencia:
- el efecto de onda (ripple) al tocar;
- los íconos de Material;
- la altura de línea y el espaciado de letras del tema.

**Depende de**: `02-01`, `02-03` y HU-48 fase 1.

Maqueta: `Inicio-visitante`, `Visitante-modal`, `Inicio`, `Inicio-cargando`, `Inicio-error`, `Iniciar-sesion`, `Iniciar-sesion-error`, `Registro`, `Registro-error`, `Verificacion`, `Verificacion-lista`, `Aviso-privacidad`, `Perfil` y `Ajustes`. También cubre la hoja "Filtrar" de Recién publicados y el diálogo "¿Cerrar sesión?". Todas en modo claro y oscuro.

## Requisitos
1. **Medidas de la maqueta:**
   - 1 px de CSS = 1 px lógico;
   - cada texto fija su altura de línea y su espaciado de letras (`MusubiType.style`): los del tema de Material cambian el ancho y el alto del texto;
   - en columnas, los textos con `line-height: normal` miden lo que les da Chrome (`CssLineBox`), no el entero al que Flutter redondea la línea;
   - el punteado `1.5px dashed` del boleto lleva el patrón de Chrome (`cssDashSegments`).
2. **Íconos de la maqueta** (Lucide, licencia ISC):
   - el mismo trazo, pintado desde el `d` del SVG;
   - sin paquete nuevo;
   - la licencia aparece en la pantalla de licencias.
3. **Toques sin onda.** Al presionar se usan los estados de la maqueta (`.pr`, `.ps`, `.pc` y `.press` a 0.97). Las áreas táctiles miden 44 px o más.
4. **Componentes de la maqueta:**
   - botón principal, secundario, discreto y enlace, con estado de carga;
   - campo de texto: halo al enfocar, sacudida con error y ojo de contraseña;
   - código de 6 casillas;
   - casilla y switch;
   - hoja inferior ("Crea tu cuenta" y de pantalla) y diálogo de confirmación;
   - aviso breve con acción;
   - esqueleto con brillo, barra superior, avatares e insignia de verificado.
5. **Comportamientos de la maqueta que faltaban:**
   - **Botones siempre habilitados** que dicen qué falta ("Te faltan 2 dígitos", "Acepta los términos para continuar", contraseña débil).
   - **`Registro-error`:**
     - "Crear cuenta" se ve gris, como su `aria-disabled`;
     - al tocarlo, sacude el aviso y vuelve al correo;
     - no se muestran las reglas de la contraseña.
   - **Código:**
     - se verifica solo al completarse;
     - "Pegar código";
     - "Abrir mi correo" abre la app de correo de Android, o avisa si no hay;
     - el sobre flota (`__fly`: 3 px cada 2.6 s, tres vueltas).
   - **Saludo por nombre** en Inicio con sesión ("Hola, Ana"). El perfil de la sesión (`SessionProfile`) se guarda junto a los tokens.
   - **Hoja "Filtrar"** en Recién publicados: categoría y "Ocultar agotados".
   - **"Publicaciones recientes"** (con sesión) de la más nueva a la más vieja.
   - **Pantalla Ajustes** (`/ajustes`): "Cerrar sesión" pide confirmación en un diálogo.
6. **Vitrina de muestra** (`DEMO_CATALOG`, solo `dev`): los productos, Populares y "Se busca" de la maqueta, para revisar el diseño en un celular mientras llega HU-06. `AppConfig.parse` la rechaza fuera de dev.
7. **Modo oscuro:** el mapa `dc-meta.dark` del prototipo.
8. **Accesibilidad de 02-01 intacta:** etiquetas para el lector de pantalla, contraste, "reducir animaciones" y letra grande sin desbordes.

## Diseño
- **`lib/core/theme/`:**
  - `MusubiColors`: pares claro/oscuro del prototipo;
  - `MusubiType.style`: la altura de línea `normal` de Plus Jakarta Sans es 1.26;
  - sin onda (`NoSplash`) y la transición de página de la maqueta.
- **`lib/core/widgets/`:**
  - íconos: `svg_path.dart`, `musubi_icon.dart` y `musubi_icons.dart`, generados desde los SVG de la maqueta;
  - interacción: `pressable.dart`, `musubi_button.dart` (con `dimmed` y `gap`) y `musubi_text_field.dart`;
  - medidas de Chrome: `css_line_box.dart` y `css_dashes.dart`;
  - controles: `otp_field.dart` y `musubi_controls.dart`;
  - capas: `musubi_sheet.dart`, `musubi_dialog.dart` y `musubi_snack.dart`;
  - apoyo: `skeleton.dart`, `shake.dart`, `top_bar.dart`, `avatars.dart` y `feedback_views.dart` (con `RiseIn` y `FloatY`).
- **`lib/core/platform/email_inbox.dart` + `MainActivity.kt`:** canal `musubi/email`, que abre la app de correo con `CATEGORY_APP_EMAIL`.
- **`lib/core/session/session_tokens.dart`:**
  - `SessionProfile` se lee de `SessionResponse.user`;
  - una sesión guardada antes de este cambio, sin perfil, sigue siendo válida.
- **`lib/features/marketplace/`:**
  - `DemoCatalogRepository` y `CatalogFilter`;
  - `filter_sheet.dart`;
  - las tarjetas y los estados de Inicio.
- **`lib/features/auth/presentation/`:** `auth_layout.dart`, las 9 ilustraciones de la hoja (`account_gate_art.dart`) y las pantallas de cuenta.
- **`lib/features/profile/presentation/profile_screen.dart`:** Perfil y Ajustes.
- **Rutas nuevas:**
  - `/buscar` (`NOTE (HU-09)`);
  - `/notificaciones` (`NOTE (HU-31)`);
  - `/ajustes` (con sesión).
- **Recursos:** 14 fotos WebP de la maqueta (600 px) en `assets/products/` y `assets/licenses/lucide.txt`.
- **`tool/screenshots_test.dart`:**
  - captura las pantallas a 390×844 @3x con las fuentes reales para compararlas con la maqueta;
  - con `RECTS=true` imprime la caja de cada texto, para cotejarla con el DOM de la maqueta;
  - no corre en el CI.

## Contratos
Ninguno nuevo. El perfil sale de `SessionResponse.user { fullName, email, campus { shortName } }`, que ya está en el catálogo del back (`POST /api/v1/auth/verification/confirm` y el inicio de sesión).

## Tests
- `test/core/widgets/widgets_test.dart` (19):
  - botón: carga, alturas, color al presionar sin onda, deshabilitado y atenuado (`Registro-error`);
  - campo: error, ojo, halo y error sin mensaje;
  - aviso en línea, error, sacudida, código, diálogo, aviso breve, casilla y switch;
  - esqueleto con "reducir animaciones";
  - flotar: −3 px a media vuelta, quieto al final y sin moverse con "quitar animaciones";
  - accesibilidad en claro y oscuro.
- `test/core/widgets/css_dashes_test.dart` (3): empieza y termina con guion, hueco cerca del ideal y línea continua si no caben dos guiones.
- `test/core/widgets/svg_path_test.dart` (7): comandos absolutos y relativos, números compactos de Lucide, arcos, curvas y que los íconos caben en su cuadro.
- `test/features/marketplace/home_screen_test.dart` (9):
  - "Filtrar": categoría y globo "1", "Ocultar agotados" y "Limpiar";
  - sin categorías no hay filtro;
  - letra al 130 % sin desbordes;
  - con sesión: saludo con y sin nombre, "Publicaciones recientes" de la más nueva a la más vieja, cargando y sin red.
- `test/features/marketplace/demo_catalog_repository_test.dart` (8): datos de la maqueta, Hoy/Semana, filtro, lo más nuevo primero (sin fecha al final y empates en orden), "hace 20 min" y "Último"/"Quedan 2".
- **Pruebas actualizadas:**
  - flujos de cuenta: código incompleto, verificación automática, "Abrir mi correo" con `FakeEmailInbox`, nombre, contraseña débil y `Registro-error` (botón gris, sin reglas, vuelve al correo);
  - sesión, visitante, navegación, tema, configuración (`DEMO_CATALOG` solo en dev) y sesión con perfil.

## Criterios
- `dart format` sin cambios · `flutter analyze --fatal-infos --fatal-warnings` 0 · `flutter test` 195/195.
- `pwsh scripts/critic-guardrails.ps1` PASS (también en PowerShell 5.1) · `flutter build apk --debug` √.
- Capturas lado a lado de la maqueta y la app (`tool/screenshots_test.dart`) para cada pantalla de la lista, en claro y en oscuro. Van como evidencia en el PR.
- **Posiciones medidas contra el DOM** de la maqueta (Edge sin ventana, `getBoundingClientRect`):
  - etiquetas de `Registro` en 211.000, 367.333 y 459.667;
  - `Iniciar-sesion-error` en 342.667 y 435.000;
  - la app coincide al tercio de punto.
- **Self-tests (27-Oct-2026):**
  - sin `newestFirst`, falla "Publicaciones recientes: de la más nueva a la más vieja";
  - con el orden anterior, `scrollUntilVisible` no encuentra "hace 3 h · Luis M.".

## Límites
- **"Muy pronto" hasta su HU:**
  - `Se-busca-visitante` y "Se busca" (HU-15);
  - Producto (HU-11), Búsqueda (HU-09/10) y Notificaciones (HU-31);
  - Mensajes (HU-20/22) y Publicar (HU-06).
- **Perfil** muestra solo lo que ya existe (cuenta y verificación). Calificaciones, ventas y apartados llegan con HU-04.
- **Diferencias a propósito con la maqueta:**
  - `Inicio-error`: "Guardado en tu teléfono" y "Lo que guardaste sigue disponible" llegan con los favoritos locales (HU-53);
  - `Inicio` con sesión: el aviso push de ejemplo ("Valeria Cruz") llega con las notificaciones (HU-31);
  - `Aviso-privacidad`: debajo del resumen va el aviso integral (HU-47), que la maqueta no dibuja;
  - los datos de muestra siguen a `Inicio-visitante` cuando las dos pantallas de la maqueta no coinciden (por ejemplo, "Bata de laboratorio" frente a "…manga larga, talla S").
- **Ajustes** todavía no trae el modo noche manual ni las preferencias (HU-54): la app sigue el modo del sistema.
- **Sin golden tests en el CI.** La comparación es por capturas, porque el render cambia entre plataformas; las pruebas de widget fijan textos, estados y medidas clave.
- **La vitrina de muestra no es contenido real** y solo existe en dev. Se revisa al llegar HU-06.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 26-Oct-2026
- **Detalle:** Decisiones a revisar con el equipo:
  - botones siempre habilitados, como en la maqueta;
  - `DEMO_CATALOG` solo en dev;
  - "Se busca" del visitante diferido a HU-15.
