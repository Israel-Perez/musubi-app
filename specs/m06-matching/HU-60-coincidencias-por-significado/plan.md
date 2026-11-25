# plan.md — HU-60 Coincidencias por significado

## 1. Componentes
`assets/legal/aviso-de-privacidad.md` y `docs/play/README.md`. La lógica está en musubi-api.

## 2. Decisiones (con su porqué)
- **Sin código en la app:** la API conserva las formas de "Ya coinciden" y de los avisos; la app las muestra igual.
- **Se declara en el aviso y en Play:** los textos públicos salen a Google sin que nadie lo pida. Aunque ya son públicos en el campus, la capa gratuita de Gemini puede usarlos.
- **El aviso no cambia de versión** (igual que en HU-59): el cambio describe textos públicos sin contacto.

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
RNF-06 sigue igual (no salen conversaciones); HU-46 borra los vectores.

## 5. Validación
`flutter test test/features/auth/legal_documents_test.dart`, `flutter analyze` y critic.

## 6. Secuencia
T1 → T2.
