# plan.md — HU-01 Crear cuenta (app)

1. **Componentes:** `lib/features/auth/{domain,data,presentation}`, `ApiPaths` (4 rutas), `router.dart` (rutas de registro) y `test/helpers/fake_auth_repository.dart`.
2. **Decisiones:**
   - **El repositorio lanza `ApiFailure` tipado** en lugar de devolver un estado sellado como `status`: el flujo tiene muchos códigos de negocio y la pantalla decide por `code`.
   - **La detección del campus no bloquea si falla la red:** solo `auth.email_not_institutional` marca el error.
   - **Consentimiento con una sola casilla para los dos documentos**, como en la maqueta: se envía `acceptTerms` y `acceptPrivacy` en `true`.
3. **Guardarraíles:** pruebas con el router real (guardia incluida) y self-test del consentimiento.
4. **Validación:** pruebas del repositorio con `FakeHttpAdapter` y pruebas de widget del flujo con un fake del repositorio y reloj fijo.
5. **Secuencia:** dominio → datos → pantalla → rutas → pruebas.
