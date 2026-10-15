# lib/features — convención feature-first (módulos M-01…M-14)

Cada módulo de `docs/modulos.md` vive en `lib/features/<modulo>/` y se crea con su **primera HU** (no hay carpetas vacías). Dentro, tres capas con dependencias en un solo sentido (`presentation → domain ← data`):

```
lib/features/<modulo>/
├── domain/         # modelos inmutables (sealed/final) e interfaces de repositorio. Sin Flutter UI ni Dio.
├── data/           # implementaciones de los repositorios (Dio) que consumen filas de musubi-api/docs/endpoints.md
└── presentation/   # providers de Riverpod (estado) + pantallas y widgets
```

## Reglas

- La **UI nunca llama a Dio**: usa un provider que expone el estado; el provider usa la interfaz del repositorio.
- Cada repositorio tiene un **fake** en `test/helpers/` (skill `deferred-scope-fakes`). Si el endpoint aún no existe en el back, el provider de producción usa el fake con `NOTE (musubi-api:HU-NN)`.
- Los errores de red se traducen a estados de dominio con mensajes en español (`lib/core/errors/`); un repositorio no deja escapar `DioException` a la UI.
- Las rutas de la API se agregan a `lib/core/network/api_paths.dart`, citando su fila del catálogo del back (skill `api-contract`).
- Las rutas de navegación del módulo se registran en `lib/app/router.dart`.
- Pruebas espejo en `test/features/<modulo>/{data,presentation}/`.

## Lo que no es un módulo

- `lib/app/`: raíz de la app (tema, rutas, idioma).
- `lib/core/`: configuración (`config/`), red (`network/`), errores (`errors/`) y tema (`theme/`), compartidos por los módulos.
- `lib/features/status/`: feature de plataforma de la fundación (ping a la API, spec 01-03); no pertenece a M-01…M-14.
