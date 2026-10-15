---
name: empirical-verification
description: Medir antes de fijar versiones, umbrales, timeouts, nombres y formatos en MUSUBI; nunca inventarlos. Úsala al elegir una versión de paquete o imagen, al definir un umbral de CI o NFR, o al documentar un número.
---

## Propósito
Que cada número o nombre de los docs y la configuración tenga una fuente medida y fechada.

## Cuándo usarla
Al agregar un paquete o una imagen, al fijar un timeout o un umbral, al escribir un contrato JSON o al afirmar que "funciona".

## Precondiciones
Acceso a la herramienta real (CLI, registro de paquetes, ejecución de pruebas).

## Pasos
1. **Ejecutar y capturar:** `flutter --version`, `dart pub outdated`, `flutter doctor -v`, `git ls-remote` para los SHAs de las actions; leer los valores reales (p. ej. `targetSdkVersion` en `FlutterExtension.kt` y en el APK con `aapt2 dump badging`).
2. **Inspeccionar el formato real** (JSON del wire, salida del comando) antes de escribir la prueba o el parser.
3. **Fijar el valor** con margen y citar la fuente y la fecha en la spec o en `Memoria.md`.
4. **Confirmar el exit code real** antes de leer los resultados: `flutter build … | tail` devuelve el código de `tail` (00-04 #15).
5. **Self-test** de los guardarraíles: romper a propósito y ver que fallen (00-04 #18).

## Checklist
Versiones verificadas en su registro · umbrales con su medición · nombres reales · self-test hecho.

## Criterios de done
Cada número de los docs cita su fuente y su fecha (p. ej. "`targetSdkVersion:'36'` en el APK, 15-Oct-2026").

## Límites/trampas
- No asumir la última versión "de memoria": consultar el registro.
- No asumir que `sdkmanager` funciona en Windows: usar `android sdk install` (00-04 #14).
- No asumir la sintaxis de Dart de los tutoriales: very_good_analysis 11 exige `const new(...)` (00-04 #13).
- `status 0` no implica OK: comparar con un grupo de control.

## Referencias
`specs/phase-00-constitution/00-04-lessons-learned/spec.md`, `Memoria.md`.
