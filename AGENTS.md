# AGENTS.md — Guía operativa de musubi-app para agentes y desarrolladores

> Qué no se negocia: `.specify/memory/constitution.md` (manda ante cualquier conflicto).
> Principios y stack: `specs/phase-00-constitution/00-01-principles-stack/spec.md`. No se agregan paquetes fuera del stack sin la regla de excepción de 00-01.
> Repo hermano: [`musubi-api`](https://github.com/Israel-Perez/musubi-api) (back .NET 10). El contrato HTTP canónico es `musubi-api/docs/endpoints.md`: aquí se enlaza, nunca se copia.

## 1. Forma de trabajo

- **Setup:** Flutter 3.47.7 (stable), JDK 17 y Android SDK (platform `android-36`, build-tools 36.1.0, NDK 28.2.13676358). En Windows, instala los paquetes con `android sdk install "<paquete>"` (`sdkmanager.bat` parte los argumentos en `;`).
- `Copy-Item config/dev.example.json config/dev.json` → `flutter run --dart-define-from-file=config/dev.json` (emulador contra musubi-api local en `http://10.0.2.2:5080`). Con un celular por USB: `adb reverse tcp:5080 tcp:5080` y `config/usb.json` (`http://localhost:5080`).
- **Comandos:**
  - `dart format --output=none --set-exit-if-changed .`
  - `flutter analyze --fatal-infos --fatal-warnings`
  - `flutter test`
  - `flutter build apk --debug --dart-define-from-file=config/dev.example.json`
  - `pwsh scripts/critic-guardrails.ps1`
  - `pwsh scripts/run_integration_tests.ps1` (02-10: levanta `../musubi-api`, corre `test/integration` contra ella y el guard de cobertura)
  - `pwsh scripts/run_device_tests.ps1` (02-10: la suite de `integration_test/` en un teléfono físico por USB contra `../musubi-api`; guía en `integration_test/README.md`)
- **CI (`ci-pr.yml`):** `analyze`, `test` (cobertura como artefacto), `integration` (contra musubi-api real: la rama del mismo nombre o `main`), `critic`, `gitleaks` (secretos en el historial, 02-10), `semgrep`; `build-apk` solo en push a `main`.
- **Flujo SDD por HU:** spec (`specs/mNN-<modulo>/HU-NN-<slug>/`, misma carpeta que en el back; skill `spec-first-writing`) → `slice-scaffolder` (Fase A) → implementación y pruebas (skill `vertical-slice`) → `security-reviewer` → `traceability-clerk` → PR que enlaza el PR del back.
- **Ramas y PR:** `feature/SCRUM-NN-slug` / `fix/SCRUM-NN-slug`; un PR = una HU o un fix; título con la clave Jira; checklist de `.github/pull_request_template.md` obligatorio.
- **Naming:** código en inglés; textos de la UI, documentos y specs en español.
- Sin secretos (todo lo que va en el APK es público), sin `TODO` (solo `NOTE (ID)`), sin `print`, sin código muerto.
- Al terminar, resume qué cambiaste y qué decisiones debe revisar el usuario.

## 2. Memoria

> **Gobernanza SDD:** plantilla obligatoria en `specs/_template.md` y DoD en `specs/phase-00-constitution/00-02-sdd-governance/spec.md`. Cada spec nueva sigue la plantilla; los criterios siempre se verifican con un comando o una prueba.

- `AGENTS.md`: manual operativo vivo. `Memoria.md`: bitácora del estado, las decisiones y las lecciones.
- **Al empezar**, lee `Memoria.md`.
- **Al terminar una tarea**, actualízala: estado actual, decisiones importantes (con su porqué) y errores a evitar.
- **Al cerrar una spec**, concilia `spec.md`/`plan.md`/`task.md` con lo implementado y resuelve la aprobación: "Borrador con evidencia", o "Aprobado" solo si el usuario indicó un revisor.
- Mantenla breve (máximo ~10 000 líneas). Las reglas permanentes se mueven a `AGENTS.md` o a `00-04`.
- Nunca guardes datos sensibles.
- Si cambias una **sección compartida** (`<!-- Sección compartida … -->`), cámbiala también en `musubi-api`, regístralo en las dos `Memoria.md` y corre `pwsh scripts/check_shared_sections.ps1`.

## 3. Límites

- No pongas secretos en el código, los assets, `config/*.json` ni `--dart-define`: las llaves privadas viven solo en `musubi-api`.
- No escribas `http://` en `lib/` (la URL de dev vive en `config/`).
- No empieces un comentario con la palabra "todo" en español: `flutter_style_todos` rompe el análisis.
- No llames a Dio desde la UI: pantalla → provider → interfaz del repositorio.
- No dejes que una excepción de red llegue a la UI: tradúcela a un estado de dominio con mensaje en español.
- No copies el catálogo del back (DTOs, códigos) en las specs: enlaza la fila.
- No des por bueno un build mirando el exit code de un pipe (`| tail`): revisa el de Flutter.
- Versiona solo `config/*.example.json`; los reales y los archivos de Firebase están ignorados.
- Siempre: actualiza `Memoria.md` al terminar cada tarea.

## 4. Verificación

- `dart format` sin cambios y `flutter analyze --fatal-infos --fatal-warnings` sin observaciones.
- `flutter test` 100 % en verde.
- `pwsh scripts/run_integration_tests.ps1` → `integration: OK` (02-10). Una llamada nueva a la API necesita su flujo en `test/integration/`; si no, `tool/check_integration_coverage.dart` falla.
- `pwsh scripts/critic-guardrails.ps1` → `PASS` exit 0 (también con `powershell -File` en 5.1).
- `flutter build apk --debug --dart-define-from-file=config/dev.example.json` → `√ Built`; si tocas Android, revisa el APK con `aapt2 dump badging` (paquete `com.musubi.app`, `targetSdkVersion:'36'`).
- YAML del CI: `python -c "import yaml; yaml.safe_load(open('.github/workflows/ci-pr.yml'))"` y `actionlint .github/workflows/ci-pr.yml`.
- SAST antes del primer push de una rama: `semgrep scan --config=auto --config=.semgrep/semgrep.yaml --error`.

### 4.2 Requerimientos no funcionales

Tabla y comandos: `specs/phase-00-constitution/00-03-nfr/spec.md`. Si un cambio impacta un umbral (tiempo de carga, tamaño de foto, contraste), ejecuta su verificación antes de pedir la aprobación.

### 4.3 Configuración

Claves y estado: `specs/phase-01-foundation/01-04-config-reference/spec.md` + `config/README.md`.

## 5. Convenciones técnicas

> Fase 01 implementada (15-Oct-2026), en "Borrador con evidencia".

- Feature-first: `lib/app/`, `lib/core/{config,network,errors,theme}`, `lib/features/<modulo>/{domain,data,presentation}` (ver `lib/features/README.md`).
- Patrón de referencia: `lib/features/status/` (repositorio + fake + provider + estados de UI).
- Rutas de la API en `lib/core/network/api_paths.dart`, cada una citando su fila del catálogo del back (skill `api-contract`).
- Riverpod 3 sin codegen; go_router; dio; Material 3; `es-MX`.
- Dart 3.13 + very_good_analysis 11: constructores `const new(...)` (`dart fix --apply`).
- **Base 02-01:** colores y medidas con `context.musubi` y `MusubiSizes` (nunca números sueltos); componentes en `lib/core/widgets/`; errores con `ApiFailure.fromDio` (decidir por `code`); peticiones con sesión por `dioProvider` y públicas por `publicDioProvider`; rutas y guardia en `lib/app/router.dart`.
- **Maqueta:** `docs/maqueta/` (60 pantallas). La app es igual a la maqueta y no se le quitan funciones (lineamiento 4); cada spec de HU cita sus pantallas por ID (índice en `docs/maqueta/README.md`).
- **Piezas de la maqueta (02-04):**
  - textos con `MusubiType.style(size, line:, em:)`, con altura de línea y espaciado explícitos; `CssLineBox` para `line-height: normal` en columnas;
  - íconos con `MusubiIcon(MusubiIcons.x)` (Lucide desde el SVG de la maqueta), nunca `Icons.*`;
  - toques con `Pressable` o `MusubiButton`, sin onda;
  - hojas con `showMusubiSheet`; hojas con título, X y acciones (`UI.sheet`) con `showMusubiPanel` + `MusubiPanel` y listas de opciones con `MusubiOptions`; diálogos con `showMusubiDialog` y avisos con `showMusubiSnack`.
  - Para comparar con la maqueta: `flutter test tool/screenshots_test.dart --dart-define=SHOTS=<carpeta>`.
- **Versión:** `version` de `pubspec.yaml`, alineada con `docs/versionado.md` (lo verifica `test/versioning_test.dart`).
- **Lineamientos de la materia:** checklist L-NN en `musubi-api/docs/bitacora/lineamientos-materia.md`.
- Chat (HU-20, HU-22): `lib/features/chat/`; tiempo real con `SignalRChatRealtime` (protocolo JSON de SignalR sobre `dart:io`, sin paquete).
- Reportar y bloquear (HU-28, HU-57): `lib/features/reputation/`; `showReportSheet` desde el chat y Ajustes, `showBlockedUsersSheet` desde Privacidad; con un bloqueo, el chat cambia la caja de texto por un aviso (`Conversation.canReply`).
- Solicitudes de compra (HU-13): `lib/features/purchase_requests/` (clases `Wanted*`, como en la API); los pasos reutilizan `SellStepLayout` (`steps`, `heading`, `onSave`, `top`) y Mis solicitudes vive en la rama de Perfil.
- "Yo tengo este producto" (HU-16): `showOfferSheet` (vincular o oferta directa) y `showOfferSentSheet` en `lib/features/purchase_requests/presentation/offer_sheet.dart`; la foto usa la subida de los productos (HU-06).
- Ofertas recibidas (HU-17): `ReceivedOffersSection` en `Mis-solicitudes` (`received_offers.dart`, orden con `sortOffers`); el chat de una oferta usa `ChatContext.isOffer` y `ChatScreen.draft` (el saludo al aceptar).
- Gestionar una solicitud (HU-14): "Cambiar" abre "Tu solicitud" (`MyWantedScreen._manage`). "Editar solicitud" reutiliza `Necesidad-1…3` con `editing: true`, rutas `AppRoutes.editNeed*` y su propio borrador (`needEditDraftProvider`, `need_edit.dart`) para no pisar el de publicar.
- Pedidos (HU-23): `lib/features/orders/`. En el chat, "Resumir acuerdo" abre `showOrderSummary` (resumen sin IA: cantidad, entrega y fecha) para quien compra; con un pedido abierto (`openOrderProvider`) el aviso cambia a "Pedido #MS-NNNN" y abre `OrderPaymentScreen` (`AppRoutes.order`, `Pedido-pago`).
- Reseña en Google Play (HU-67): al cerrar "Calificar" de un pedido completado (enviar, "Ahora no" o X; si la calificación falló, no pide), `reviewPrompterProvider` pide la In-App Review una vez cada 90 días por dispositivo (canal nativo `musubi/review` + Play Core `review:2.0.2`); si Play no la muestra, no avisa.
- Acuerdo con IA (HU-32/33/34): `lib/features/genai/`. "Resumir acuerdo" (los dos) pide la propuesta (`HttpAgreementRepository`, 30 s), la primera vez con `confirmAiNotice` (`AiNoticeStore`), y abre `showAgreementSheet` (`Acuerdo-esperando` / `Acuerdo-confirmado`, con `SummaryField` y los paneles de HU-23). Con `genai.unavailable`, quien compra cae al resumen a mano. `agreementProvider` y la hoja se recargan con `ChatRealtime.agreementChanges`; los avisos del chat (`ChatMessage.notice`) van centrados.
- Tablero "Se busca" (HU-15): `WantedBoardScreen` (con sesión `Se-busca`, sin ella `Se-busca-visitante`), filtros en `wantedBoardFilterProvider` y páginas en `wantedBoardProvider`; listas de varias opciones con `MusubiMultiOptions`.
- Avisos (HU-31): `lib/features/notifications/`. `pushCoordinatorProvider` (lo enciende `MusubiApp`) registra el FID con sesión y permiso, da de baja al cerrar sesión, abre lo que trae un push y muestra el snack con la app abierta (`scaffoldMessengerKeyProvider`). El permiso se pide en contexto con `askForPushInContext` (primer mensaje y publicar una solicitud). Sin `google-services.json` la app funciona sin push.
- Apoyo a vendedores (HU-36/37/38): `lib/features/seller_support/`. `SlowListingsPanel` ("Llevan tiempo sin venderse") va en "Activos" de `Mis-productos` (`slowListingsProvider`; si falla, la pantalla sigue sin él); `showSalesTipsSheet` ("Ideas para vender más rápido", con "Nombre y descripción con IA": `POST /products/{id}/ideas` a petición y "Usar en mi publicación" llena la edición) y `showDemandSheet` ("Quienes la buscan", que abre `showOfferSheet` de HU-16 ahí mismo). `PublishedDemandCard` en `Vender-listo`.
- Intereses (HU-66): `InterestsScreen` en `lib/features/profile/presentation/`; con `onboarding` sale después de `Verificacion-lista` ("Empezar a explorar") y se puede saltar; sin él es "Mis intereses" de `Ajustes`.
- Pagos (HU-55, D-01): `lib/features/orders/`. `OrderPaymentScreen` elige el bloque por estado (`Pedido-pago` con la transferencia elegida si quien vende tiene cuenta, `Pago-validando`, `Pago-vendedor`, `Pedido-entrega` con la franja de pago validado y `Pedido-efectivo` con el código); `TransferScreen` (`AppRoutes.transfer`) es `Pago-transferencia` y `PayoutAccountScreen` (`AppRoutes.settingsPayouts`, desde `Ajustes`) es `Cuenta-pagos`. Las piezas viven en `payment_widgets.dart`. NOTE (HU-55): el comprobante.
- Comparar y "Avísame" (HU-51): `lib/features/marketplace/`. `CompareSection` (con sesión, después de quien vende en `Producto`) pide `comparisonProvider` y ordena en `Comparison.ranked` con las reglas de `compareVals` de la maqueta ("Para ti", Reputación, Ventas y Precio; insignias y barra de precios). "Avísame" ↔ "Te avisaremos" usa `stockAlertProvider` y `ComparisonRepository.watch/unwatch`; sin cuenta abre `AccountGateMotive.alert`. "Ver todas" abre `SearchScreen(initialFilter:)` por `extra`.
- Insignias de confianza (HU-64): `PublicProfile.responseLabel` ("Responde en ~1 h", redondeo `approxDuration` de la maqueta) y `PublicProfile.trusted` (`TrustedBadge`) salen de la API; van en la tarjeta de quien vende de `Producto` y en los chips de `Perfil-vendedor`. Sin datos no se muestran.
- Apartados (HU-52): `lib/features/orders/`. "Apartar" de `Producto` abre `showReserveSheet` (horas de `PickupSlots` y puntos del campus) y luego `ReservationScreen` (`Apartado-listo`, QR con `qr_flutter`). `MyReservationsScreen` (`AppRoutes.myReservations`, y `MyReservationsTile` en `Perfil`); quien vende verifica en `VerifyBuyerScreen` (cámara de `qrCameraProvider` con `mobile_scanner`, o el código) y entrega en `BuyerVerifiedScreen`. `codeFromQr` solo acepta el QR del apartado abierto.
- Moderación y categorías (HU-39/40/41): `lib/features/admin/`.
  - "Administración" sale en `Ajustes` solo si `isAdminProvider`; `SessionTokens.isAdmin` lee el `role` del JWT, como `userId` lee el `sub`.
  - `AdminScreen` (`AppRoutes.settingsAdmin`) tiene las pestañas "Abiertos", "Revisados" y "Suspendidas".
  - `showAdminReportSheet` descarta o marca procedente; con una publicación, "Retirar publicación" pide confirmación.
  - `AdminAccountScreen` (`AppRoutes.adminAccount`) suspende con motivo o reactiva.
  - "Categorías" (HU-41): `AdminCategoriesScreen` (`AppRoutes.adminCategories`) agrega, renombra, desactiva y activa; `refreshCategories` también invalida `categoriesProvider` y `sellCategoriesProvider`.
  - La API vuelve a revisar el rol en cada acción.
- Precio sugerido (HU-58): el modelo de ML está en la API. En `Vender-3`, `priceSuggestionProvider` (`PriceQuery`: nombre, categoría y estado del borrador) da "Precio sugerido: $X – $Y" en la misma tarjeta de la maqueta (`_PriceRangeCard` con `suggestion`); sin rango queda el de la categoría (`priceRangeProvider`). En "Compara antes de comprar", `priceEstimateProvider` agrega la fila "Musubi estima $X – $Y para algo así · veredicto" debajo de la regla de la maqueta. Nunca cambia el precio (RN-38).
- Entrega (HU-62): `lib/features/orders/presentation/delivery_actions.dart`. En un pedido confirmado, `DeliveryCard` (debajo del producto en `Pedido-pago`) dice cuándo y dónde, con "Agregar al calendario" (`deviceCalendarProvider`: canal `musubi/calendar`, `Intent.ACTION_INSERT` sin permiso) y, desde 2 h antes (`Order.canSayArrived`), "Ya llegué" (`POST /orders/{id}/arrived`); en el chat, `ArrivalBar` sale arriba de la caja de texto en esa misma ventana. El recordatorio de una hora antes es un push de la API (`delivery_reminder`).
- Pendientes con dueño: Crashlytics → 02-01; datos locales → HU-53; firma de subida → 02-02.

## 6. Seguridad (OWASP MASVS)

- MASVS-STORAGE: nada sensible en el APK; tokens en `flutter_secure_storage` (02-01); `allowBackup=false` y permisos aprobados verificados por `test/security/android_config_test.dart`.
- MASVS-NETWORK: el token solo viaja al esquema, host y puerto de la API (`AuthInterceptor`, con self-test).
- MASVS-AUTH (02-10): el logout manda también el access token para que la API lo revoque de inmediato (lista de revocación en Redis); `test/security/session_security_test.dart` cuida dónde viven los tokens (lista permitida de archivos), que nada los registre y que un error no los muestre.
- MASVS-NETWORK: HTTPS fuera de dev (`AppConfig.parse`); release sin tráfico en claro; debug/profile solo hacia `10.0.2.2` (emulador) y `localhost` (USB con `adb reverse`).
- MASVS-CODE: análisis estricto, Dependabot con `cooldown`, paquetes evaluados (00-01); gitleaks revisa el historial completo en el CI. Las excepciones van en `.gitleaksignore` con su motivo.
- MASVS-PRIVACY: datos mínimos, aviso de privacidad (HU-47), eliminación de cuenta (HU-46), la IA solo a petición (RNF-06).
- Firebase (HU-31): política en la skill `critic-guardrails` (archivos ignorados, regenerados en CI desde secretos).
- Checks del agente `security-reviewer`: `.claude/agents/security-reviewer.md`.

## 7. Testing

- Unit (config, repositorios con `FakeHttpAdapter`, providers con `ProviderContainer.test`) + widget tests por estado de cada pantalla.
- `test/integration/` (02-10): flujos de cada grupo de pantallas con los proveedores reales contra musubi-api en Development (`LiveSession`, `liveUser()`, cuentas reales con el código del log). Se saltan sin `MUSUBI_API_URL`; los corre `scripts/run_integration_tests.ps1` y el job `integration`. Guía: `test/integration/README.md`.
- `test/security/`: configuración de Android y seguridad de la sesión; los flujos de seguridad contra la API están en `test/integration/security_flow_test.dart`.
- `integration_test/` (02-10): la suite en un teléfono físico (`app_test.dart` + `flows/`, `DeviceApp`), con las pantallas reales contra musubi-api por `adb reverse`; la corre `scripts/run_device_tests.ps1`. Los mismos flujos corren en la VM en `test/integration/device_flows_test.dart` (CI), así un cambio de pantalla que la rompa falla en el PR.
- Matriz completa: skill `testing-strategy`.

## 8. Observabilidad

> Pendiente (`02-01`): Firebase Crashlytics y registro de errores sin PII. La observabilidad del servicio (logs, alarmas y dashboard de CloudWatch) está en `musubi-api`.

## 9. Publicación

- Google Play en **prueba cerrada** desde el 09-Nov-2026. La versión vigente está en `docs/versionado.md` (hoy `0.11.0+13`); la ficha y "Seguridad de los datos", en `docs/play/README.md`.
- El workflow `release-play` (manual) hace esto:
  1. valida que la versión no exista;
  2. corre las pruebas;
  3. compila y firma el AAB con la llave de subida (secreto de GitHub, se borra al terminar);
  4. lo sube a la pista elegida;
  5. etiqueta `app-vX.Y.Z+N`.
- En local, la firma lee `android/key.properties` (ignorado).
- Los lotes juntan varias HU antes de publicar.
- Pendiente: la versión `1.0.0` en producción antes de la evaluación del 02-Dic-2026.

## 10. Reglas basadas en lecciones aprendidas

La fuente canónica es `specs/phase-00-constitution/00-04-lessons-learned/spec.md` (10 heredadas + 9 propias).

## 11. Sub-agentes (híbrido agentes → skills)

- `slice-scaffolder`: Fase A del lado front de una HU (modelo → repositorio/fake → estado → pantalla → pruebas).
- `security-reviewer`: gate pre-push contra OWASP MASVS; **solo lectura forzada** (`disallowedTools` + hook `readonly-git-guard.ps1`).
- `traceability-clerk`: spec ↔ código ↔ test ↔ Jira ↔ contraparte; solo lectura forzada.
- Reglas en `.claude/skills/` (9 skills); convención en `.claude/agents/README.md`.
- OpenCode: lee este `AGENTS.md` y las skills de `.claude/skills/`; sus agentes están en `.opencode/agents/` y remiten a `.claude/agents/` (solo lectura por `permission`). Flujo del equipo: `docs/guia-equipo.md`.

---

## Estructura del repo

| Carpeta | Contenido |
|---|---|
| `lib/` | `main.dart`, `app/`, `core/`, `features/` |
| `test/` | Unit + widget (`core/`, `features/`, `helpers/`), `security/` y `integration/` (contra la API, 02-10) |
| `integration_test/` | Suite en un teléfono físico (`app_test.dart`, `flows/`; 02-10) |
| `android/` | Proyecto Android (`com.musubi.app`, targetSdk 36) |
| `config/` | `*.example.json` por ambiente + README |
| `docs/` | `trazabilidad.md` (47 HU), `modulos.md` (14 módulos), `versionado.md`, `maqueta/` (HTML + índice) |
| `specs/` | SDD: plantilla, fases 00 y 01, `mNN-*/HU-NN-*` |
| `scripts/` | `critic-guardrails.ps1`, `check_shared_sections.ps1`, `run_integration_tests.ps1`, `run_device_tests.ps1`, `MusubiLocalApi.ps1` |
| `.claude/` | `agents/` (3), `skills/` (9), `hooks/` |
| `.github/` | CI, Dependabot, plantilla de PR |
| `.semgrep/` | Reglas SAST propias |
