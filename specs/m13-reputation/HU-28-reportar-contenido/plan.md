# HU-28 — Reportar contenido o usuarios sospechosos (app, plan)

## Decisiones
- **Una sola función `showReportSheet(target)`:** la maqueta usa la misma `reportSheet` desde el chat y desde Ajustes; solo cambia lo que se reporta.
- **Los tiempos de la maqueta:** la opción se marca y se cierra a los 160 ms (`MusubiOptions`) y la siguiente hoja abre 240 ms después (`later(240)`).
- **Error en la hoja, no en un aviso:** así no se pierde lo que se escribió.
- **Texto honesto bajo la caja:** el "chat de soporte" de la maqueta no existe; el equipo responde por correo.

## Archivos
- **Nuevos:** `lib/features/reputation/{domain,data,presentation}/…` e íconos `flag` y `circleHelp`.
- **Cambian:** `MusubiTextField` (`multiline`), `settings_screen.dart` ("Reportar un problema") y `chat_screen.dart` ("Más opciones").
- **Pruebas:** `http_reputation_repository_test.dart`, `reputation_flow_test.dart` y `test/helpers/fake_reputation.dart`.
