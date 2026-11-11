# Google Play: ficha y guía de Play Console (02-02)

Todo lo que se escribe o se sube en Play Console para Musubi (`com.musubi.app`). La spec es [`specs/phase-02-architecture/02-02-google-play/`](../../specs/phase-02-architecture/02-02-google-play/spec.md).

## Archivos

| Archivo | Para qué | Requisito de Play |
|---|---|---|
| `icon-512.png` | Ícono de la ficha | 512 × 512, PNG de 32 bits |
| `feature-1024x500.png` | Gráfico de funciones | 1024 × 500, PNG o JPG |
| `capturas/01…05-*.png` | Capturas del teléfono | 1080 × 1920 (9:16); 4 o más permiten promocionar la app |

- Las capturas salen de `flutter test tool/screenshots_test.dart --dart-define=SHOTS=<carpeta> --dart-define=SHOT_WIDTH=360 --dart-define=SHOT_HEIGHT=640 --dart-define=ONLY=…`. Usan datos de muestra de la maqueta.
- No hay captura de Inicio con "Populares": la versión actual oculta esa sección hasta HU-11. Tampoco de Perfil, que hoy solo dice "Muy pronto".

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

Encuentra lo que buscas
Busca por palabra y filtra por categoría, precio, estado y orden. Revisa el detalle de cada producto antes de escribirle al vendedor.

¿No lo encuentras? Pídelo en "Se busca"
Publica lo que necesitas con tu presupuesto y para cuándo lo quieres. Quien lo tenga te manda una oferta; tú las comparas por precio y reputación y eliges la que más te convenga.

Platica antes de comprar
Escríbele a la otra persona en el chat, en tiempo real, para acordar el precio y el lugar de entrega. Si alguien te incomoda, puedes reportarlo o bloquearlo.

Del chat al pedido
Cuando se pongan de acuerdo, toca "Resumir acuerdo": la IA propone producto, precio, cantidad, lugar y fecha a partir de la plática, y lo que no encuentre queda marcado para que lo completes. Los dos revisan y confirman el acuerdo, y con un toque se crea el pedido. Eliges el edificio del campus donde se ven y pagas en efectivo al recibir.

Guarda lo que te interesa
Marca con el corazón los productos que te gustan y encuéntralos después en Favoritos.

Sin comisiones
Musubi no cobra comisiones ni procesa pagos: acuerdas directamente con la otra persona y entregan en un lugar público del campus.

Tus datos son tuyos
No vendemos tus datos ni usamos rastreo publicitario. Puedes pedir que borremos tu cuenta cuando quieras.

Musubi es un proyecto estudiantil de la Universidad Tecnológica de Tula-Tepeji (UTTT). Por ahora está disponible para la UTTT; pronto llegarán más universidades y funciones: apartados, calificaciones y avisos.

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
| Acceso a la app | Algunas funciones requieren iniciar sesión. Cuenta de revisión: `revision@musubiapp.com.mx` (dominio del equipo dentro de la UTTT, SCRUM-88). La contraseña vive solo en el gestor del titular. Instrucciones en inglés: ver abajo |
| Clasificación de contenido (IARC) | Categoría: Compras/mercado. Sin violencia, sexo, lenguaje vulgar, drogas ni apuestas. **Sí**: los usuarios publican contenido que ven otros usuarios. No comparte ubicación. No vende productos digitales |
| Público objetivo | 18 años o más (pendiente de confirmar) |
| App de noticias / gubernamental / salud / préstamos | No |
| Funciones financieras | No (Musubi no procesa pagos) |
| Eliminación de cuenta | `https://musubiapp.com.mx/eliminar-cuenta` y, desde `0.3.0+4`, Perfil → Ajustes → Eliminar mi cuenta (HU-46) |

**Seguridad de los datos:**
- **Cifrado en tránsito:** sí. Todo va por HTTPS a `api.musubiapp.com.mx`.
- **Borrado de datos:** el usuario puede pedirlo, desde la URL de arriba.
- **¿Se comparten datos con terceros?** Desde `0.7.0`, **sí**: cuando una persona toca "Resumir acuerdo", los mensajes de texto de esa conversación (sin nombres ni datos de contacto) se envían a Gemini de Google. En la capa gratuita, Google puede usarlos para mejorar sus productos, así que no cuenta como un proveedor que solo procesa por cuenta de Musubi: se declara como compartido. AWS y MongoDB Atlas sí son proveedores que procesan por cuenta de Musubi (no cuentan como compartir).

Qué datos se recopilan:

| Tipo de dato (Play) | ¿Se recopila? | Para qué | ¿Opcional? |
|---|---|---|---|
| Información personal → Nombre | Sí | Funcionalidad de la app, administración de la cuenta | No |
| Información personal → Dirección de correo | Sí | Administración de la cuenta (verificación y recuperación) | No |
| Información personal → IDs de usuario | Sí (ID interno de la cuenta) | Administración de la cuenta | No |
| Fotos y videos → Fotos | Sí (fotos de los productos publicados y foto de perfil, desde `0.4.0`) | Funcionalidad de la app | Sí (solo quien publica o quien sube su foto) |
| Información personal → Otra información | Sí (carrera y cuatrimestre del perfil, desde `0.4.0`) | Funcionalidad de la app | Sí |
| Actividad en la app → Otro contenido generado por el usuario | Sí (publicaciones: título, descripción y precio; desde `0.6.0` también solicitudes "Se busca", ofertas y reportes; desde `0.7.0`, pedidos y acuerdos: cantidad, lugar y fecha de entrega) | Funcionalidad de la app; reportes: seguridad y cumplimiento | Sí |
| Mensajes → Otros mensajes en la app | Sí (chat entre estudiantes, desde `0.5.0`). **Compartido** desde `0.7.0`: con Google (Gemini) solo cuando alguien pide "Resumir acuerdo" | Funcionalidad de la app | Sí (solo quien escribe; la IA solo si alguien la pide) |
| Actividad en la app → Interacciones con la app | Sí (a quién bloqueaste, desde `0.6.0`; favoritos, desde `0.7.0`) | Funcionalidad de la app; seguridad | Sí |
| Ubicación, contactos, correos o SMS, información financiera, salud, archivos, calendario, audio | No | — | — |
| Información y rendimiento de la app (fallos) | No (sin Crashlytics en esta versión) | — | — |

