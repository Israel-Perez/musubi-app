# plan.md — HU-42 Consultar indicadores de uso (app)

## 1. Componentes
`lib/features/admin/`: modelos, `HttpAdminRepository.indicators`, `adminIndicatorsProvider`, `AdminIndicatorsScreen`; la ruta en `router.dart` y la fila en `settings_screen.dart`.

## 2. Decisiones (con su porqué)
- **La API manda números y la unidad; la app decide el formato:** el mismo indicador se puede mostrar distinto sin cambiar el contrato, y el texto en español queda en la app.
- **Tarjetas y no gráficas:** sin un paquete de gráficas (00-01), y con 15 números cada tarjeta se lee de un vistazo.
- **Un provider por periodo:** cambiar entre semana y mes no vuelve a pedir lo que ya se cargó mientras la pantalla siga abierta.

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
Solo con `isAdminProvider` se muestra la entrada; la API revisa el rol en la base (RNF-03).

## 5. Validación
`flutter analyze`, `flutter test`, `run_integration_tests.ps1` y critic; prueba en el celular (T4).

## 6. Secuencia
T1 → T2 → T3 → T4.
