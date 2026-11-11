# HU-54 — Plan de implementación de la app

## Componentes
- `lib/features/profile/domain/`: enum/modelo e interfaz de preferencias.
- `lib/features/profile/data/`: repositorio HTTP y mapeo de fallo a mensaje español.
- `lib/features/profile/presentation/`: provider/notifier y `DarkModeRow` ("Modo noche" en Ajustes · "Preferencias").
- `lib/app/musubi_app.dart`: `themeMode` reactivo con temas claros/oscuros ya existentes.
- `lib/core/network/api_paths.dart`: referencia a la fila HU-54 del catálogo del back.
- Tests unitarios de repositorio/provider y widget/flujo en `test/features/profile/`.

## Decisiones
- API es fuente de verdad de preferencia por cuenta; no agregar almacenamiento local o paquetes fuera del stack aprobado.
- Valor predeterminado `system`; serialización enum en minúsculas compatible con `ThemeMode`.
- Como la maqueta, un interruptor (`MusubiSwitch`) y no un selector: muestra el tema que se ve y guarda `dark` o `light`. Avisa "Modo noche activado" o "desactivado" (1.8 s, como la maqueta).
- Guardado optimista; en error, restaurar el tema anterior, mostrar mensaje y dejar reintentar.
- Visitante conserva `ThemeMode.system`; preferencias de notificación quedan fuera por decisión pendiente de Jira.

## Guardarraíles
- No llamar a Dio desde widgets; todas las llamadas usan `dioProvider` en el repositorio.
- Solo usuario con sesión usa GET/PUT autenticados; no registrar PII ni tokens.
- Contraste AA en modo claro y oscuro; no cambiar colores ni componentes globales no necesarios.

## Validación
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze --fatal-infos --fatal-warnings`
- `flutter test`
- `pwsh scripts/critic-guardrails.ps1`

## Secuencia
1. Modelar y probar el contrato de preferencias contra la API.
2. Agregar provider reactivo para inicio/cambio/rollback.
3. Conectar `MusubiApp` y el interruptor de Ajustes; cubrir sesión/visitante.
4. Cerrar specs, trazabilidad y Memoria; verificar y crear commit aislado SCRUM-71.
