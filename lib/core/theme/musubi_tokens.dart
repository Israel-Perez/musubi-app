import 'package:flutter/material.dart';

/// Colores de la maqueta (docs/maqueta). El modo oscuro aplica el mapa
/// `dc-meta.dark` del prototipo: cada token lleva su valor claro y oscuro
/// juntos, como en ese mapa. Los rellenos rojos y el tinta #1C1C1E de los
/// fondos se conservan en oscuro (`fillKeep`).
@immutable
class MusubiColors extends ThemeExtension<MusubiColors> {
  const new _(this.brightness);

  static const light = MusubiColors._(Brightness.light);
  static const dark = MusubiColors._(Brightness.dark);

  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  Color _pick(int light, int dark) => Color(isDark ? dark : light);

  // Marca.

  /// Relleno rojo de botones, pestanas y circulos (igual en oscuro).
  Color get brand => const Color(0xFFD7191F);

  /// Boton principal presionado (`.pr:active`).
  Color get brandPressed => const Color(0xFFA50F15);

  /// Rojo de textos e iconos sobre el fondo.
  Color get brandText => _pick(0xFFD7191F, 0xFFFF5C61);

  /// Rojo oscuro: precio de "Se busca" y pastilla "Estudiante verificado".
  Color get brandStrongText => _pick(0xFFA50F15, 0xFFFF8A8E);

  /// Borde rojo (campo con foco).
  Color get brandBorder => _pick(0xFFD7191F, 0xFFE5383D);

  /// Rojo claro: boletos "Se busca", ilustraciones y halo del foco.
  Color get brandSoft => _pick(0xFFFDECEC, 0xFF3A1517);

  /// Rojo muy claro: boleto "Se busca" mientras carga.
  Color get brandFaint => _pick(0xFFFDF3F3, 0xFF2A1719);
  Color get onBrand => const Color(0xFFFFFFFF);

  // Fondos y lineas.

  Color get background => _pick(0xFFFFFFFF, 0xFF17171A);

  /// Chips, buscador, tarjetas grises.
  Color get surface => _pick(0xFFF6F6F7, 0xFF232327);

  /// Chip presionado (`.pc:active`).
  Color get surfacePressed => _pick(0xFFECECEF, 0xFF2E2E33);

  /// Hojas y dialogos de la capa de la app (en oscuro se elevan un poco).
  Color get elevated => _pick(0xFFFFFFFF, 0xFF1E1E22);

  /// Superficie dentro de una hoja o dialogo de la capa de la app.
  Color get elevatedSurface => _pick(0xFFF6F6F7, 0xFF2A2A2F);

  /// Lineas de la capa de la app (manija de la hoja).
  Color get elevatedLine => _pick(0xFFE4E4E7, 0xFF36363D);
  Color get border => _pick(0xFFE4E4E7, 0xFF2E2E33);

  /// Interruptor apagado y manija de "Filtrar".
  Color get borderStrong => _pick(0xFFD4D4D8, 0xFF3A3A40);
  Color get divider => _pick(0xFFF0F0F2, 0xFF26262A);

  /// Caja del codigo ya escrita y puntos de "escribiendo".
  Color get neutralStrong => _pick(0xFFC9C9CF, 0xFF4A4A52);

  /// Fondos oscuros que no cambian en modo noche (banner, "Agotado").
  Color get inverse => const Color(0xFF1C1C1E);

  /// Pastillas blancas sobre fotos (vistas, corazon).
  Color get overlayPill =>
      isDark ? const Color(0xE61E1E22) : const Color(0xF0FFFFFF);

  /// Velo de las hojas dentro de la pantalla ("Filtrar").
  Color get scrim => isDark ? const Color(0x9E000000) : const Color(0x7A1C1C1E);

  /// Velo de la hoja "Crea tu cuenta" (no cambia en oscuro).
  Color get gateScrim => const Color(0x8C1C1C1E);

  /// Velo de los dialogos de la capa de la app.
  Color get dialogScrim =>
      isDark ? const Color(0x9E000000) : const Color(0x701C1C1E);

