# HU-41 — Gestionar categorías (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-41 / SCRUM-64 / Sprint 5 (23 nov – 4 dic 2026) / M-14 / [musubi-api:HU-41](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-41-gestionar-categorias)

## Contexto
Jira (SCRUM-64): Como **administrador**, quiero **gestionar las categorías**, para **mantener organizada la plataforma**.

- Maqueta: sin pantalla propia. Se diseña con la guía de estilo de la maqueta; el lineamiento 4 permite agregar, nunca quitar.
- Trazabilidad: RF-56 · CU-26.
- Origen: Propuesta inicial §11.

**Depende de:** `HU-39` ("Administración" en `Ajustes`, `isAdminProvider`, `AdminRepository`), `HU-06` (`Vender-3`), `HU-10` ("Filtrar"), `HU-66` ("Mis intereses").

## Requisitos
1. "Categorías" sale en `Ajustes` → "Administración" solo con el rol `admin`.
2. La pantalla lista todas las categorías del campus con su estado ("Activa" o "Desactivada").
3. "Agregar categoría" pide el nombre (2 a 40 caracteres). Sin un nombre válido no se manda.
4. Al tocar una categoría se abre "Editar categoría": cambiar el nombre, "Desactivar categoría" (con confirmación) o "Activar categoría".
5. Después de un cambio, `Vender-3`, "Filtrar" e "Intereses" vuelven a pedir las categorías: solo salen las activas.
6. Los errores de la API (`admin.category_exists`, `admin.last_category` y los demás) se muestran en la hoja.

## Diseño
- `AdminCategoriesScreen` y `CategorySheet` en `lib/features/admin/presentation/admin_categories_screen.dart`, con las piezas de "Administración" (`AdminCard`, `StatusPill`) y `MusubiPanel`.
- Ruta `AppRoutes.adminCategories` (`/ajustes/administracion/categorias`); la guarda de sesión ya cubre `/ajustes/administracion/*`.
- `AdminRepository.categories`, `createCategory` y `updateCategory`; `adminCategoriesProvider` y `refreshCategories`, que también invalida `categoriesProvider` y `sellCategoriesProvider`.

## Contratos
Filas "M-14" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`GET` y `POST /admin/categories`, `PATCH /admin/categories/{slug}`), enlazadas desde `ApiPaths.adminCategories` y `adminCategory`. Formas de `admin-category.json` y `admin-category-page.json`.

## Tests
- `test/features/admin/http_admin_repository_test.dart`: la lista con las desactivadas, agregar (nombre sin espacios) y cambiar (solo lo que cambia).
- `test/features/admin/admin_categories_test.dart`: sin el rol no se ve; la lista; agregar; nombre corto; renombrar; desactivar con confirmación y activar sin ella; el error de la API en la hoja; sin conexión y "Reintentar".

## Criterios
- [x] El administrador puede crear, editar y desactivar categorías: `admin_categories_test` ("Agregar categoría", "renombrar", "desactivar pide confirmación").
- [x] Las categorías activas son las que aparecen al publicar productos y solicitudes, y en los filtros: `refreshCategories` vuelve a pedir `GET /categories`, que en la API solo da las activas (`musubi-api:HU-41`, `CategoryAdminFlowTests`).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 809/809 · critic PASS (16-Nov-2026).

## Límites
- No se borran ni se reordenan categorías (decisión de `musubi-api:HU-41`).
- El rol sale del token: después de dar el rol hay que volver a iniciar sesión o esperar la renovación (HU-39).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 revisor distinto del autor)
- **Fecha:** 16-Nov-2026
- **Detalle:** la spec ligera del 29-Oct-2026 se detalló al implementar. Necesita la API `0.5.0-alpha.39`.
