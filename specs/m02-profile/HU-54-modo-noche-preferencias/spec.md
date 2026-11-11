# HU-54 — Elegir modo noche y preferencias (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-54 / SCRUM-71 / Sprint 4 / M-02 / [musubi-api:HU-54](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m02-profile/HU-54-modo-noche-preferencias)

## Contexto
Jira (SCRUM-71): Como **usuario**, quiero **cambiar entre modo claro y modo noche y ajustar mis preferencias**, para **usar la app con comodidad a cualquier hora**.

- Maqueta: `Ajustes`.
- **Depende de:** `02-01`, `02-03`, `02-04`, `HU-04` y `musubi-api:HU-54`.

## Requisitos
1. En `Ajustes` · "Preferencias", el interruptor "Modo noche" de la maqueta: encendido es modo noche y apagado, modo claro. Si la cuenta aún no elige, la app sigue el tema del sistema y el interruptor muestra el tema que se ve.
2. Aplicar la paleta oscura existente con contraste AA (RNF-20).
3. Guardar la selección en la preferencia de la cuenta para recuperarla tras cerrar y abrir la app y sincronizarla entre sesiones.
4. Mostrar errores de carga/guardado en español y permitir reintentar; no perder la preferencia ya cargada si falla una actualización.

## Diseño
- `lib/features/profile/`: modelo `ThemePreference`, repositorio HTTP y provider Riverpod con estado inicial del sistema.
- Consumir `GET/PUT /api/v1/profiles/me/preferences` de `musubi-api:HU-54`; la app no duplica DTOs ni códigos.
- `MusubiApp` aplica `ThemeMode` desde el provider; `Ajustes` agrega la sección "Preferencias" con la fila "Modo noche" y su interruptor (`DarkModeRow`), como la maqueta, y el aviso "Modo noche activado" o "desactivado".
- Actualización optimista con rollback al error; para cuenta sin sesión, mantener el modo de sistema y no enviar requests autenticados.

## Contratos
- [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), filas M-02 GET/PUT `/profiles/me/preferences` (HU-54), enlazadas desde `lib/core/network/api_paths.dart`.
- JSON `{ theme: system|light|dark }`; no se copian DTOs ni catálogo de errores.

## Tests
- `test/features/profile/http_theme_preference_repository_test.dart`: HTTP, JSON y errores.
- `test/features/profile/profile_flow_test.dart`: carga, persistencia, rollback, valores predeterminados, el interruptor "Modo noche" (tema que se ve, guardado y aviso) y el reintento.
- `test/core/theme/app_theme_test.dart`: contraste AA en las dos paletas.

## Criterios
- [x] El interruptor "Modo noche" de Ajustes cambia entre claro y oscuro en toda la app; sin elegir, sigue el sistema.
- [x] Contraste del tema oscuro cumple RNF-20 (≥ 4.5:1 en pares de texto medidos por `app_theme_test.dart`).
- [x] GET carga la preferencia de la cuenta; la app la solicita al iniciar sesión, PUT la persiste y el fallo de guardado revierte y permite reintentar. Persistencia API y carga del cliente están verificadas por sus pruebas de componente/flujo; no se afirma una prueba E2E de cierre y reinicio del proceso.
- [x] `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos --fatal-warnings`, `flutter test` y critic PASS.

## Límites
- Las preferencias de notificaciones por tipo quedan fuera porque Jira deja su alcance MVP pendiente.
- Volver a "seguir el sistema" después de elegir no tiene control en la maqueta: la API lo admite (`system`), pero la app no lo ofrece.
- Los interruptores de "Notificaciones" por tipo de la maqueta (coincidencias, mensajes y pedidos) no se muestran: necesitan su contrato en la API (`NOTE (HU-54)`).
- La cuenta visitante no sincroniza la preferencia; usa el modo del sistema. No se añade un paquete de persistencia local.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 revisor distinto del autor)
- **Fecha:** 10-Nov-2026
- **Detalle:** alcance detallado desde SCRUM-71; la preferencia se guarda por cuenta mediante la API; no se incluyen preferencias de notificaciones no definidas en Jira. **11-Nov-2026 (revisión):** el selector de tres opciones se cambió por el interruptor "Modo noche" de la maqueta (`Ajustes` · "Preferencias"), con su aviso, para cumplir la fidelidad con la maqueta. Jira sigue en «Por hacer» con sus criterios sin marcar; esta evidencia técnica no aprueba ni transiciona el ticket, que queda para el responsable.
