import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/shake.dart';

/// Codigo de verificacion de la maqueta (`Verificacion`): 6 cajas de 60 de
/// alto con radio 14. Escrita: borde gris; la siguiente: borde rojo con halo
/// y cursor que parpadea; vacia: borde claro; verificado: borde verde.
///
/// Un solo campo invisible encima recibe el teclado, el pegado y el
/// autocompletado del codigo (`oneTimeCode`).
class OtpField extends StatefulWidget {
  const new({
    required this.controller,
    super.key,
    this.fieldKey,
    this.length = 6,
    this.onCompleted,
    this.shakeTrigger,
    this.verified = false,
    this.autofocus = false,
  });

  final TextEditingController controller;

  /// Llave del TextField interno (para pruebas).
  final Key? fieldKey;
  final int length;

  /// Se llama al escribir el ultimo digito.
  final ValueChanged<String>? onCompleted;

  /// Cambia para sacudir las cajas (codigo incorrecto o incompleto).
  final Object? shakeTrigger;

  /// Codigo aceptado: bordes verdes.
  final bool verified;
  final bool autofocus;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final _focus = FocusNode();
  Timer? _blink;
  bool _caretOn = true;
  String? _completed;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_restartBlink);
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(OtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    _blink?.cancel();
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _onText() {
    _restartBlink();
    final code = widget.controller.text;
    // El controlador tambien avisa cambios de seleccion: cada codigo completo
    // se entrega una sola vez.
    if (code.length < widget.length) {
      _completed = null;
    } else if (code != _completed) {
      _completed = code;
      widget.onCompleted?.call(code);
    }
  }

  /// `__blink` de la maqueta: medio segundo visible y medio oculto. Con un
  /// temporizador (no un ticker) para no detener `pumpAndSettle`.
  void _restartBlink() {
    _blink?.cancel();
    if (!mounted) return;
    setState(() => _caretOn = true);
    if (!_focus.hasFocus) return;
    _blink = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _caretOn = !_caretOn);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final code = widget.controller.text;
    final focused = _focus.hasFocus;

    Widget box(int index) {
      final digit = index < code.length ? code[index] : null;
      final active = focused && index == code.length && !widget.verified;
      final border = widget.verified
          ? c.success
          : active
          ? c.brandBorder
          : digit != null
          ? c.neutralStrong
          : c.border;
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 60,
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
            border: Border.all(color: border, width: 1.5),
            boxShadow: active
                ? [BoxShadow(color: c.brandSoft, spreadRadius: 4)]
                : null,
          ),
          alignment: Alignment.center,
          child: digit != null
              ? _PopIn(
                  key: ValueKey('$index-$digit'),
                  child: Text(
                    digit,
                    style: MusubiType.style(
                      24,
                      weight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                )
              : active && _caretOn
              ? Container(width: 2, height: 24, color: c.brand)
              : null,
        ),
      );
    }

    return Shake(
      trigger: widget.shakeTrigger,
      child: Stack(
        children: [
          Row(
            spacing: MusubiSizes.space2,
            children: [for (var i = 0; i < widget.length; i++) box(i)],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                key: widget.fieldKey,
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                showCursor: false,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration.collapsed(hintText: null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `__pop`: el digito aparece desde 0.8 (0.25 s).
class _PopIn extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 250),
    curve: Curves.ease,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
    ),
    child: child,
  );
}
