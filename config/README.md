# config — configuración por ambiente (`--dart-define-from-file`)

```powershell
Copy-Item config/dev.example.json config/dev.json      # config/dev.json está ignorado por Git
flutter run --dart-define-from-file=config/dev.json
```

| Archivo | Versionado | Uso |
|---|---|---|
| `dev.example.json` | Sí | Emulador de Android contra musubi-api local: `http://10.0.2.2:5080` (10.0.2.2 es la PC vista desde el emulador; el puerto es el del perfil `http` de la API) |
| `usb.example.json` | Sí | Celular por USB contra musubi-api local: `http://localhost:5080`. Antes, `adb reverse tcp:5080 tcp:5080` (el `localhost` del celular apunta al puerto 5080 de la PC); se pierde al desconectar el cable |
| `demo.example.json` | Sí | Vitrina de muestra (SCRUM-82): `DEMO_CATALOG` muestra los productos de la maqueta mientras llega el catálogo real (HU-06). Copia en `config/demo.json` y pon la URL HTTPS de la API (la de `prod.json`) |
| `staging.example.json` / `prod.example.json` | Sí | Plantillas con HTTPS obligatorio (RNF-02); las URLs reales se definen al desplegar (`musubi-api:02-05`) |
| `dev.json`, `demo.json`, `staging.json`, `prod.json` | **No** (ignorados) | Valores reales de cada desarrollador o del pipeline |

## Reglas (00-04)

- **Todo lo que va en el APK es público.** Cualquier persona puede extraer del APK los valores de `--dart-define`. Aquí solo van la URL base de la API y banderas.
- **Nunca** llaves privadas (IA, Firebase Admin, cifrado de datos de pago): viven solo en `musubi-api`. El critic falla si un `--dart-define` con `SECRET`, `KEY` o `TOKEN` aparece en el código o en el CI.
- `AppConfig.parse` (`lib/core/config/app_config.dart`) valida al arrancar:
  - `ENV` ∈ {dev, staging, prod};
  - URL absoluta;
  - HTTPS fuera de dev;
  - HTTP en dev solo hacia `10.0.2.2`, `localhost` o `127.0.0.1`;
  - `DEMO_CATALOG` solo con `ENV=dev` (un APK de staging o prod nunca muestra datos de muestra).
- La excepción HTTP de dev también está en `android/app/src/debug/res/xml/network_security_config.xml`; release solo permite HTTPS.
- Una clave nueva → fila en la tabla de `specs/phase-01-foundation/01-04-config-reference/spec.md` + ejemplo aquí.
