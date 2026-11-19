# Pruebas de integración contra musubi-api (02-10)

Prueban los flujos de las pantallas con los proveedores reales de la app (repositorios HTTP, Dio, `AuthInterceptor` y sesión) contra una musubi-api de verdad, en Development y en memoria.

## Cómo correrlas

Con `musubi-api` clonado junto a este repo (`../musubi-api`):

```powershell
pwsh scripts/run_integration_tests.ps1
```

El script hace esto:

1. Compila y levanta la API en `http://localhost:5080`.
2. Corre `test/integration` y luego el guard `tool/check_integration_coverage.dart`.
3. Detiene la API.

Si algo falla, el log de la API queda en `build/integration/api.log`.

Opciones:
- `-ApiPath <ruta>`: otra copia de la API.
- `-Port <n>`: otro puerto.
- `-Tests <archivo>`: un solo flujo.
- `-NoBuild`: no compila la API.
- `-SkipCoverage`: no corre el guard.

Sin `MUSUBI_API_URL`, `flutter test` las salta, así que la suite normal no depende de la API.

## Flujos del teléfono en la VM

`device_flows_test.dart` corre los flujos de pantallas de `integration_test/flows/` en la VM, con frames y tiempo reales, contra la API. Es la misma suite que se corre en un teléfono con `scripts/run_device_tests.ps1` (ver `integration_test/README.md`).

## Reglas para una HU nueva

- Si la HU agrega una llamada a la API, agrega su flujo aquí con `liveUser()` y los proveedores reales. Si no, el guard falla en el CI.
- Cada prueba crea sus propias cuentas (`liveUser()`), porque las pruebas corren en paralelo. Usa nombres de producto únicos si buscas por texto.
- Solo `admin_flow_test.dart` usa `liveAdmin()`: la cuenta `admin` es una sola.
- Si una fila de verdad no se puede llamar desde aquí, la excepción va en `waivers` de `tool/check_integration_coverage.dart`, con su motivo.
