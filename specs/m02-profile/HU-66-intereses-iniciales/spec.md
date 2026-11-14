# HU-66 — Elegir mis intereses la primera vez que entro

**HU / Jira / Sprint / Módulo / Contraparte:** HU-66 / SCRUM-106 / Sprint 5 / M-02 / [musubi-api:HU-66](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m02-profile/HU-66-intereses-iniciales)

## Contexto
Jira (SCRUM-106): Como **estudiante nuevo**, quiero **elegir las categorías que me interesan al entrar por primera vez**, para **ver desde el inicio productos que me sirven**.

- Maqueta: **no tiene la pantalla** (Jira lo deja pendiente). Se arma con piezas de la maqueta: el esqueleto de `Verificacion-lista` (`AuthLayout`), los chips de `Necesidad-1` (`NeedChip`) y una fila de `Ajustes` (`SettingsRow`).
- Trazabilidad: RN-46 · alimenta HU-35 ("Para ti") y HU-60 · RNF-07.
- **Depende de:** `musubi-api:HU-66` (filas `GET`/`PUT /api/v1/profiles/me/interests` de [`endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md)), HU-03 (verificación), HU-10 (`categoriesProvider`).

## Requisitos
1. Después de verificar el correo, "Empezar a explorar" (`Verificacion-lista`) abre "¿Qué te interesa?" con las categorías del campus como chips.
2. Es opcional: "Ahora no" (o "Continuar" sin elegir) sigue sin guardar nada; "Continuar" con algo elegido lo guarda. Las dos siguen a donde iba la persona al crear la cuenta (HU-48).
3. `Ajustes` → Preferencias → "Mis intereses" muestra cuántas hay ("Sin elegir", "1 categoría", "N categorías") y abre la misma pantalla con lo guardado; "Guardar" los reemplaza.
4. La pantalla dice que son privados ("Solo tú las ves: no salen en tu perfil.").
5. Un error al guardar se queda en la pantalla con el aviso y lo elegido; sin poder leer lo guardado, ofrece "Reintentar" sin dejar editar.

## Diseño
- `lib/features/profile/`: `domain/interests_repository.dart`, `data/http_interests_repository.dart` (forma inesperada → `ApiFailure`), `presentation/interests_providers.dart` (`interestsRepositoryProvider`, `myInterestsProvider`) e `interests_screen.dart` (`InterestsScreen(onboarding:)`).
- Rutas con sesión: `AppRoutes.interests` (`/intereses`) y `AppRoutes.settingsInterests` (`/ajustes/intereses`). `ApiPaths.myInterests`.
- Desde `Ajustes`, "Regresar" y "Guardar" vuelven con `pop` o, si se abrió con un enlace, con `go(AppRoutes.settings)`.

## Tests
- `test/features/profile/http_interests_repository_test.dart`: GET, PUT, forma inesperada y `profiles.invalid_interest`.
- `test/features/profile/profile_flow_test.dart` (grupo "Intereses (HU-66)"): Ajustes elige, guarda y resume; parte de lo guardado y se vacía; error al guardar; error al leer y reintentar; al entrar "Ahora no", "Continuar" con y sin elegir.
- `test/features/auth/presentation/auth_flow_test.dart` y `test/features/marketplace/visitor_flow_test.dart`: después de verificar sale "¿Qué te interesa?" y al saltarla se vuelve a donde se estaba.
- Capturas: `tool/screenshots_test.dart` escenas `intereses` y `mis-intereses`.

## Criterios
- [x] Pantalla opcional después de verificar el correo, con las categorías como chips: `auth_flow_test.dart`, grupo HU-66 de `profile_flow_test.dart`.
- [x] Se guardan en la cuenta y se cambian en Ajustes: grupo HU-66 de `profile_flow_test.dart` y `musubi-api:HU-66`.
- [ ] HU-35 los usa en el arranque en frío (RN-46): "Para ti" todavía no existe (`NOTE (HU-35)` en la API).
- [x] Privados (RNF-07): la API no los pone en el perfil público (`musubi-api:HU-66`) y la pantalla lo dice.
- [x] `dart format` sin cambios, `flutter analyze --fatal-infos --fatal-warnings` sin observaciones y `flutter test` 676/676 (con HU-35 de `main`).

## Límites
- Se muestra una vez, justo después de verificar. Quien la saltó la encuentra en `Ajustes`; no se vuelve a preguntar.
- Sin modo sin conexión: sin red, el aviso de error deja reintentar.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 revisor distinto del autor)
- **Fecha:** 14-Nov-2026
- **Detalle:** el diseño de la pantalla (pendiente en Jira) se armó con piezas de la maqueta; lo revisa la usuaria. La app no sube de versión (se publica en lote).