  // Texto.

  Color get textPrimary => _pick(0xFF1C1C1E, 0xFFF2F2F4);
  Color get textSecondary => _pick(0xFF6B6B70, 0xFFA4A4AB);

  /// Gris oscuro: "PAGA HASTA" y opciones sin elegir.
  Color get textTertiary => _pick(0xFF55555A, 0xFFBDBDC3);

  /// Texto de un boton deshabilitado.
  Color get disabledText => const Color(0xFF8E8E93);

  /// Texto de ejemplo dentro de un campo ("tu.nombre@uttt.edu.mx").
  Color get placeholder => _pick(0xFF77777D, 0xFF8A8A92);

  // Estados.

  Color get success => _pick(0xFF1E9E5A, 0xFF3FCB82);
  Color get successText => _pick(0xFF167C47, 0xFF4CD38A);
  Color get successSoft => _pick(0xFFE8F6EE, 0xFF12301F);

  /// Ambar: puntos de "Quedan 2" y estrellas (igual en oscuro).
  Color get warning => const Color(0xFFE8A317);
  Color get warningText => _pick(0xFF8F5B00, 0xFFF2B544);
  Color get warningSoft => _pick(0xFFFDF4E1, 0xFF3A2C0E);

  /// Rojo oxido: errores. Distinto del rojo de marca para no confundirse con
  /// un boton.
  Color get error => _pick(0xFFC4320A, 0xFFFF7A50);
  Color get errorSoft => _pick(0xFFFDEEE8, 0xFF3A1A10);

  /// Relleno rojo oxido (insignia "!" de `Inicio-error`; igual en oscuro).
  Color get errorFill => const Color(0xFFC4320A);
  Color get errorBorder => _pick(0xFFF4CBBB, 0xFF6A3220);

  /// Linea punteada del boleto "Se busca".
  Color get ticketLine => _pick(0xFFEFA9AC, 0xFF6B2A2E);

  // Aviso breve (snack).

  Color get snack => _pick(0xFF1C1C1E, 0xFFF2F2F4);
  Color get onSnack => _pick(0xFFFFFFFF, 0xFF17171A);

  /// Circulo del icono del aviso informativo y su icono.
  Color get snackInfo => _pick(0xFF3A3A40, 0xFFC9C9CF);
  Color get onSnackInfo => _pick(0xFFFFFFFF, 0xFF17171A);

  /// Accion dentro del aviso ("Pegar código").
  Color get snackAction => _pick(0xFFFF8A8E, 0xFFD7191F);

  // Esqueleto de carga (`.sk` y `.skr`).

  Color get skeleton => _pick(0xFFEEEEF0, 0xFF26262A);
  Color get skeletonShine => _pick(0xFFF7F7F8, 0xFF2E2E33);
  Color get skeletonBrand => _pick(0xFFFBE3E4, 0xFF3A1C1F);
  Color get skeletonBrandShine => _pick(0xFFFDF1F1, 0xFF2A1719);

  /// Avatares de iniciales de la comunidad (fondo, texto).
  List<(Color, Color)> get avatars => [
    (_pick(0xFFE9E2F3, 0xFF2E2440), _pick(0xFF5B3E86, 0xFFC7AEEB)),
    (_pick(0xFFFBE3D6, 0xFF3D2418), _pick(0xFF8A3E17, 0xFFF0AE88)),
    (_pick(0xFFDCEBF7, 0xFF1E3247), _pick(0xFF1F4E79, 0xFF9CC3EA)),
    (_pick(0xFFDDEBDD, 0xFF1F3321), _pick(0xFF2F5D34, 0xFF9ED3A6)),
    (_pick(0xFFF1E4D3, 0xFF3A2C1D), _pick(0xFF7A4E1D, 0xFFE5BE8E)),
  ];

  @override
  MusubiColors copyWith() => this;

