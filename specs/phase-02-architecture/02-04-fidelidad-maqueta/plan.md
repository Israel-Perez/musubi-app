# plan.md — 02-04 Fidelidad con la maqueta

1. **Componentes:**
   - tokens y tipografía;
   - íconos;
   - piezas de `lib/core/widgets/`;
   - pantallas de cuenta, Inicio, Perfil y Ajustes;
   - vitrina de muestra;
   - herramienta de capturas.
2. **Decisiones:**
   - **Se mide, no se estima.** La maqueta se captura con Edge sin ventana y la app con `tool/screenshots_test.dart`, las dos a 390×844 @3x, y se comparan lado a lado. Una diferencia se corrige con el número del CSS, no a ojo.
   - **Los íconos se pintan desde el SVG de la maqueta** (Lucide) con un lector de rutas propio. Un paquete de íconos o de SVG está fuera del stack (00-01) y no garantiza el mismo trazo.
   - **Cada texto fija su altura de línea y su espaciado de letras.** El tema de Material agrega 0.25 de espaciado y una altura propia: los textos quedaban 3.6 % más anchos.
   - **Se copian los redondeos de Chrome, no solo el CSS:**
     - Flutter redondea cada línea a un entero y Chrome a 3x redondea por separado el ascenso y el descenso. `CssLineBox` da a cada texto `normal` el alto de Chrome; sin eso, `Registro` se desfasaba 1.7 pt hacia abajo.
     - El punteado sigue el algoritmo de Chromium (`SelectBestDashGap`).
   - **Sin onda al tocar:** la maqueta cambia el fondo (`.pr`/`.ps`/`.pc`) o encoge el contenido (`.press`). `Pressable` lo reproduce y sostiene el estado 120 ms para que se vea.
   - **Botones siempre habilitados**, como en la maqueta: al tocar, explican qué falta en lugar de quedarse grises sin decir por qué.
   - **El perfil viaja con la sesión:** el saludo "Hola, Ana" no necesita otra llamada a la API. Una sesión vieja, sin perfil, saluda "Hola".
   - **La vitrina de muestra solo existe en dev** (`DEMO_CATALOG`). Así el equipo revisa el diseño en un celular sin que un APK de producción muestre datos inventados.
3. **Guardarraíles:**
   - las animaciones respetan "reducir animaciones" y nunca quedan corriendo sin fin en las pruebas;
   - las pruebas corren con letra al 130 %;
   - sin `http://` en `lib/` y sin `TODO`.
4. **Validación:**
   - pruebas de widget y de flujo;
   - capturas comparadas con la maqueta en claro y oscuro;
   - APK de debug.
5. **Secuencia:** tokens → íconos → componentes → pantallas de cuenta → Inicio y hoja "Crea tu cuenta" → Perfil y Ajustes → modo oscuro → pruebas → capturas → documentación.
