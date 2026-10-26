# 02-03 — Marca y arranque: logotipo, ícono y splash

**HU / Jira / Sprint / Módulo / Contraparte:** — / SCRUM-81 / S2 / App / —

## Contexto
Hasta ahora la app mostraba el ícono y el splash de Flutter. La guía de estilo de la maqueta define el logotipo: dos anillos entrelazados, el rojo a la izquierda. La maqueta dice "Sin splash ni bienvenida: la app abre directo en la vitrina", pero el equipo pidió un splash animado corto (25-Oct-2026), y el lineamiento 4 permite agregar funciones.

## Requisitos
1. **Logotipo en Flutter** (`MusubiRings`, `MusubiLogo`):
   - el mismo trazo que el SVG de la guía (viewBox 64x40, anillos de radio 14 con trazo 6, arcos de hueco de 11);
   - claro (rojo + tinta) y oscuro (rojo + blanco).
2. **Ícono de la app:**
   - adaptable en Android 8+, con fondo blanco y los anillos dentro de la zona segura de 66 dp;
   - monocromo para los íconos temáticos de Android 13+;
   - PNG para Android 7 (`mipmap-*dpi`), generados con el mismo pintor (`tool/launcher_icons_test.dart`).
3. **Splash nativo** en Android 12+ (`windowSplashScreen*`) y en versiones anteriores (`launch_background`): fondo de la app (`#FFFFFF` / `#17171A`) y los anillos centrados.
4. **Splash animado** (~1.5 s), sobre la app que ya se construye debajo, así que no retrasa la carga:
   - los anillos llegan desde los lados y se anudan;
   - aparece "Musubi" y todo se desvanece;
   - bloquea los toques mientras se ve.
   - Con "reducir animaciones", solo un fundido de 600 ms.

## Diseño
- `lib/core/widgets/musubi_logo.dart` (`MusubiRingsPainter`). El arco de color se alarga 4° por lado para tapar el borde del hueco; sin eso, el suavizado deja una costura clara.
- `lib/app/splash/brand_splash.dart` va en el `builder` de `MaterialApp.router`. `brandSplashEnabledProvider` lo apaga en las pruebas.
- Android:
  - `res/drawable/{splash_icon, ic_launcher_foreground, ic_launcher_monochrome, launch_background}.xml`;
  - `mipmap-anydpi-v26/ic_launcher.xml`;
  - `values{,-night}/colors.xml`;
  - `values{,-night}-v31/styles.xml`.

## Contratos
No aplica.

## Tests
- `test/app/brand_splash_test.dart` (4): se retira a los ~1.5 s, bloquea toques mientras se ve, con "reducir animaciones" dura 600 ms y apagado no aparece.
- `test/core/widgets/musubi_logo_test.dart` (4): colores en claro y oscuro, proporción 64:40 y cuándo repinta.

## Criterios
- `flutter test` 144/144 · `flutter analyze` 0.
- En el dispositivo (Galaxy A54, modo oscuro): splash nativo → splash animado → Inicio.

## Límites
- El ícono de 512 px de la ficha de Google Play llega con `02-02`.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 25-Oct-2026
- **Detalle:** Splash animado por decisión del usuario (25-Oct-2026), aunque la maqueta no lo trae.
