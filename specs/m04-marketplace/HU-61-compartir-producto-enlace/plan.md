# Plan — HU-61 Compartir un producto con un enlace

## Componentes
- UI y detalle: `lib/features/marketplace/presentation/product_screen.dart`.
- Rutas y deep link: `lib/app/router.dart` (`/producto/:id` actual y alias externo `/p/:id`).
- Asociación Android: `android/app/src/main/AndroidManifest.xml` y `android/app/src/main/kotlin/com/musubi/app/MainActivity.kt`.
- Pruebas de widget/ruta/configuración: `test/features/marketplace/product_screen_test.dart`, `test/app/navigation_test.dart`, `test/security/android_config_test.dart`.
- El contrato de detalle se enlaza desde `musubi-api/docs/endpoints.md`; el fallback web y `assetlinks.json` son externos al repo de la app.

## Decisiones
1. Reutilizar `ProductScreen` y el repositorio de catálogo/detalle existente; no crear otro modelo HTTP.
2. Mantener `/producto/:id` para navegación interna y aceptar `/p/:id` como ruta universal de enlaces compartidos.
3. La hoja del sistema puede incluir nombre/precio porque compartir es una acción explícita del usuario. El HTML/OG de la landing no publica esos campos.
4. Preservar el visitante de HU-48. El cliente usa el token cuando hay sesión; el API ya decide campus y visibilidad.
5. Extender el canal nativo Android existente para invocar el share chooser, sin dependencia Flutter adicional. Confirmar el contrato del canal durante implementación con pruebas de plataforma.

## Guardarraíles
- No incluir tokens, correo, identificador de vendedor ni datos personales en URL o texto compartido.
- El id no es autorización; al abrir siempre cargar el detalle desde el API.
- No reportar éxito si la actividad de compartir no se pudo invocar; mostrar el error mediante estado/mensaje de UI conforme al patrón existente.
- El fallback debe ser genérico y no contener contenido del producto. No afirmar que el sitio fue verificado hasta probarlo en el dominio real.
- No modificar el comportamiento de HU-48 ni la salida anónima de la API en esta HU.

## Validación y secuencia
1. Implementar y probar el método de plataforma Android para compartir texto y URL.
2. Agregar acción contextual a `ProductScreen` y cubrir datos/no-disponible.
3. Agregar ruta `/p/:id` y mantener `/producto/:id`; probar navegación y sesión.
4. Agregar filtro Android App Links `https`, host y prefijo `/p/`; extender prueba de configuración.
5. Coordinar con el dueño de landing el fallback genérico, `assetlinks.json` y pruebas de HTML/OG.
6. Ejecutar format, analyze, tests, APK debug y critic con el SDK Dart requerido por `pubspec.yaml`.
7. Cerrar trazabilidad y Memoria con resultados reales; no marcar evidencia de la landing si solo se probó localmente.
