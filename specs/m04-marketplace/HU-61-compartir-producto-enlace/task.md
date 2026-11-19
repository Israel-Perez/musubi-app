# HU-61 — Compartir un producto con un enlace

## T1 — Confirmar contrato y alcance privacidad
- **Qué:** Mantener preview web genérico, compartir intencionalmente nombre/precio, preservar la navegación de HU-48 y enlazar `GET /products/{id}`.
- **Verificación:** Jira SCRUM-101, HU-48 y `musubi-api:HU-61`.
- **Estado:** ✅ Decisión de preview privado registrada; interpretación de acceso visitante pendiente de aprobación del PO si Jira exige exclusividad por campus.

## T2 — Compartir con la hoja del sistema
- **Qué:** Agregar acción en `ProductScreen` y puente nativo para enviar nombre, precio y enlace canónico.
- **Verificación:** `test/features/marketplace/product_screen_test.dart` y prueba del método de plataforma.
- **Estado:** ✅ Implementado y probado (payload del chooser y fallo controlado).

## T3 — Abrir App Links
- **Qué:** Configurar Android App Links verificados y mapear `/p/{id}` a la pantalla existente de detalle.
- **Verificación:** `test/app/navigation_test.dart`, `test/security/android_config_test.dart` y validación en dispositivo con enlace HTTPS real.
- **Estado:** 🟡 Ruta y manifest implementados; pruebas unitarias en verde. Pendiente validar el dominio asociado y abrir desde un dispositivo físico.

## T4 — Landing y cierre
- **Qué:** Coordinar fallback genérico y `assetlinks.json` con el dueño del sitio; actualizar la trazabilidad y conciliar la spec.
- **Verificación:** pruebas de HTML/OG del sitio, format/analyze/test/build/critic de app.
- **Estado:** 🟡 La app implementa la ruta y el manifest; `https://musubiapp.com.mx/.well-known/assetlinks.json` respondió 404. Pendientes publicación del archivo y pruebas del fallback web por el dueño del sitio.

## Pendientes
- Sprint y fecha → Jira SCRUM-101 (por asignar, posterior al MVP).
- Resolver interpretación del criterio "solo mismo campus con sesión" frente a HU-48 → PO/equipo antes de cambiar reglas de acceso.
- Revisor de spec → integrante distinto del autor.
- APK debug → compilado con `--android-skip-build-dependency-validation`; la compilación normal con Flutter 3.50 requiere AGP 9.1.1 mientras el repo fija 9.1.0. Decidir si alinear la versión de Gradle/AGP antes del PR o conservar el toolchain fijado.
- Analizador estricto → `flutter analyze --fatal-infos --fatal-warnings` falla por infos deprecadas de `material.dart` en el repo preexistente al usar Flutter 3.50; resolver con la versión Flutter prescrita o migración coordinada.
