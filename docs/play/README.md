# Google Play: ficha y guía de Play Console (02-02)

Todo lo que se escribe o se sube en Play Console para Musubi (`com.musubi.app`). La spec es [`specs/phase-02-architecture/02-02-google-play/`](../../specs/phase-02-architecture/02-02-google-play/spec.md).

## Archivos

| Archivo | Para qué | Requisito de Play |
|---|---|---|
| `icon-512.png` | Ícono de la ficha | 512 × 512, PNG de 32 bits |
| `feature-1024x500.png` | Gráfico de funciones | 1024 × 500, PNG o JPG |
| `capturas/01…06-*.png` | Capturas del teléfono | 1170 × 2340 (2:1 como máximo) |

- Las capturas salen de `flutter test tool/screenshots_test.dart --dart-define=SHOTS=<carpeta> --dart-define=SHOT_HEIGHT=780 --dart-define=ONLY=…`. Usan datos de muestra de la maqueta.
- No hay captura de Inicio con "Populares": la versión actual oculta esa sección hasta HU-11.

## Ficha de la tienda (Español, Latinoamérica)

**Nombre** (≤ 30): `Musubi`

**Descripción corta** (≤ 80):

```text
Compra, vende y pide lo que necesitas entre estudiantes de tu universidad.
```

**Descripción completa** (≤ 4000):

```text
Musubi es el mercado de tu campus: compra y vende libros, calculadoras, laptops, batas y material de laboratorio con otros estudiantes de tu universidad.

Solo para tu comunidad
Te registras con tu correo institucional y confirmas que es tuyo con un código. Así, todas las personas en Musubi son de tu campus.

Vende en minutos
Toma fotos de lo que ya no usas, ponle nombre, precio y categoría, y publícalo. Musubi te muestra en qué rango se venden productos parecidos para que pongas un precio justo.

Sin comisiones
Musubi no cobra comisiones ni procesa pagos: acuerdas directamente con la otra persona y entregan en un lugar público del campus.

Tus datos son tuyos
No vendemos tus datos ni usamos rastreo publicitario. Puedes pedir que borremos tu cuenta cuando quieras.

Musubi es un proyecto estudiantil de la Universidad Tecnológica de Tula-Tepeji (UTTT). Por ahora está disponible para la UTTT; pronto llegarán más universidades y funciones: búsqueda, solicitudes "Se busca", chat, apartados y avisos.

Dudas: contacto@musubiapp.com.mx
```

- **Categoría:** Compras.
- **Etiquetas:** Compras, Mercado.
- **Correo de contacto:** `contacto@musubiapp.com.mx`.
- **Sitio web:** `https://musubiapp.com.mx`.
- **Política de privacidad:** `https://musubiapp.com.mx/privacidad`.

## Contenido de la app (respuestas para la versión 0.3.0)

Revísalas antes de enviar. Deben describir lo que **esta** versión hace, no lo que hará.

| Sección | Respuesta |
|---|---|
| Política de privacidad | `https://musubiapp.com.mx/privacidad` |
| Anuncios | No contiene anuncios |
| Acceso a la app | Algunas funciones requieren iniciar sesión. Se da una cuenta de prueba con usuario y contraseña (pendiente: cuenta de revisión, ver la spec 02-02) |
| Clasificación de contenido (IARC) | Categoría: Compras/mercado. Sin violencia, sexo, lenguaje vulgar, drogas ni apuestas. **Sí**: los usuarios publican contenido que ven otros usuarios. No comparte ubicación. No vende productos digitales |
| Público objetivo | 18 años o más (pendiente de confirmar) |
| App de noticias / gubernamental / salud / préstamos | No |
| Funciones financieras | No (Musubi no procesa pagos) |
| Eliminación de cuenta | `https://musubiapp.com.mx/eliminar-cuenta`. La opción dentro de la app llega con HU-46 |

**Seguridad de los datos:**
- **Cifrado en tránsito:** sí. Todo va por HTTPS a `api.musubiapp.com.mx`.
- **Borrado de datos:** el usuario puede pedirlo, desde la URL de arriba.
- **¿Se comparten datos con terceros?** No. AWS y MongoDB Atlas son proveedores que procesan los datos por cuenta de Musubi, y Google no cuenta eso como compartir.

Qué datos se recopilan:

| Tipo de dato (Play) | ¿Se recopila? | Para qué | ¿Opcional? |
|---|---|---|---|
| Información personal → Nombre | Sí | Funcionalidad de la app, administración de la cuenta | No |
| Información personal → Dirección de correo | Sí | Administración de la cuenta (verificación y recuperación) | No |
| Información personal → IDs de usuario | Sí (ID interno de la cuenta) | Administración de la cuenta | No |
| Fotos y videos → Fotos | Sí (fotos de los productos publicados) | Funcionalidad de la app | Sí (solo quien publica) |
| Actividad en la app → Otro contenido generado por el usuario | Sí (publicaciones: título, descripción, precio) | Funcionalidad de la app | Sí |
| Ubicación, contactos, mensajes, información financiera, salud, archivos, calendario, audio | No | — | — |
| Información y rendimiento de la app (fallos) | No (sin Crashlytics en esta versión) | — | — |

Notas:
- La API guarda el *user agent* de cada sesión para que el usuario la reconozca. No es un identificador del dispositivo.
- **Cuando lleguen** chat (HU-20), avisos push (HU-31), Crashlytics o la foto de perfil (HU-04), **hay que actualizar este formulario** antes de subir esa versión.

## Pasos en Play Console (primera vez)

1. **Crear app:**
   - nombre "Musubi";
   - idioma predeterminado: Español (Latinoamérica);
   - tipo: App;
   - gratuita;
   - aceptar las declaraciones.
2. **Probar y lanzar → Pruebas → Prueba interna → Crear versión:**
   - acepta **Play App Signing** (Google guarda la llave de la app; nosotros solo usamos la llave de subida);
   - sube `app-release.aab`;
   - nombre de la versión: `0.3.0 (3)`;
   - notas: "Primera versión de prueba: registro con correo institucional, publicar productos y vitrina del campus".
3. **Testers de la prueba interna:** crea una lista de correo (Gmail del equipo), guárdala y copia el **enlace de inscripción** para que se unan.
4. **Panel → Configura tu app:** completa la ficha y cada sección de "Contenido de la app" con las respuestas de arriba.
5. **Prueba cerrada** (la que cuenta los 14 días):
   - cuando todo lo anterior esté completo y HU-46 en la app, crea la pista;
   - agrega a los 12 o más testers;
   - envíala a revisión.

## Llave de subida

- **Dónde está:** `C:\Users\adani\.musubi-play\musubi-upload.jks`, alias `upload`, con su contraseña en `contrasena-llave-subida.txt` en la misma carpeta. **Nunca entra al repo.**
- **Uso local:** `android/key.properties` (ignorado por Git) apunta a ella.
- **Respaldo:** la carpeta completa debe copiarse a un lugar seguro (Drive personal y gestor de contraseñas). Si se pierde, Google puede cambiarla, pero el trámite tarda días.
- **Huella SHA-256 del certificado de subida:** `98:BB:B0:9E:CD:93:5E:6E:6A:06:94:40:68:2C:9E:B5:E9:64:7B:7D:42:4A:30:10:92:3B:95:73:CF:CD:61:93`.
