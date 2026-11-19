# Suite automatizada en un teléfono físico (02-10)

Recorre las pantallas reales de la app en el teléfono, con los mismos repositorios HTTP que la versión de Play, contra una musubi-api que corre en la PC.

## Antes de empezar

1. **En la PC:**
   - Flutter 3.47.7 y el SDK de Android (`adb`);
   - .NET 10 (el `global.json` de musubi-api);
   - `musubi-api` clonado junto a este repo (`../musubi-api`).
2. **En el teléfono:** Opciones de desarrollador → **Depuración por USB** activada.
3. Conecta el teléfono por USB y acepta la huella de la PC. `adb devices` debe mostrarlo como `device`.

## Correrla

```powershell
pwsh scripts/run_device_tests.ps1
```

Si hay varios teléfonos, elige uno con `-Device <id>` (el id sale en `flutter devices`).

El script hace esto, y al final deshace todo aunque algo falle:

1. Compila y levanta musubi-api en la PC (Development, en memoria) en `http://localhost:5080`.
2. Levanta `tool/device_code_server.dart` en `5081`. El teléfono le pide ahí los códigos de verificación que la API escribe en su log.
3. Ejecuta `adb reverse` de los dos puertos: en el teléfono, `localhost:5080` y `localhost:5081` son la PC.
4. Instala la app en modo debug (solo debug permite HTTP hacia `localhost`) y corre `integration_test/app_test.dart`.

Si algo falla, el log de la API queda en `build/device/api.log`.

## Qué prueba

| Flujo | Pantallas | Pruebas |
|---|---|---|
| `flows/start_flow.dart` | Inicio como visitante → "Entrar" | 1 |
| `flows/account_flow.dart` | Crear cuenta → código del correo → Verificación lista → Intereses → Inicio; iniciar sesión, reabrir la app con la sesión guardada en el Keystore y cerrar sesión; eliminar la cuenta desde Privacidad | 3 |
| `flows/explore_flow.dart` | Buscar → Producto → Chat (enviar mensaje); Producto → Apartar → Apartado listo (QR), y quien vende lo entrega con el código | 2 |
| `flows/sell_flow.dart` | Publicar → Vender 1…4 con foto → Vender listo → Mis productos; un nombre inapropiado no se publica (moderación) | 2 |

Lo que la prueba no puede tocar en Android se reemplaza:

- la cámara y la galería: la "foto" es un PNG generado en el teléfono;
- el permiso de avisos push;
- la ventana de reseñas de Play;
- la animación de la marca.

Quien vende y los datos de apoyo se preparan por la API con las mismas funciones de `test/integration/support/`.

## En el CI

Los mismos flujos corren en la VM en `test/integration/device_flows_test.dart`, con frames y tiempo reales, contra la API del job `integration`. Si un cambio de pantalla rompe la suite del teléfono, el PR falla antes de llegar a un teléfono.
