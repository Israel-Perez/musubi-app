# 00-01 — Principios y stack

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) · contraparte conceptual: `musubi-api:00-01`

## Contexto
Primera spec de la constitución de musubi-app: registra los principios no negociables de MUSUBI con su consecuencia práctica en la app, el stack obligatorio y la regla de excepción. **Depende de**: —

## Requisitos
1. Listar los principios con su consecuencia práctica en el front (fuente: constitución §2, sección compartida).
2. Tabla del stack por capa (constitución §6).
3. Definir la regla de excepción para paquetes o servicios fuera del stack.
4. Ser citada desde `AGENTS.md` y `00-02`.

## Diseño

| Principio (constitución §2) | Consecuencia práctica en musubi-app |
|---|---|
| Seguridad primero | Cero secretos en el APK (critic B2 + Semgrep); HTTPS fuera de dev (`AppConfig.parse` + `network_security_config`); `allowBackup=false`; dependencias revisadas. Referencia: OWASP MASVS. |
| Privacidad por diseño | La conversación solo se envía a la IA con una acción explícita del usuario (HU-32); aviso de privacidad antes de crear la cuenta (HU-47); sin PII en logs (`print` prohibido en `lib/`). |
| IA y ML desacoplados | Las pantallas de IA y recomendaciones degradan con un mensaje si fallan; nunca bloquean búsqueda, chat ni pedidos (RNF-15). |
| Multi-comunidad | La universidad y su dominio de correo vienen de la API, no del código (RNF-21). |
| Trabajo pesado en segundo plano | Indicador visible mientras se espera (RNF-12); la UI no se congela (operaciones async y estados de carga en los providers). |
| Empírico antes que teórico | Versiones medidas (Flutter 3.47.7, Dart 3.13.5, targetSdk 36 leído del plugin de Gradle); umbrales sin medir quedan como 🎯 en `00-03`. |
| Documentar límites | `NOTE (ID)` en 4 capas; nunca `TODO` (`todo: error` en el analizador + critic B1 + Semgrep). |

Stack: ver la constitución §6 (tabla canónica; no se duplica aquí).

**Regla de excepción** (paquete o servicio fuera del stack):
1. Proponerlo en el `plan.md` de la spec que lo necesita, con su licencia (`LICENSE` en el pub cache o pub.dev), su mantenimiento (último release, publisher verificado, puntaje en pub.dev) y sus avisos de seguridad.
2. Documentar la alternativa descartada y el plan de remoción.
3. Actualizar la constitución §6, el bloque de aprobación y `Memoria.md`.
4. Ningún paquete que requiera llaves privadas en el cliente: esa integración va en `musubi-api`.

## Contratos
N/A — spec constitucional. Referencia normativa en `AGENTS.md` §1 y en la constitución §6.

## Tests
N/A — verificación estructural y por los guardarraíles que hacen cumplir cada principio.

## Criterios
- Cada principio cita una consecuencia práctica verificable (tabla de Diseño).
- `pubspec.yaml` solo contiene paquetes del stack (`dio`, `flutter_riverpod`, `go_router`, `flutter_localizations`, `flutter_secure_storage`, `image_picker`; dev: `very_good_analysis`, `flutter_test`, `integration_test`).
- `AGENTS.md` y `00-02` citan `00-01` (`grep -n "00-01" AGENTS.md specs/phase-00-constitution/00-02-sdd-governance/spec.md`).

## Límites
No fija versiones exactas (viven en `pubspec.yaml`/`pubspec.lock` y en Memoria.md) ni umbrales (viven en `00-03`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 20-Oct-2026
- **Detalle:** Adaptada de la referencia WebAPIDevSecOpsScallingSDD (00-01) al front Flutter de MUSUBI. Paquetes aprobados por el usuario: Riverpod, go_router, dio y very_good_analysis. 20-Oct-2026 (SCRUM-66): la constitución §1 (compartida) fija la evaluación el 02-Dic-2026 y hace mandar los lineamientos de la materia; §6 agrega el diseño de la maqueta y los datos locales (02-01). 27-Oct-2026 (SCRUM-23): `image_picker` 1.2.4 aprobado por el usuario como excepción (ver el `plan.md` de HU-06).
