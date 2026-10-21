# Maqueta de MUSUBI

`musubi-prototipo.html` es el prototipo navegable de la app: 60 pantallas en 10 secciones, más la guía de estilo v1.0 de septiembre de 2026. Se versionó el 20-Oct-2026 (SCRUM-66; SHA-256 `c0910250911069163259beb2d44f5686a2bc05c1f619bab7af3f38387a6dfba0`).

- **Lineamiento 4:** la app se construye a la imagen de esta maqueta. Se pueden agregar funciones, pero **nunca quitar** las que aparecen aquí.
- **Cómo abrirla:** abre el archivo en el navegador. No hace llamadas externas: las fuentes y las imágenes vienen incrustadas.
- **Datos:** las personas, correos y productos son ficticios. La contraseña de demostración del prototipo no es una credencial real.
- **Cambios:** una versión nueva de la maqueta reemplaza el archivo en un PR propio, actualiza este índice y el SHA-256, y se registra en `Memoria.md`.
- **Uso en las specs:** cada spec de HU del front cita sus pantallas por ID, por ejemplo `Maqueta: Registro, Registro-error`, y su widget/golden test reproduce los estados de esas pantallas.

## 1. Sistema visual (guía de estilo)

Fuente de los tokens implementados en `lib/core/theme/musubi_tokens.dart` (spec `02-01`, 21-Oct-2026). Si este resumen y la guía de estilo difieren, manda la guía.

| Token | Valor |
|---|---|
| Tipografía | Plus Jakarta Sans 400–800 (OFL); respaldo: fuente del sistema. Display 28/34·800 · Título 1 26/32·800 · Título 2 19/24·800 · Título 3 16/21·800. Mínimo 12 px; 16 px dentro de los campos |
| Rojo Musubi (acción principal, pestaña activa, "Se busca") | `#D7191F` (blanco encima 5.2:1) |
| Rojo presionado / texto sobre rojo claro | `#A50F15` |
| Rojo claro (resaltado, chips, tarjeta de solicitud) | `#FDECEC` |
| Neutros | Fondo `#FFFFFF` · Superficie `#F6F6F7` · Texto `#1C1C1E` · Texto secundario `#6B6B70` · Borde `#E4E4E7` |
| Éxito | `#1E9E5A` íconos · `#167C47` texto · `#E8F6EE` fondo |
| Advertencia ("No identificado" de la IA) | `#E8A317` íconos · `#8F5B00` texto · `#FDF4E1` fondo |
| Error (rojo óxido, distinto de la marca) | `#C4320A` ícono y texto · `#FDEEE8` fondo |
| Modo oscuro | Mapa completo en el prototipo (`dc-meta.dark`), p. ej. `#FFFFFF → #17171A`, `#1C1C1E → #F2F2F4` |
| Proporción por pantalla | Blanco 44 % · Superficie 26 % · Texto e íconos 20 % · Rojo 10 % |
| Interacción | Área táctil ≥ 44 px · espaciado en múltiplos de 4 · margen lateral 20 px |
| Navegación inferior | Inicio · Se busca · Publicar (botón central) · Mensajes · Perfil |

Principios de la guía:

1. El rojo se usa con intención y nunca pinta una pantalla completa.
2. Productos y solicitudes tienen lenguajes distintos: un producto se muestra con foto grande y una solicitud como un boleto "Se busca" (RNF-19).
3. La IA propone y la persona decide: el resultado es editable, lleva su etiqueta y lo que falta aparece como "No identificado".

Los estados nunca se comunican solo con color.

## 2. Pantallas ↔ HU (propuesta, a validar con el equipo)

