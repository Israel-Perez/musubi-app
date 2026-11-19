# HU-61 — Compartir un producto con un enlace

**HU / Jira / Sprint / Módulo / Contraparte:** HU-61 / [SCRUM-101](https://uttt-startup-musubi.atlassian.net/browse/SCRUM-101) / Por asignar (posterior al MVP) / M-04 / [musubi-api:HU-61](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-61-compartir-producto-enlace)

## Contexto
Como usuario, quiero compartir un producto por WhatsApp u otra aplicación mediante un enlace, para que otras personas puedan abrirlo en Musubi. La spec de API reutiliza el detalle existente y descarta metadatos públicos del producto en la landing. La app debe conservar el flujo visitante ya existente de HU-48: la decisión de preview privado no cambia quién puede explorar la vitrina o abrir un producto público. **Depende de**: `02-01`, `02-03`, `HU-11`, `HU-48` y `musubi-api:HU-61`.

## Requisitos
1. Compartir desde `Producto` el nombre y precio actuales junto con el enlace canónico `https://musubiapp.com.mx/p/{id}` usando la hoja del sistema.
2. Abrir los enlaces `/p/{id}` recibidos con Musubi instalada y navegar al detalle de ese producto, sin crear una pantalla duplicada.
3. Usar el detalle actual de producto: con sesión, el back aplica campus y visibilidad; como visitante, conservar el acceso público previsto por HU-48.
4. Mostrar el estado no disponible si el producto dejó de ser visible; no inferir el motivo a partir del id o del enlace.
5. No insertar metadatos del producto en la URL ni en el contenido web de fallback. La hoja de compartir contiene nombre/precio porque el usuario inicia explícitamente el envío.
6. Mantener accesible el flujo existente de compartir/enlaces en Android; no almacenar destinatarios ni historial de compartidos.

Aplican RNF-03 (sesión y autorización), RNF-05/RNF-07 (privacidad), RNF-21 (campus) y RNF-25 (pruebas automatizadas), además de MASVS-NETWORK.

## Diseño
- M-04 reutiliza `lib/features/marketplace/`; el detalle existente vive en `ProductScreen` (`lib/features/marketplace/presentation/product_screen.dart`).
- Agregar una ruta externa `/p/:id` que renderice el mismo detalle, conservando la ruta interna `/producto/:id` para no romper navegación existente.
- Declarar Android App Links verificados para `https://musubiapp.com.mx/p/*` en `android/app/src/main/AndroidManifest.xml`; `assetlinks.json` debe publicarse en el dominio por quien administra la landing.
- La hoja nativa de compartir invoca un método de plataforma en `android/app/src/main/kotlin/com/musubi/app/MainActivity.kt`, reutilizando el puente nativo existente; no añadir paquete Flutter sin evaluar y justificar la excepción al stack en `00-01`.
- El fallback web y sus metadatos son propiedad del sitio/landing fuera de este repositorio. La contraparte de app exige que el fallback sea genérico y no exponga contenido del producto.

## Contratos
- Reutilizar la fila [`GET /api/v1/products/{id}`](../../../docs/endpoints.md) de `musubi-api`; con sesión, el contrato filtra por campus y visibilidad. Sin sesión se conserva el detalle público de HU-48.
- Contrato externo del enlace: `https://musubiapp.com.mx/p/{id}` (sin tokens ni información privada en query parameters).
- No se agrega DTO ni ruta HTTP.

## Tests
- `test/features/marketplace/product_screen_test.dart`: acción compartir, datos de texto enviados y publicación no disponible.
- `test/app/navigation_test.dart`: navegación desde el URI `/p/{id}` al mismo `ProductScreen`.
- `test/security/android_config_test.dart`: intent filter verificado HTTPS, host y prefijo de ruta de App Links.
- Nueva prueba unitaria del adaptador de compartir nativo usando `TestDefaultBinaryMessengerBinding` o un método inyectable, según el patrón que se elija al implementar.
- El sitio de landing requiere pruebas propias de HTML/OG; no existe en este repositorio.

## Criterios
- [x] La hoja del sistema recibe nombre, precio y exactamente `https://musubiapp.com.mx/p/{id}` → `test/core/platform/product_share_test.dart` y `product_screen_test.dart`.
- [x] El enlace `/p/{id}` navega al detalle sin duplicar pantalla; `/producto/:id` sigue funcionando → `product_screen_test.dart` y `test/app/navigation_test.dart`.
- [ ] Android declara `autoVerify` para HTTPS, host `musubiapp.com.mx` y ruta `/p/` → `test/security/android_config_test.dart`; el dominio publica un `assetlinks.json` válido.
- [x] Con cuenta del mismo campus se muestra el detalle permitido; con sesión de otro campus o producto no visible, se aplica la respuesta existente del API → `musubi-api` `IntegrationTest/Listings/ListingFlowTests.cs` y `SecurityTest/Auth/ListingsAuthTests.cs`; la ruta externa reutiliza `ProductScreen` (prueba widget HU-61).
- [ ] Sin app instalada, la landing no expone nombre, precio, foto ni datos de vendedor en HTML/OG → evidencia de prueba del repo de landing antes de cerrar la HU.
- [ ] `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos --fatal-warnings`, `flutter test`, build APK debug y critic PASS.

## Límites
- No cambia el acceso de visitantes permitido por HU-48. Si el criterio de Jira exige que el producto solo se vea con sesión del mismo campus, hay que revisar primero HU-48 y el contrato anónimo de `musubi-api:HU-11`; no se puede imponer solo en la navegación del enlace.
- La publicación y despliegue de la landing, el archivo `assetlinks.json` y los metadatos genéricos dependen del dueño del sitio; no están en este repo.
- No se guardan destinatarios ni historial de compartidos y no se incorpora analítica.
- Jira marca la HU como posterior al MVP, sin sprint asignado; el trabajo no debe entrar a publicación hasta que el equipo la priorice.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 revisor distinto del autor)
- **Fecha:** 19-Nov-2026
- **Detalle:** Implementados el chooser nativo, la ruta `/p/:id` y el intent filter; tests Flutter completos en verde y APK debug compilado. La compilación normal requiere AGP 9.1.1, pero el repo fija 9.1.0; se compiló con el bypass oficial de Flutter. Falta validar App Links en dispositivo y verificar la landing/`assetlinks.json` con el dueño del dominio (el URL publicado actualmente da 404). El análisis global con Flutter 3.50 reporta diagnósticos `info` preexistentes de deprecación de Material, incompatibles con `--fatal-infos`.
