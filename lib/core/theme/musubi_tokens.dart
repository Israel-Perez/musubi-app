import 'package:flutter/material.dart';

/// Colores de la guia de estilo de la maqueta (docs/maqueta/README.md, seccion
/// 1). El modo oscuro usa el mapa `dc-meta.dark` del prototipo.
@immutable
class MusubiColors extends ThemeExtension<MusubiColors> {
  const new({
    required this.brand,
    required this.brandPressed,
    required this.brandSoft,
    required this.onBrand,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.success,
    required this.successText,
    required this.successSoft,
    required this.warning,
    required this.warningText,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
  });

  /// Rojo Musubi: accion principal, pestana activa y "Se busca".
  final Color brand;
  final Color brandPressed;

  /// Rojo claro: chips seleccionados y tarjetas de solicitud.
  final Color brandSoft;
  final Color onBrand;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color success;
  final Color successText;
  final Color successSoft;

  /// Ambar: "No identificado" de la IA y avisos que no son error.
  final Color warning;
  final Color warningText;
  final Color warningSoft;

  /// Rojo oxido: errores. Distinto del rojo de marca para no confundirse con
  /// un boton.
  final Color error;
  final Color errorSoft;

  static const light = MusubiColors(
    brand: Color(0xFFD7191F),
    brandPressed: Color(0xFFA50F15),
    brandSoft: Color(0xFFFDECEC),
    onBrand: Color(0xFFFFFFFF),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF6F6F7),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6B6B70),
    border: Color(0xFFE4E4E7),
    success: Color(0xFF1E9E5A),
    successText: Color(0xFF167C47),
    successSoft: Color(0xFFE8F6EE),
    warning: Color(0xFFE8A317),
    warningText: Color(0xFF8F5B00),
    warningSoft: Color(0xFFFDF4E1),
    error: Color(0xFFC4320A),
    errorSoft: Color(0xFFFDEEE8),
  );

  /// El relleno rojo de los botones se conserva (`fillKeep` del prototipo);
  /// el texto y los iconos rojos usan la variante clara.
  static const dark = MusubiColors(
    brand: Color(0xFFD7191F),
    brandPressed: Color(0xFFFF8A8E),
    brandSoft: Color(0xFF3A1517),
    onBrand: Color(0xFFFFFFFF),
    background: Color(0xFF17171A),
    surface: Color(0xFF232327),
    textPrimary: Color(0xFFF2F2F4),
    textSecondary: Color(0xFFA4A4AB),
    border: Color(0xFF2E2E33),
    success: Color(0xFF3FCB82),
    successText: Color(0xFF4CD38A),
    successSoft: Color(0xFF12301F),
    warning: Color(0xFFE8A317),
    warningText: Color(0xFFF2B544),
    warningSoft: Color(0xFF3A2C0E),
    error: Color(0xFFFF7A50),
    errorSoft: Color(0xFF3A1A10),
  );

  /// Rojo para texto e iconos sobre el fondo (en oscuro, #FF5C61).
  Color get brandText =>
      background == dark.background ? const Color(0xFFFF5C61) : brand;

  @override
  MusubiColors copyWith({Color? brand, Color? error}) => MusubiColors(
    brand: brand ?? this.brand,
    brandPressed: brandPressed,
    brandSoft: brandSoft,
    onBrand: onBrand,
    background: background,
    surface: surface,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    border: border,
    success: success,
    successText: successText,
    successSoft: successSoft,
    warning: warning,
    warningText: warningText,
    warningSoft: warningSoft,
    error: error ?? this.error,
    errorSoft: errorSoft,
  );

  @override
  MusubiColors lerp(MusubiColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return MusubiColors(
      brand: mix(brand, other.brand),
      brandPressed: mix(brandPressed, other.brandPressed),
      brandSoft: mix(brandSoft, other.brandSoft),
      onBrand: mix(onBrand, other.onBrand),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      border: mix(border, other.border),
      success: mix(success, other.success),
      successText: mix(successText, other.successText),
      successSoft: mix(successSoft, other.successSoft),
      warning: mix(warning, other.warning),
      warningText: mix(warningText, other.warningText),
      warningSoft: mix(warningSoft, other.warningSoft),
      error: mix(error, other.error),
      errorSoft: mix(errorSoft, other.errorSoft),
    );
  }
}

/// Medidas de la guia de estilo: escala de 4 y margen lateral de 20.
abstract final class MusubiSizes {
  static const gutter = 20.0;
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space6 = 24.0;
  static const space8 = 32.0;

  /// Radios: etiquetas, miniaturas, campos, botones, "Se busca", hojas, chips.
  static const radiusTag = 8.0;
  static const radiusThumb = 12.0;
  static const radiusField = 14.0;
  static const radiusButton = 16.0;
  static const radiusWanted = 22.0;
  static const radiusSheet = 28.0;
  static const radiusChip = 999.0;

  /// Alto de boton: accion de pantalla, en tarjeta y minimo tactil.
  static const buttonHeight = 56.0;
  static const buttonHeightCard = 48.0;
  static const minTouch = 44.0;

  /// Barra inferior (sin la zona segura) y boton central "Publicar".
  static const navBarHeight = 60.0;
  static const publishButton = 52.0;
}

/// Tipografia de la guia (tamano/interlineado, peso). Fuente: Plus Jakarta Sans.
abstract final class MusubiType {
  static const family = 'PlusJakartaSans';

  static TextStyle _style(double size, double line, FontWeight weight) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        height: line / size,
        fontWeight: weight,
      );

  static final TextStyle display = _style(28, 34, FontWeight.w800);
  static final TextStyle title1 = _style(26, 32, FontWeight.w800);
  static final TextStyle title2 = _style(19, 24, FontWeight.w800);
  static final TextStyle title3 = _style(16, 21, FontWeight.w800);
  static final TextStyle body = _style(15, 22, FontWeight.w500);
  static final TextStyle bodySmall = _style(13, 18, FontWeight.w600);
  static final TextStyle label = _style(12, 16, FontWeight.w700);
  static final TextStyle overline = _style(
    11,
    14,
    FontWeight.w800,
  ).copyWith(letterSpacing: 11 * 0.06);
  static final TextStyle price = _style(
    17,
    22,
    FontWeight.w800,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  static final TextStyle button = _style(16, 20, FontWeight.w800);

  /// Texto dentro de un campo: 16 para evitar el zoom automatico.
  static final TextStyle field = _style(16, 22, FontWeight.w500);
}
