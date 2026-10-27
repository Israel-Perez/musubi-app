# 02-04 — Fidelidad con la maqueta (tareas)

## T1 — Tokens, tipografía e íconos
- **Crear:** `svg_path.dart`, `musubi_icon.dart`, `musubi_icons.dart` y `assets/licenses/lucide.txt`.
- **Cambiar:** `musubi_tokens.dart` y `app_theme.dart`.
- **Verificar:** `svg_path_test.dart` y `app_theme_test.dart`.
- **Estado:** ✅ Hecho (26-Oct-2026).

## T2 — Componentes de la maqueta
- **Crear:** `pressable.dart`, `otp_field.dart`, `musubi_controls.dart`, `musubi_sheet.dart`, `musubi_dialog.dart`, `musubi_snack.dart`, `skeleton.dart`, `shake.dart`, `top_bar.dart` y `avatars.dart`.
- **Cambiar:** `musubi_button.dart`, `musubi_text_field.dart` y `feedback_views.dart`.
- **Verificar:** `widgets_test.dart` (16).
- **Estado:** ✅ Hecho (26-Oct-2026).

## T3 — Pantallas de cuenta
- **Alcance:** Iniciar sesión, Registro, Verificación, Bienvenida, Recuperar contraseña, Aviso de privacidad y Términos.
- **Crear:** `auth_layout.dart` y `email_inbox.dart` (con `MainActivity.kt`).
- **Agregar:** `SessionProfile` en la sesión.
- **Verificar:** `auth_flow_test.dart`, `session_flow_test.dart` y `session_test.dart`.
- **Estado:** ✅ Hecho (26-Oct-2026).

## T4 — Inicio, hoja "Crea tu cuenta" y vitrina de muestra
- **Inicio:**
  - visitante y con sesión;
  - estados de carga y de error;
  - hoja "Filtrar".
- **Hoja "Crea tu cuenta":** las 9 ilustraciones.
- **Vitrina de muestra:** `DemoCatalogRepository` con `DEMO_CATALOG` (solo dev).
- **Verificar:** `home_screen_test.dart`, `demo_catalog_repository_test.dart`, `visitor_flow_test.dart` y `app_config_test.dart`.
- **Estado:** ✅ Hecho (26-Oct-2026).

## T5 — Perfil y Ajustes
- **Alcance:**
  - Perfil con la cuenta verificada;
  - Ajustes (`/ajustes`) con cuenta, ayuda y legal;
  - "Cerrar sesión" con su diálogo.
- **Verificar:** `navigation_test.dart` y `session_flow_test.dart`.
- **Estado:** ✅ Hecho (26-Oct-2026).

## T6 — Evidencia
- **Capturas:** `tool/screenshots_test.dart` en claro y oscuro, comparadas con la maqueta.
- **Verificación completa:** format, analyze, test, critic (pwsh y 5.1) y APK de debug.
- **Estado:** ✅ Hecho (26-Oct-2026).

## Pendientes
- `NOTE (HU-06)`: retirar o conservar la vitrina de muestra cuando exista el catálogo real.
- `NOTE (HU-09)`, `NOTE (HU-10)`: Búsqueda y sus filtros (la hoja "Filtrar" ya existe en Inicio).
- `NOTE (HU-15)`: "Se busca" del visitante (`Se-busca-visitante`).
- `NOTE (HU-31)`: Notificaciones (la campana ya abre `/notificaciones`).
- `NOTE (HU-04)`: Perfil completo (calificaciones, ventas y apartados).
- `NOTE (HU-49)`: Recién publicados completo con "Más antiguas".
- `NOTE (HU-53)`: guardar desde la vitrina.
- `NOTE (HU-54)`: modo noche manual y preferencias en Ajustes.
