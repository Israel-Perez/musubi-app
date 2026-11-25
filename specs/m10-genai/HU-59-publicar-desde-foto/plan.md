# plan.md — HU-59 Publicar un producto a partir de una foto

## 1. Componentes
- `lib/features/listings/`: `PhotoDraftProposal`, `ListingsRepository.draftFromPhoto`, `SellDraftNotifier.fillFromCover` y `_AiFillCard` en `sell_photos_screen.dart`.
- `lib/features/genai/presentation/agreement_providers.dart`: `photoAiNoticeStoreProvider`.
- `assets/legal/aviso-de-privacidad.md` y `docs/play/README.md`.

## 2. Decisiones (con su porqué)
- **En `Vender-1` y no en `Vender-2`:** la IA necesita la foto y en `Vender-1` ya está; así quien vende llega a `Vender-2` con el borrador lleno y solo lo corrige.
- **Se manda la llave de la portada:** la foto ya está subida y moderada; la app espera esa subida en lugar de mandar el archivo otra vez.
- **Un aviso aparte:** el de "Resumir acuerdo" habla del chat; este envía una foto. Cada uno sale la primera vez que aplica.
- **El aviso de privacidad no cambia de versión:** el cambio describe un envío que solo pasa a petición y con su aviso en la app; subir la versión obligaría a pedir aceptarlo a todas las cuentas. Queda para que la usuaria lo decida.

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
- RNF-06: nada sale sin que la persona toque "Llenar con IA" y vea el aviso la primera vez.
- RN-38: la propuesta solo llena el borrador.
- RNF-15: sin IA, la tarjeta avisa y el flujo a mano no cambia.

## 5. Validación
`flutter analyze`, `flutter test`, `run_integration_tests.ps1`, critic; prueba en el celular (T5).

## 6. Secuencia
T1 → T2 → T3 → T4 → T5.
