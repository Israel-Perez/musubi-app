# 02-02 — Publicación en Google Play (tareas)

## T1 — Firma y build de release
- **Qué:** llave de subida, `key.properties`, el AAB firmado y su revisión.
- **Estado:** ✅ Hecho (29-Oct-2026, SCRUM-87).
  - La llave está fuera del repo, en RSA 4096 con alias `upload`.
  - `app-release.aab` `0.3.0+3` está firmado con `CN=Musubi` (`keytool -printcert`).

## T2 — Ficha y contenido de la app
- **Qué:** textos, gráficos y capturas (`docs/play/`), Seguridad de los datos, IARC, público y acceso para revisores.
- **Estado:** 🚧 En curso.
  - Listos en `docs/play/`: ícono, gráfico, 6 capturas, textos y respuestas.
  - Falta: cuenta de revisión y confirmar el público.

## T3 — Prueba interna y prueba cerrada
- **Qué:** subir `0.3.0+3`, inscribir a 12 o más testers y cuidar los 14 días seguidos.
- **Estado:** 🚧 En curso.
  - La cuenta personal está verificada y `0.3.0+3` se subió a la prueba interna.
  - **Prueba cerrada publicada el 30-Oct-2026.** Si los 12 testers siguen inscritos, la solicitud de producción puede enviarse desde el ~13-Nov-2026.
  - Para instalar desde Play hay que desinstalar antes cualquier APK firmado con otra llave.

## T4 — Despliegue desde GitHub
- **Qué:** `release-play.yml` con la cuenta de servicio y los secretos de firma.
- **Estado:** ⏳ Por hacer.

## T5 — Producción
- **Qué:** cuestionario de acceso, publicación y verificación de la descarga.
- **Estado:** ⏳ Por hacer.

## Pendientes
- `NOTE (HU-46)`: eliminar la cuenta desde la app (requisito de Google).
- Decisiones: cuenta de revisores y público objetivo.
