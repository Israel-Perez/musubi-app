# plan.md — 02-02 Publicación en Google Play (borrador)

1. **Llave de subida:**
   - `keytool -genkeypair -v -keystore musubi-upload.jks -keyalg RSA -keysize 4096 -validity 10000 -alias upload`, fuera del repo;
   - crear `android/key.properties`;
   - respaldo cifrado en el Drive del titular más un gestor de contraseñas.
2. **Build:**
   - `flutter build appbundle --release --dart-define-from-file=config/prod.json`;
   - revisar el AAB con `aapt2`/`bundletool`.
3. **Play Console:**
   - crear la app "Musubi" (gratis, sin anuncios);
   - activar Play App Signing;
   - subir a la prueba interna.
4. **Ficha y formularios:** textos y gráficos en `docs/play/`, y las respuestas de Seguridad de los datos y de IARC.
5. **Prueba cerrada:** lista de testers (correos de Gmail), enlace de inscripción y una guía corta para los testers.
6. **`release-play.yml`:** la cuenta de servicio de Google Cloud con acceso a la app y los secretos en GitHub.
7. **Producción:** cuestionario de acceso al cumplir los 14 días y publicación.

**Decisiones a cerrar al iniciar:**
- cuenta de revisores;
- público objetivo;
- acción de GitHub para subir a Play (versión fijada por SHA y licencia revisada, regla de 00-01).
