# HU-53 — Guardar productos en favoritos (app, tareas)

## T1 — Detallar la spec y conciliar dependencias
- **Qué:** Fijar requisitos, estados, contrato y pruebas en `spec.md`/`plan.md`; retirar de otras specs la promesa de que HU-53 traería datos locales.
- **Archivos:**
  - `specs/m04-marketplace/HU-53-favoritos/{spec,plan,task}.md`;
  - `specs/phase-02-architecture/02-01-app-foundation/spec.md`, `plan.md` y `task.md`;
  - `specs/phase-02-architecture/02-04-fidelidad-maqueta/spec.md`;
  - `specs/phase-02-architecture/02-06-cache/spec.md` y `task.md`;
  - `specs/m03-listings/HU-06-publicar-producto/spec.md` y `task.md`;
  - `specs/m04-marketplace/HU-09-buscar-productos/spec.md` y `plan.md`;
  - `specs/m04-marketplace/HU-10-filtrar-categoria-precio/spec.md` y `task.md`;
  - `specs/m04-marketplace/HU-11-detalle-producto/spec.md`;
  - `specs/m05-purchase-requests/HU-13-publicar-necesidad/plan.md`;
  - `lib/features/listings/presentation/sell_draft.dart` (se retiró el `NOTE (HU-53)` de datos locales);
  - `specs/m03-listings/HU-50-cantidad-disponible/spec.md` (la relación es con apartados, HU-52).
- **Pasos:** enlazar las filas 79–81 del back; dejar escrito "sin modo sin conexión"; marcar las notas resueltas o fuera del MVP; no cambiar el estado de las specs de otras HU.
- **Verificación:** `grep -rn "HU-53" specs lib` solo muestra las notas que siguen vigentes y las de esta HU.
- **Estado:** ✅ Hecho (09-Nov-2026).

## T2 — Dominio y datos
- **Qué:** Modelos, repositorio HTTP y pruebas de contrato.
- **Crear:**
  - `lib/features/marketplace/domain/favorite_models.dart`;
  - `lib/features/marketplace/domain/favorites_repository.dart`;
  - `lib/features/marketplace/data/http_favorites_repository.dart`;
  - `test/features/marketplace/data/http_favorites_repository_test.dart`.
- **Cambiar:** `lib/core/network/api_paths.dart` con `favorites` y `favorite(productId)`.
- **Pasos:** mapear `available`, `soldOut`, `unavailable` y `product: null`; parsear `savedAt` en UTC; tolerar un elemento inválido; traducir `DioException` con `ApiFailure.fromDio`.
- **Verificación:** `flutter test test/features/marketplace/data/http_favorites_repository_test.dart` en verde (8 pruebas).
- **Estado:** ✅ Hecho (09-Nov-2026).

## T3 — Estado y sesión
- **Qué:** Proveedor global de favoritos, pestaña y fake de pruebas.
- **Crear:**
  - `lib/features/marketplace/presentation/favorites_providers.dart`;
  - `test/features/marketplace/favorites_providers_test.dart`;
  - `test/helpers/fake_favorites_repository.dart`.
- **Pasos:**
  - `favoritesProvider` escucha el `userId` de `sessionControllerProvider`;
  - con visitante devuelve vacío y no llama al repositorio;
  - `toggle`, `add` y `remove` actualizan después de la respuesta y bloquean dobles toques;
  - al cerrar sesión se limpia; al cambiar de cuenta se recarga;
  - `favoriteTabProvider` conserva Todos/Disponibles/Agotados;
  - dejar `NOTE (HU-53)` del tope de 200 sin paginar, con su límite en la spec.
- **Verificación:** `flutter test test/features/marketplace/favorites_providers_test.dart` en verde (11 pruebas), incluido el caso de dos cuentas y una petición en vuelo.
- **Estado:** ✅ Hecho (09-Nov-2026).

