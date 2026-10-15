# Specs de musubi-app — roadmap SDD

Cada cambio nace de una spec que sigue [`_template.md`](_template.md) (gobernanza en `00-02`). Una spec es una carpeta con `spec.md`, `plan.md` y `task.md`.

<!-- Sección compartida con musubi-app/musubi-api: si cambia, cámbiala en ambos repos y regístralo en las dos Memoria.md -->
## Convención de IDs y carpetas

- **Specs técnicas:** `NN-NN` en `specs/phase-NN-<nombre>/NN-NN-<slug>/`.
- **Specs funcionales:** `HU-NN` en `specs/mNN-<modulo>/HU-NN-<slug>/`, con **el mismo ID y la misma carpeta en los dos repos**. Cada una describe su lado y declara su `**Contraparte:**`.
- Las specs de cada HU se crean **al iniciar el sprint** de esa HU (calendario en la constitución §1 y en `docs/trazabilidad.md`).
- Para citar una spec del otro repo se antepone el repo: `musubi-api:02-01`, `musubi-app:HU-01`. Los `NOTE (…)` usan los mismos IDs.
- Módulos y carpetas: [`docs/modulos.md`](../docs/modulos.md).
<!-- Fin de sección compartida -->

## Roadmap

| Fase | Specs | Estado |
|---|---|---|
| 00 — Constitución | 00-01 Principios y stack · 00-02 Gobernanza SDD y DoD · 00-03 NFR · 00-04 Lecciones aprendidas | 🚧 Borrador con evidencia |
| 01 — Fundación | 01-01 Setup y toolchain · 01-02 Estructura de la app (shell) · 01-03 Cliente de API y ping · 01-04 Configuración por ambiente · 01-05 Estructura, calidad y CI | 🚧 Borrador con evidencia |
| 02 — Arquitectura de la app | 02-01 Navegación por módulos, estado, cliente de API (interceptores, sesión), tema y componentes base, Crashlytics · 02-02 Publicación en Google Play (firma de subida, prueba cerrada desde el 09-Nov-2026) | Pendiente (se redacta antes de HU-01) |
| Módulos | `m01-auth/` … `m14-admin/` — una carpeta por módulo, una spec por HU (contraparte en `musubi-api`) | Por sprint |

Los IDs de la fase 02 son **tentativos**: son los dueños de los `NOTE (02-0N)` que ya existen en el código. Si cambian, se actualizan los NOTE con `grep "NOTE (02-"`.

## Estado de las specs

La matriz viva está en [`docs/trazabilidad.md`](../docs/trazabilidad.md).
