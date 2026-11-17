# plan.md — HU-41 Gestionar categorías (app)

## Componentes
- `lib/features/admin/`:
  - `domain/admin_models.dart`: `AdminCategory` y el largo del nombre (2 a 40).
  - `domain/admin_repository.dart` y `data/http_admin_repository.dart`: `categories`, `createCategory` y `updateCategory`.
  - `presentation/admin_providers.dart`: `adminCategoriesProvider` y `refreshCategories`.
  - `presentation/admin_categories_screen.dart`: `AdminCategoriesScreen` y `CategorySheet`.
- `lib/core/network/api_paths.dart`: `adminCategories` y `adminCategory(slug)`.
- `lib/app/router.dart`: `AppRoutes.adminCategories`.
- `lib/features/profile/presentation/settings_screen.dart`: la fila "Categorías" en "Administración".
- `test/helpers/fake_admin.dart`: `seedCategories()` y las categorías del fake.

## Decisiones
- **Una fila más en "Administración"** y no una pestaña en `AdminScreen`. Las pestañas de esa pantalla son bandejas de moderación; las categorías son otro tema.
- **"Desactivar" pide confirmación y "Activar" no.** Desactivar quita la categoría de `Vender-3` y "Filtrar"; activarla no quita nada.
- **Al guardar el mismo nombre se cierra la hoja sin llamar a la API.** La API respondería `admin.no_category_changes` y no hay nada que avisar.
- **Después de un cambio se invalidan las categorías públicas** (`categoriesProvider` y `sellCategoriesProvider`). Así, en el mismo teléfono, `Vender-3` y "Filtrar" ya no muestran una desactivada.
- **El nombre se valida en la app (2 a 40) y la API decide el resto** (repetidas, la última activa, 30 por campus): el mensaje de la API se muestra en la hoja.

## Guardarraíles
- La fila solo sale con `isAdminProvider`. La API vuelve a revisar el rol y la cuenta en cada llamada.
- Pantalla → provider → `AdminRepository`; los errores de red llegan como `ApiFailure` con mensaje en español.

## Validación
`flutter test` (las pruebas de `spec.md` → Tests), `flutter analyze` y critic. La prueba en el celular necesita la API `0.5.0-alpha.39` desplegada y una cuenta en `Admin:Emails`.

## Secuencia
1. Modelo, repositorio y su prueba con `FakeHttpAdapter`.
2. Providers, pantalla, hoja, ruta y fila de `Ajustes`.
3. Widget tests, documentos y PR (apilado sobre el de HU-39/40, #78).
