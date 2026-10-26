# plan.md — 02-03 Marca y arranque

1. **Componentes:** el pintor del logotipo, `BrandSplash`, los recursos de Android y `tool/launcher_icons_test.dart`.
2. **Decisiones:**
   - **Un solo pintor** para la app, el splash y los PNG del ícono: el logotipo no se puede desalinear entre lugares.
   - **El splash animado va sobre la app ya construida:** no agrega tiempo de carga, solo los ~1.5 s visibles.
   - **El splash nativo y el de Flutter comparten fondo y posición:** la transición se ve continua.
   - **Sin paquetes nuevos** (por ejemplo `flutter_native_splash`): recursos de Android escritos a mano.
3. **Guardarraíles:** respeta "reducir animaciones"; apagado en las pruebas para no esperar.
4. **Validación:** pruebas de widget y captura en el dispositivo.
5. **Secuencia:** pintor → recursos de Android → splash animado → pruebas → dispositivo.
