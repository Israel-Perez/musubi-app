# plan.md — HU-46 Eliminar mi cuenta y mis datos (app)

## 1. Componentes
- **Datos:** `AccountRepository` y `HttpAccountRepository`, con sesión.
- **Pantalla y flujo:** `PrivacyScreen`, `DeleteAccountButton` y `ConfirmPasswordSheet`.
- **Piezas reutilizables:**
  - `SettingsRow` pasa a un archivo propio;
  - `MusubiTopBar.titleAtStart`;
  - el token `dangerText` y el ícono `trash`.
- **Navegación:** la ruta `/ajustes/privacidad` y la sección "Privacidad y seguridad" en `Ajustes`.

## 2. Decisiones
- **Contraseña en una hoja, después del diálogo:** se respeta el diálogo de la maqueta tal cual y se agrega el paso de seguridad. Así la acción irreversible pide una prueba de que la persona es la titular.
- **Al terminar, primero a Inicio y después `signOut()`,** como "Cerrar sesión": la guardia no manda a "Iniciar sesión". No se llama a `logOut()` porque la API ya borró las sesiones.
- **`Privacidad` muestra solo lo que funciona:** "Quién te ve" llega con HU-04 y los bloqueos con HU-28.

## 3. Validación
- Las pruebas de `spec.md`.
- La captura `privacidad` contra la maqueta.
- La prueba en el teléfono desde Google Play, después del despliegue del back.

## 4. Secuencia
1. Repositorio.
2. Hoja y botón.
3. Pantalla y ruta.
4. Fila en `Ajustes`.
5. Pruebas.
6. Captura.
7. Documentación.
8. Versión `0.3.0+4` para la prueba cerrada.
