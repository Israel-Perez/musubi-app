import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/css_line_box.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/shake.dart';

/// Campo de la maqueta: etiqueta arriba (13, peso 700), caja de 52 con radio
/// 14 y borde de 1.5. Con foco el borde es rojo con un halo de 4; con error,
/// rojo oxido, la caja se sacude y debajo va el aviso con su icono (nunca
/// solo el color).
class MusubiTextField extends StatefulWidget {
  const new({
    required this.label,
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.errorText,
    this.shakeTrigger,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscure = false,
    this.enabled = true,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.fieldKey,
    this.prefixIcon,
    this.suffix,
    this.footer,
    this.sheet = false,
    this.multiline = false,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;

  /// Error que se muestra bajo la caja (de la API o de la validacion). Vacio:
  /// solo el borde rojo (la explicacion va en otra parte).
  final String? errorText;

  /// Cambia en cada intento fallido para volver a sacudir la caja.
  final Object? shakeTrigger;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// Contrasenas: oculta el texto y agrega el ojo para mostrarlo.
  final bool obscure;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Llave del TextField interno (para pruebas).
  final Key? fieldKey;

  /// Icono a la izquierda (sobre de "Correo institucional").
  final MusubiIconData? prefixIcon;

  /// Elemento a la derecha (palomita de campus detectado).
  final Widget? suffix;

  /// Lo que va bajo la caja: campus detectado, reglas de la contrasena.
  final Widget? footer;

  /// Dentro de una hoja con titulo (`.s-field`): la etiqueta hereda la linea
  /// de 22 del cuerpo de la hoja y la separacion es de 6.
  final bool sheet;

  /// Caja de varias lineas (`.s-field textarea`): 96 de alto, relleno de
  /// `12 14` y linea de 22 ("Cuentanos que paso", HU-28).
  final bool multiline;

  @override
  State<MusubiTextField> createState() => _MusubiTextFieldState();
}

class _MusubiTextFieldState extends State<MusubiTextField> {
  late bool _hidden = widget.obscure;
  FocusNode? _ownFocus;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(MusubiTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final error = widget.errorText;
    final focused = _focus.hasFocus;
    final trailing = widget.obscure
        ? _EyeButton(
            hidden: _hidden,
            onTap: () => setState(() => _hidden = !_hidden),
          )
        : widget.suffix;

    final multiline = widget.multiline;
    final fieldStyle = multiline
        ? MusubiType.field.copyWith(height: 22 / 16)
        : MusubiType.field;
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: multiline ? 96 : MusubiSizes.fieldHeight,
      padding: multiline
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
          : EdgeInsets.only(left: 14, right: widget.obscure ? 4 : 14),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
        border: Border.all(
          color: error != null
              ? c.error
              : focused
              ? c.brandBorder
              : c.border,
          width: 1.5,
        ),
        boxShadow: focused && error == null
            ? [BoxShadow(color: c.brandSoft, spreadRadius: 4)]
            : null,
      ),
      child: Row(
        spacing: widget.obscure ? 6 : 10,
        children: [
          if (widget.prefixIcon != null)
            MusubiIcon(
              widget.prefixIcon!,
              size: 20,
              strokeWidth: 1.9,
              color: c.textSecondary,
            ),
          Expanded(
            child: TextField(
              key: widget.fieldKey,
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              obscureText: _hidden,
              enableSuggestions: !widget.obscure,
              autocorrect: !widget.obscure,
              keyboardType: multiline
                  ? TextInputType.multiline
                  : widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              maxLines: multiline ? null : 1,
              expands: multiline,
              textAlignVertical: multiline ? TextAlignVertical.top : null,
              textCapitalization: multiline
                  ? TextCapitalization.sentences
                  : TextCapitalization.none,
              cursorColor: c.brand,
              style: fieldStyle.copyWith(
                color: c.textPrimary,
                letterSpacing: _hidden ? 1.6 : null,
              ),
              decoration: InputDecoration.collapsed(
                hintText: widget.hint,
                hintStyle: fieldStyle.copyWith(color: c.placeholder),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );

    final label = Text(
      widget.label,
      style: MusubiType.label.copyWith(color: c.textPrimary),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: widget.sheet ? 6 : MusubiSizes.space2,
      children: [
        if (widget.sheet)
          SizedBox(
            height: 22,
            child: Align(alignment: Alignment.centerLeft, child: label),
          )
        else
          CssLineBox(fontSize: 13, child: label),
        Shake(
          trigger: error == null ? null : widget.shakeTrigger ?? error,
          pattern: ShakePattern.field,
          child: box,
        ),
        if (error != null && error.isNotEmpty) FieldMessage(text: error),
        ?widget.footer,
      ],
    );
  }
}

/// Aviso bajo un campo: icono de 16 y texto de 13 (peso 600). Por defecto es
/// un error en rojo oxido con el triangulo.
class FieldMessage extends StatelessWidget {
  const new({
    required this.text,
    super.key,
    this.icon = MusubiIcons.triangleAlert,
    this.color,
  });

  final String text;
  final MusubiIconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.musubi.error;
    return Semantics(
      liveRegion: true,
      child: Row(
        spacing: 6,
        children: [
          MusubiIcon(icon, size: 16, color: color),
          Expanded(
            child: CssLineBox(
              fontSize: 13,
              child: Text(
                text,
                style: MusubiType.style(
                  13,
                  weight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  const new({required this.hidden, required this.onTap});

  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
    builder: (context, _) => SizedBox.square(
      dimension: MusubiSizes.minTouch,
      child: Center(
        child: MusubiIcon(
          hidden ? MusubiIcons.eye : MusubiIcons.eyeOff,
          size: 20,
          strokeWidth: 1.9,
          color: context.musubi.textSecondary,
        ),
      ),
    ),
  );
}
