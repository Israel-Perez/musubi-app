# plan.md — HU-40 Suspender y reactivar cuentas (app)

Se implementa con HU-39, en el mismo feature y PR. Componentes, decisiones, guardarraíles y secuencia: [`../HU-39-moderar-contenido/plan.md`](../HU-39-moderar-contenido/plan.md).

Decisiones propias de HU-40:

- **El motivo es obligatorio en la app y en la API.** Queda en el historial (RNF-04). Sin él, la app no manda la petición.
- **"Reactivar" pide confirmación** y avisa que las publicaciones siguen pausadas, porque la API no las reactiva sola (decisión de `musubi-api:HU-40`).
- **"Suspendidas" es la tercera pestaña de "Administración"** y no una pantalla aparte. Así, la única manera de llegar a una cuenta que ya no tiene reportes abiertos es desde ahí.