Notas:
- La API guarda el *user agent* de cada sesión para que el usuario la reconozca. No es un identificador del dispositivo.
- **`0.4.0` (HU-04) agrega la foto de perfil y la carrera:** actualiza el formulario en Play Console antes de enviar esa versión.
- **`0.6.0` (lote de HU-09 a HU-17) ya recopila mensajes del chat, solicitudes, ofertas, reportes y bloqueos:** actualiza el formulario en Play Console (filas de arriba) antes de enviar esa versión.
- **`0.7.0` (lote de HU-14, HU-53, HU-23 y HU-32/33/34) comparte mensajes con Google (Gemini) y recopila pedidos, acuerdos y favoritos:** actualiza en Play Console la pregunta "¿Se comparten datos?" y las filas de arriba antes de enviar esa versión.
- **Cuando lleguen** avisos push (HU-31) o Crashlytics, **hay que actualizar este formulario** antes de subir esa versión.

### Acceso a la app: texto para Play (en inglés)

- **Nombre:** `Reviewer account (student)`.
- **Usuario:** `revision@musubiapp.com.mx`.
- **Contraseña:** la del gestor del titular. No se escribe aquí.
- **Otra información:**

```text
Musubi is a marketplace for students of Universidad Tecnologica de Tula-Tepeji. Tap "Iniciar sesion" (Sign in) on the Profile tab and use these credentials. No two-step verification or one-time code is required to sign in: the email of this account is already verified. Without signing in, the app can also be browsed as a visitor.
```

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

## Publicar desde GitHub Actions (`release-play.yml`, L-16a)

**Qué hace:** se lanza a mano y solo desde `main`.
1. Revisa que la etiqueta `app-v<version>` no exista.
2. Corre `flutter analyze` y `flutter test`.
3. Compila el AAB firmado con la llave de subida.
4. Lo sube a la pista elegida con la API de Google Play.
5. Crea la etiqueta.

Las notas de la versión salen de `whatsnew/whatsnew-es-419` (máximo 500 caracteres): cámbialas antes de cada publicación.

### Configuración (una sola vez)

1. **Google Cloud** (con la cuenta del desarrollador: `desarrollomusubi@gmail.com` en Google Cloud y Play Console; `desarrollo@musubiapp.com.mx` es el correo del dominio que llega al mismo buzón del equipo):
   - crea un proyecto (por ejemplo, `musubi-play`);
   - en **APIs y servicios → Biblioteca**, activa **Google Play Android Developer API**;
   - en **IAM → Cuentas de servicio**, crea `github-release` **sin roles**;
   - en **Claves → Agregar clave → JSON**, descarga el archivo. Es un secreto: no lo subas al repo ni lo compartas.
2. **Play Console → Usuarios y permisos → Invitar a usuarios:**
   - escribe el correo de la cuenta de servicio (`github-release@<proyecto>.iam.gserviceaccount.com`);
   - en **Permisos de la app → Musubi**, marca "Lanzar a producción, excluir dispositivos y usar Play App Signing" y "Lanzar versiones en pistas de prueba".
   - El permiso puede tardar unos minutos en aplicarse.
3. **GitHub → musubi-app → Settings → Environments → `google-play`:**
   - rama permitida: `main`;
   - secretos:

     | Secreto | Valor |
     |---|---|
     | `PLAY_UPLOAD_KEYSTORE_B64` | `musubi-upload.jks` en base64 (`[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.musubi-play\musubi-upload.jks"))`) |
     | `PLAY_UPLOAD_KEYSTORE_PASSWORD` | La de `contrasena-llave-subida.txt` |
     | `PLAY_UPLOAD_KEY_ALIAS` | `upload` |
     | `PLAY_UPLOAD_KEY_PASSWORD` | La misma de `contrasena-llave-subida.txt` (PKCS12 usa una sola) |
     | `PLAY_SERVICE_ACCOUNT_JSON` | El contenido completo del JSON de la cuenta de servicio |

**Cuenta de servicio creada:** `github-release@sodium-cat-513606-s7.iam.gserviceaccount.com` (proyecto `sodium-cat-513606-s7`). Su llave JSON solo vive en el secreto `PLAY_SERVICE_ACCOUNT_JSON`. Si una llave se expone (por ejemplo, pegada en un chat), bórrala en Google Cloud → Cuentas de servicio → Claves y crea otra.

### Publicar una versión

1. Sube `version` en `pubspec.yaml`. El `+N` es el versionCode de Play y debe ser mayor que el último subido.
2. Agrega su fila en `docs/versionado.md` y actualiza `whatsnew/whatsnew-es-419`.
3. Fusiona a `main`. Si la versión depende de cambios en la API, **despliega antes la API** (`infra-up` en musubi-api).
4. **Actions → release-play → Run workflow:**
   - pista `alpha` (prueba cerrada), `internal` o `production`;
   - estado `completed`.
5. Google revisa la versión (de minutos a horas) y la publica en esa pista.

**Pistas:** `alpha` es el id de la prueba cerrada predeterminada de Play Console. Si creaste otra con un nombre propio, su id es ese nombre.