  /// Sin mezcla: el cambio de tema cambia todos los tokens a la vez.
  @override
  MusubiColors lerp(MusubiColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// Medidas de la maqueta: escala de 4 y margen lateral de 20.
abstract final class MusubiSizes {
  static const gutter = 20.0;
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space6 = 24.0;
  static const space8 = 32.0;

  /// Radios: miniaturas, campos, botones, boletos, hojas y chips.
  static const radiusThumb = 12.0;
  static const radiusField = 14.0;
  static const radiusButton = 16.0;
  static const radiusWanted = 22.0;
  static const radiusSheet = 28.0;
  static const radiusGate = 32.0;
  static const radiusChip = 999.0;

  /// Alto de boton: accion de pantalla, en hoja y chico (minimo tactil).
  static const buttonHeight = 56.0;
  static const buttonHeightSheet = 54.0;
  static const buttonHeightSmall = 44.0;
  static const minTouch = 44.0;

  /// Campo de texto.
  static const fieldHeight = 52.0;

  /// Barra inferior (sin la zona segura) y boton central "Publicar".
  static const navBarHeight = 60.0;
  static const publishButton = 52.0;
}

/// Tipografia de la maqueta: Plus Jakarta Sans con el interlineado de CSS
/// (`line-height` reparte el espacio arriba y abajo por igual) y el espaciado
/// entre letras en `em`.
abstract final class MusubiType {
  static const family = 'PlusJakartaSans';

  /// `line-height: normal` de Plus Jakarta Sans: (1038 + 222) / 1000 de sus
  /// metricas `hhea`. Se fija para no heredar el interlineado del tema.
  static const normalLineHeight = 1.26;

  /// Alto de una linea `normal` como la deja Chrome en un telefono a 3x: el
  /// ascenso (1.038) y el descenso (0.222) se redondean por separado a
  /// pixeles del dispositivo. Flutter redondea la linea entera a un entero:
  /// a 13 px, Chrome da 16.333 y Flutter 16.
  static double normalLineBox(double size) =>
      ((3 * 1.038 * size).roundToDouble() +
          (3 * 0.222 * size).roundToDouble()) /
      3;

  /// Estilo de la maqueta: `font-size` [size], `line-height` [line] en px (o
  /// `normal` si es nulo) y `letter-spacing` [em] en em.
  static TextStyle style(
    double size, {
    FontWeight weight = FontWeight.w500,
    double? line,
    double em = 0,
    Color? color,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    height: line == null ? normalLineHeight : line / size,
    leadingDistribution: TextLeadingDistribution.even,
    // Siempre explicito: si no, se hereda el 0.25 de la tipografia de Material.
    letterSpacing: em * size,
    color: color,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );

  /// Titulo de pantalla ("Hola de nuevo", "Crea tu cuenta").
  static final TextStyle display = style(
    28,
    weight: FontWeight.w800,
    line: 34,
    em: -0.025,
  );

  /// Titulo de Verificacion y bienvenida.
  static final TextStyle title1 = style(
    26,
    weight: FontWeight.w800,
    line: 32,
    em: -0.02,
  );

  /// Titulo de hoja o dialogo.
  static final TextStyle title2 = style(
    19,
    weight: FontWeight.w800,
    line: 25,
    em: -0.02,
  );
  static final TextStyle title3 = style(16, weight: FontWeight.w800, line: 21);

  /// Texto de apoyo bajo un titulo.
  static final TextStyle body = style(15, line: 22);
  static final TextStyle bodySmall = style(
    13,
    weight: FontWeight.w600,
    line: 18,
  );

  /// Etiqueta de un campo.
  static final TextStyle label = style(13, weight: FontWeight.w700);

  /// "PASO 1 DE 2".
  static final TextStyle eyebrow = style(12, weight: FontWeight.w800, em: 0.08);
  static final TextStyle price = style(
    17,
    weight: FontWeight.w800,
    line: 22,
    tabular: true,
  );

  /// Texto de un boton grande.
  static final TextStyle button = style(16, weight: FontWeight.w700);

  /// Texto dentro de un campo: 16 para evitar el zoom automatico.
  static final TextStyle field = style(16);
}