## T4 — Corazones en las pantallas existentes
- **Qué:** Conectar el corazón de Inicio, Búsqueda y Producto al estado de favoritos, con el aviso de la maqueta.
- **Crear:** `lib/features/marketplace/presentation/favorites_actions.dart`.
- **Cambiar:**
  - `home_cards.dart` (`SaveButton` con estado y `onSave` por producto);
  - `home_screen.dart`, `search_screen.dart` y `product_screen.dart`;
  - `test/features/marketplace/{home_screen,search_screen,product_screen}_test.dart`.
- **Pasos:**
  - corazón relleno si el id está en `favoritesProvider`;
  - con sesión alterna; sin sesión abre "Crea tu cuenta" y no llama a la API;
  - aviso "Guardaste «…»" con "Ver" y "Lo quitaste de Favoritos" con "Deshacer" (sin "Deshacer" para `unavailable`);
  - un error conserva el estado anterior y muestra el mensaje en español.
- **Verificación:** `flutter test test/features/marketplace/home_screen_test.dart test/features/marketplace/search_screen_test.dart test/features/marketplace/product_screen_test.dart` en verde (7 pruebas nuevas: 3 de Inicio, 1 de Búsqueda y 3 de Producto).
- **Estado:** ✅ Hecho (09-Nov-2026).

## T5 — Pantalla Favoritos, ruta y Perfil
- **Qué:** La pantalla de la maqueta con sus tres estados, la ruta y el mosaico de Perfil.
- **Crear:** `lib/features/marketplace/presentation/favorites_screen.dart` y `test/features/marketplace/favorites_screen_test.dart`.
- **Cambiar:** `lib/app/router.dart`, `lib/features/profile/presentation/profile_screen.dart` y `test/features/profile/profile_flow_test.dart`.
- **Pasos:**
  - `/favoritos` dentro de la rama de Perfil y en `requiresSession`;
  - mosaico "Favoritos" con "1 guardado" o "N guardados" antes de "Privacidad";
  - tabs con conteos, mosaico de dos columnas, vacío por pestaña, cargando y error + "Reintentar";
  - `available` y `soldOut` abren el detalle; `unavailable` muestra "Ya no está disponible", no navega y se quita sin "Deshacer".
- **Verificación:** `flutter test test/features/marketplace/favorites_screen_test.dart test/features/profile/profile_flow_test.dart` en verde (10 pruebas nuevas: 9 de Favoritos y 1 de Perfil); sin overflow a 360×640 y en tablet, con contraste AA.
- **Estado:** ✅ Hecho (09-Nov-2026).

## T6 — Evidencia, documentación y cierre
- **Qué:** Capturas, comandos completos, trazabilidad y revisión.
- **Cambiar:** `tool/screenshots_test.dart`, `docs/trazabilidad.md` y `Memoria.md`.
- **Pasos:**
  - escena `favoritos` en claro y oscuro, comparada con la maqueta;
  - `dart format`, `flutter analyze`, `flutter test`, `critic` y `semgrep`;
  - fila de `docs/trazabilidad.md` con las pruebas reales y estado "Borrador con evidencia";
  - `security-reviewer` y `traceability-clerk` antes del PR;
  - PR #44 (`feature/SCRUM-68-favoritos`); no hay PR del back todavía.
- **Verificación:** `flutter test` 454/454, analyze 0, format 0, critic PASS, capturas `favoritos`/`favoritos-dark` (1170×2532), APK debug compilado, `security-reviewer` PASS y `semgrep` PASS en el CI del PR #44.
- **Estado:** ✅ Hecho (09-Nov-2026).

## Pendientes con dueño
| Pendiente | Dueño |
|---|---|
| Desplegar la API `0.5.0-alpha.12` antes de publicar la app | `musubi-api:HU-53` / despliegue |
| Paginar la lista si alguien supera 200 favoritos; hoy es `NOTE (HU-53)` | HU posterior |
| Revisor de la spec (1 integrante distinto del autor) | Usuario |
| "Bajó $" y avisos de favorito agotado | Fuera del MVP; HU posterior |
