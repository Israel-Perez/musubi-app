# plan.md — HU-06 Publicar un producto (app)

1. **Componentes:**
   - `features/listings` (dominio, datos y pantallas);
   - `HttpCatalogRepository`;
   - la capa "Publicar" en el marco de pestañas;
   - rutas e íconos.
2. **Decisiones:**
   - **Subir cada foto al agregarla:** al tocar "Publicar producto" casi todo ya subió, y una foto que falla se reintenta sin perder lo escrito.
   - **"Publicar" es una capa dentro del marco, no una hoja modal:** en la maqueta la barra sigue encima y su botón cambia a "Cerrar"; una hoja modal la taparía.
   - **El borrador vive en un provider de la app:** "Atrás" y "Guardar" no pierden nada. Se reinicia al empezar, salvo que se haya guardado.
   - **Las URL de las fotos se arman con `API_BASE_URL`:** el back devuelve rutas `/media/...` y CloudFront sirve la API y las imágenes en el mismo dominio.
   - **`PendingCatalogRepository` se elimina:** la vitrina ya lee la API, y sin red Inicio muestra `Inicio-error` por el `ApiFailure` del repositorio HTTP.
3. **Excepción al stack (00-01), aprobada por el usuario el 27-Oct-2026:**

   | Paquete | Versión | Licencia | Mantenimiento | Seguridad | Alternativa descartada | Plan de remoción |
   |---|---|---|---|---|---|---|
   | `image_picker` | 1.2.4 (06-Oct-2026) | BSD-3 | Editor verificado `flutter.dev`; 160/160 puntos en pub.dev | Sin permisos nuevos en el manifiesto (`android_config_test` igual): usa la cámara del sistema y el selector de fotos de Android | Canal propio a Kotlin (`FileProvider` y resultados de actividad): más código que mantener | Reemplazar `ImagePickerPhotoPicker` (una clase) |

4. **Guardarraíles:**
   - `PhotoPicker` está detrás de una interfaz con un fake en las pruebas;
   - los errores de la cámara se traducen a `PhotoPickFailure` con su aviso;
   - las pruebas corren con la fuente Ahem: los textos largos son `Flexible`.
5. **Validación:** pruebas de widget y de repositorio, capturas lado a lado con la maqueta y prueba en el teléfono.
6. **Secuencia:** datos → borrador → pantallas → capa "Publicar" y rutas → Inicio real → pruebas → capturas → documentación.
