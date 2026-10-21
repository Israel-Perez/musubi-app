import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';

/// Campo de la guia de estilo: etiqueta siempre visible arriba, ayuda debajo
/// y error en rojo oxido con icono (nunca solo color).
class MusubiTextField extends StatefulWidget {
  const new({
    required this.label,
    super.key,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscure = false,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.fieldKey,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;

  /// Error que viene de la API (por ejemplo, `errors.email` de un 400).
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// Contrasenas: oculta el texto y agrega el boton para mostrarlo.
  final bool obscure;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Llave del TextFormField interno (para pruebas).
  final Key? fieldKey;

  @override
  State<MusubiTextField> createState() => _MusubiTextFieldState();
}

class _MusubiTextFieldState extends State<MusubiTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.labelMedium),
        const SizedBox(height: MusubiSizes.space2),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _hidden,
          enableSuggestions: !widget.obscure,
          autocorrect: !widget.obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: MusubiType.field.copyWith(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            helperMaxLines: 2,
            errorText: widget.errorText,
            errorMaxLines: 3,
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
