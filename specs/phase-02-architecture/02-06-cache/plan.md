# plan.md — 02-06 Caché de la app

## Decisiones
- **Revalidar con `ETag` y no guardar con un tiempo de vida:** la API manda `no-cache`. Así un cambio, por ejemplo una publicación nueva, se ve al instante y la app solo se ahorra el cuerpo de la respuesta.
- **La llave lleva la identidad, no el token:** el token cambia cada 15 minutos y la identidad no; así la copia sigue sirviendo.
- **Sin paquetes nuevos:** un interceptor de Dio de unas 80 líneas basta (regla de `00-01`).