| # | Sección | Pantallas (ID) | HU |
|---|---|---|---|
| 1 | Modo visitante | `Inicio-visitante`, `Se-busca-visitante`, `Producto-visitante`, `Visitante-modal` | HU-48, HU-09, HU-11, HU-15 |
| 2 | Cuenta con correo institucional | `Registro`, `Registro-error`, `Verificacion`, `Verificacion-lista` | HU-01, HU-03 |
| 2 | Sesión | `Iniciar-sesion`, `Iniciar-sesion-error` | HU-02 |
| 3 | Descubrir | `Inicio`, `Recien-publicados`, `Recien-publicados-antiguas` | HU-49, HU-35 |
| 3 | Buscar | `Busqueda`, `Busqueda-filtros`, `Busqueda-vacia` | HU-09, HU-10, HU-12 |
| 3 | Producto y vendedor | `Producto`, `Perfil-vendedor`, `Chat-Valeria` | HU-11, HU-50, HU-51, HU-05, HU-20 |
| 4 | Apartados con QR o código | `Apartar`, `Apartado-listo`, `Mis-apartados`, `Verificar-comprador`, `Apartado-verificado` | HU-52, HU-44 |
| 5 | Vender | `Publicar`, `Vender-1`…`Vender-4`, `Vender-listo` | HU-06 (RNF-17), HU-50 |
| 6 | Publicar una necesidad | `Necesidad-1`…`Necesidad-3`, `Necesidad-publicada`, `Mis-solicitudes` | HU-13, HU-18, HU-14, HU-17 |
| 7 | "Yo tengo este producto" | `Se-busca`, `Yo-tengo-vincular`, `Yo-tengo-oferta`, `Yo-tengo-enviada` | HU-15, HU-16 |
| 8 | Chat y acuerdo con IA | `Mensajes`, `Chat`, `Acuerdo-esperando`, `Acuerdo-confirmado` | HU-22, HU-20, HU-21, HU-32, HU-33, HU-34 |
| 9 | Pago y entrega | `Pedido-pago`, `Pago-transferencia`, `Pago-validando`, `Pago-vendedor`, `Pedido-entrega`, `Pedido-efectivo` | HU-55, HU-23, HU-24, HU-44 |
| 9 | Calificar | `Calificar` | HU-27, HU-45 |
| 10 | Avisos | `Notificaciones` | HU-29, HU-30, HU-31 |
| 10 | Perfil y vendedor | `Perfil`, `Mis-productos` | HU-04, HU-08, HU-07 |
| 10 | Favoritos | `Favoritos` | HU-53 |
| 10 | Ajustes | `Ajustes`, `Cuenta-pagos` | HU-54, HU-55 |
| 10 | Privacidad | `Privacidad`, `Aviso-privacidad` | HU-47, HU-46 (RNF-05, RNF-07) |
| 10 | Estados base | `Inicio-cargando`, `Inicio-error` | `02-01` (RNF-18) |

Tienen HU pero no tienen pantalla en la maqueta: HU-19, HU-25, HU-26, HU-28 y HU-36…HU-42 (HU-43 quedó fuera de alcance, D-01). Agregarlas está permitido por el lineamiento 4, siempre con la guía de estilo.

## 3. Funciones de la maqueta que no estaban en el backlog

Se convirtieron en historias el 21-Oct-2026 (SCRUM-75), porque el lineamiento 4 impide quitarlas.

| ID | Función | Pantallas | HU (Jira) |
|---|---|---|---|
| G-01 | Explorar como visitante; al comprar, apartar o guardar se pide crear cuenta | Sección 1 | HU-48 (SCRUM-73) |
| G-02 | Populares de hoy y de la semana, y recién publicados (con "Más antiguas") | `Inicio`, `Recien-publicados*` | HU-49 (SCRUM-69) |
| G-03 | Inventario por publicación ("Quedan 2", "Último", "Agotado") y cantidad al vender | `Producto`, `Vender-4`, `Mis-productos` | HU-50 (SCRUM-67) |
| G-04 | Comparar con publicaciones similares (reputación, ventas, precio) y "Avísame" | `Producto` | HU-51 (SCRUM-70) |
| G-05 | Apartar 24 h con QR o código de 6 dígitos que el vendedor verifica | Sección 4 | HU-52 (SCRUM-74) |
| G-06 | Favoritos | `Favoritos` | HU-53 (SCRUM-68) |
| G-07 | Modo noche y preferencias | `Ajustes` | HU-54 (SCRUM-71) |

## 4. Decisiones

**D-01 · Modelo de pago (decidido el 21-Oct-2026).** Se implementa **solo el modelo de la maqueta**:

- **Transferencia** a la cuenta (CLABE) verificada del vendedor; el vendedor valida el pago.
- **Efectivo**, con un código de entrega de 4 dígitos.
- Musubi no cobra comisión ni procesa el dinero.

Lo cubre **HU-55** (SCRUM-72). HU-43, "Pagar un pedido con Mercado Pago" (SCRUM-55), queda **fuera de alcance**.
