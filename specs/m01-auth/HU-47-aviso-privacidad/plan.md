# plan.md — HU-47 Aviso de privacidad (app)

1. **Componentes:** `assets/legal/*.md`, `legal_screens.dart`, las rutas legales y el registro de los assets en `pubspec.yaml`.
2. **Decisiones:**
   - **Markdown en assets** en lugar de textos en Dart: un solo archivo para la app y la landing, con versión en Git.
   - **Intérprete mínimo propio:** cuatro formas de línea bastan; no se justifica un paquete nuevo (regla de excepción de 00-01).
3. **Guardarraíles:** una prueba de contenido protege las secciones obligatorias y que no aparezcan nombres de personas.
4. **Validación:** pruebas de contenido y de widget.
5. **Secuencia:** documentos → pantallas → rutas → pruebas.
