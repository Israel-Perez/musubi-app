import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/orders/domain/reservation_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';

// `Verificar-comprador` es oscuro en los dos temas (como una camara).
const _dark = Color(0xFF0E0E10);
const _segment = Color(0xFF232326);
const _white = Color(0xFFFEFEFE);
const _ink = Color(0xFF111113);
const _muted = Color(0xFFC9C9CF);
const _soft = Color(0xFFA1A1A6);
const _viewfinder = Color(0xFF1F1F22);
const _viewfinderLit = Color(0xFF3A3A3F);
const _torchOn = Color(0xFFFFD66B);
const _good = Color(0xFF6FD39A);
const _bad = Color(0xFFFF7A6E);
const _off = Color(0xFF2C2C30);
const _offText = Color(0xFF8E8E93);
const _card = Color(0xFFFFFFFF);
const _cardText = Color(0xFF1C1C1E);
const _cardSoft = Color(0xFF6B6B70);

String _first(String name) => name.trim().split(RegExp(r'\s+')).first;

/// La camara que lee el QR del apartado. [onCode] recibe el texto de cada QR
/// leido; [torch] enciende la linterna.
typedef QrCameraBuilder = Widget Function({
  required ValueChanged<String> onCode,
  required bool torch,
});

/// La camara de `Verificar-comprador` (`mobile_scanner`). En pruebas y
/// capturas, una vista fija.
final qrCameraProvider = Provider<QrCameraBuilder>(
  (ref) =>
      ({required onCode, required torch}) =>
          CameraQrView(onCode: onCode, torch: torch),
);

/// `mobile_scanner` con la linea roja que baja y sube (2 s). Sin permiso o sin
/// camara dice que se puede escribir el codigo.
class CameraQrView extends StatefulWidget {
  const new({required this.onCode, required this.torch, super.key});

  final ValueChanged<String> onCode;
  final bool torch;

  @override
  State<CameraQrView> createState() => _CameraQrViewState();
}

class _CameraQrViewState extends State<CameraQrView>
    with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  late final _scan = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _scan.stop();
    } else if (!_scan.isAnimating) {
      _scan.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CameraQrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.torch != widget.torch) {
      unawaited(_controller.toggleTorch().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          for (final barcode in capture.barcodes) {
            final raw = barcode.rawValue;
            if (raw != null) widget.onCode(raw);
          }
        },
        errorBuilder: (context, error) => _CameraProblem(
          permission:
              error.errorCode == MobileScannerErrorCode.permissionDenied,
        ),
      ),
      AnimatedBuilder(
        animation: CurvedAnimation(parent: _scan, curve: Curves.easeInOut),
        builder: (context, _) => Positioned(
          left: 18,
          right: 18,
          top: 18 + 232 * Curves.easeInOut.transform(_scan.value),
          child: const ScanLine(),
        ),
      ),
    ],
  );
}

/// Sin camara: "Escribe el código".
class _CameraProblem extends StatelessWidget {
  const new({required this.permission});

  final bool permission;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Center(
      child: Text(
        permission
            ? 'Permite la cámara en los ajustes del teléfono o usa "Escribir '
                  'código".'
            : 'No pudimos abrir la cámara. Usa "Escribir código".',
        textAlign: TextAlign.center,
        style: MusubiType.style(
          14,
          weight: FontWeight.w700,
          line: 20,
          color: _white,
        ),
      ),
    ),
  );
}

/// La linea roja del visor (3 de alto con brillo).
class ScanLine extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 3,
    decoration: BoxDecoration(
      color: context.musubi.brand,
      borderRadius: BorderRadius.circular(2),
      boxShadow: const [
        BoxShadow(color: Color(0xD9D7191F), blurRadius: 14, spreadRadius: 2),
      ],
    ),
  );
}

enum _Mode { scan, code }

/// `Verificar-comprador` (HU-52, quien vende): "Escanear QR" o "Escribir
/// código", la linterna y abajo quien aparto y que. El codigo se verifica en
/// la API (5 intentos); al acertar abre `Apartado-verificado`.
class VerifyBuyerScreen extends ConsumerStatefulWidget {
  const new({required this.reservationId, super.key});

  final String reservationId;

  @override
  ConsumerState<VerifyBuyerScreen> createState() => _VerifyBuyerScreenState();
}

class _VerifyBuyerScreenState extends ConsumerState<VerifyBuyerScreen> {
  final _code = TextEditingController();
  _Mode _mode = _Mode.scan;
  bool _torch = false;
  bool _busy = false;
  bool _ok = false;

  /// "Ese código no coincide" y el aviso de la API (intentos, bloqueo).
  String? _problem;

  @override
  void initState() {
    super.initState();
    _code.addListener(() {
      if (_problem != null && _code.text.length < 6) {
        setState(() => _problem = null);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _close() => context.canPop()
      ? context.pop()
      : context.go(AppRoutes.myReservationsTab('seller'));

  void _onQr(String raw) {
    if (_busy || _ok) return;
    final code = codeFromQr(raw, widget.reservationId);
    if (code == null) {
      setState(() => _problem = 'Ese QR no es de este apartado');
      return;
    }
    unawaited(_verify(code));
  }

  Future<void> _verify(String code) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      await ref
          .read(reservationRepositoryProvider)
          .verify(widget.reservationId, code);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _ok = true;
      });
      ref.invalidate(reservationProvider(widget.reservationId));
      context.pushReplacement(AppRoutes.buyerVerified(widget.reservationId));
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      ref.invalidate(reservationProvider(widget.reservationId));
      setState(() {
        _busy = false;
        _problem = switch (failure.code) {
          'reservations.invalid_code' => 'Ese código no coincide',
          'reservations.code_locked' ||
          'reservations.not_active' ||
          'reservations.invalid_code_format' => failure.message,
          _ => null,
        };
      });
      if (_problem == null) {
        showMusubiSnack(
          messenger,
          failure.message,
          icon: MusubiIcons.circleAlert,
          tone: SnackTone.warn,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservation = ref.watch(reservationProvider(widget.reservationId));
    final value = reservation.value;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _dark,
        body: switch (reservation) {
          AsyncError(:final error) when value == null => SafeArea(
            child: ErrorView(
              message: error is ApiFailure
                  ? error.message
                  : 'No pudimos abrir el apartado.',
              onRetry: () =>
                  ref.invalidate(reservationProvider(widget.reservationId)),
            ),
          ),
          _ when value == null => const Center(
            child: MusubiSpinner(color: _white),
          ),
          _ => _body(value),
        },
      ),
    );
  }

  Widget _body(Reservation r) {
    final buyer = _first(r.buyerName);
    final camera = ref.watch(qrCameraProvider);
    final left = r.codeAttemptsLeft;
    final problem = _problem == 'Ese código no coincide' && left != null
        ? 'Ese código no coincide · '
              '${left == 1 ? 'te queda 1 intento' : 'te quedan $left intentos'}'
        : _problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Pressable(
                  key: const Key('verify-close'),
                  onTap: _close,
                  semanticLabel: 'Cerrar',
                  builder: (context, _) => const SizedBox.square(
                    dimension: MusubiSizes.minTouch,
                    child: Center(
                      child: MusubiIcon(MusubiIcons.x, size: 22, color: _white),
                    ),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Verificar comprador',
                      textAlign: TextAlign.center,
                      style: MusubiType.style(
                        17,
                        weight: FontWeight.w800,
                        line: 22,
                        color: _white,
                      ),
                    ),
                  ),
                ),
                Pressable(
                  key: const Key('verify-torch'),
                  onTap: _mode == _Mode.scan
                      ? () => setState(() => _torch = !_torch)
                      : null,
                  selected: _torch,
                  semanticLabel: 'Linterna',
                  builder: (context, _) => SizedBox.square(
                    dimension: MusubiSizes.minTouch,
                    child: Center(
                      child: MusubiIcon(
                        MusubiIcons.flashlight,
                        size: 22,
                        strokeWidth: 1.9,
                        color: _torch ? _torchOn : _white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _ModeSwitch(
            mode: _mode,
            onSelect: (mode) => setState(() {
              _mode = mode;
              _problem = null;
              if (mode == _Mode.code) _torch = false;
            }),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: _mode == _Mode.scan
                ? Column(
                    children: [
                      Container(
                        key: const Key('verify-viewfinder'),
                        margin: const EdgeInsets.only(top: 30),
                        width: 270,
                        height: 270,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: _torch ? _viewfinderLit : _viewfinder,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (r.active) camera(onCode: _onQr, torch: _torch),
                            const _Corners(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          'Apunta al QR de $buyer',
                          style: MusubiType.style(
                            16,
                            weight: FontWeight.w800,
                            line: 22,
                            color: _white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _ScanStatus(
                          busy: _busy,
                          problem: r.active
                              ? problem
                              : 'Este apartado ya no está activo',
                        ),
                      ),
                    ],
                  )
                : _CodeForm(
                    buyer: buyer,
                    controller: _code,
                    busy: _busy,
                    ok: _ok,
                    problem: r.active
                        ? problem
                        : 'Este apartado ya no está activo',
                    onVerify: r.active && _code.text.length == 6
                        ? () => unawaited(_verify(_code.text))
                        : null,
                  ),
          ),
        ),
        _BuyerCard(reservation: r),
      ],
    );
  }
}

/// "Escanear QR" / "Escribir código" (48 de alto, fondo `#232326`).
class _ModeSwitch extends StatelessWidget {
  const new({required this.mode, required this.onSelect});

  final _Mode mode;
  final ValueChanged<_Mode> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: _segment,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      spacing: 3,
      children: [
        for (final (value, label, icon) in [
          (_Mode.scan, 'Escanear QR', MusubiIcons.scan),
          (_Mode.code, 'Escribir código', MusubiIcons.keyboard),
        ])
          Expanded(
            child: Pressable(
              key: Key('verify-mode-${value.name}'),
              onTap: () => onSelect(value),
              selected: value == mode,
              semanticLabel: label,
              builder: (context, _) => AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == mode ? _white : null,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 6,
                  children: [
                    MusubiIcon(
                      icon,
                      size: 16,
                      strokeWidth: 2.2,
                      color: value == mode ? _ink : _muted,
                    ),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          14,
                          weight: value == mode
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: value == mode ? _ink : _muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Las cuatro esquinas blancas del visor (52 con borde de 5 y radio 30).
class _Corners extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: _white, width: 5);
    Widget corner({required bool top, required bool left}) => Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            left: left ? side : BorderSide.none,
            right: left ? BorderSide.none : side,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(30) : Radius.zero,
            topRight: top && !left ? const Radius.circular(30) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(30) : Radius.zero,
            bottomRight: !top && !left
                ? const Radius.circular(30)
                : Radius.zero,
          ),
        ),
      ),
    );
    return IgnorePointer(
      child: Stack(
        children: [
          corner(top: true, left: true),
          corner(top: true, left: false),
          corner(top: false, left: true),
          corner(top: false, left: false),
        ],
      ),
    );
  }
}

/// "Buscando código…" (punto verde), "Verificando…" o el problema en rojo.
class _ScanStatus extends StatelessWidget {
  const new({required this.busy, required this.problem});

  final bool busy;
  final String? problem;

  @override
  Widget build(BuildContext context) {
    final problem = this.problem;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          if (problem != null)
            const MusubiIcon(
              MusubiIcons.circleAlert,
              size: 16,
              strokeWidth: 2.4,
              color: _bad,
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.musubi.success,
                shape: BoxShape.circle,
              ),
            ),
          Flexible(
            child: Text(
              problem ?? (busy ? 'Verificando…' : 'Buscando código…'),
              textAlign: TextAlign.center,
              style: MusubiType.style(
                13,
                weight: problem == null ? FontWeight.w600 : FontWeight.w700,
                line: 18,
                color: problem == null ? _soft : _bad,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Código de Luis": la caja de 76 con los 6 digitos, el estado y
/// "Verificar".
class _CodeForm extends StatelessWidget {
  const new({
    required this.buyer,
    required this.controller,
    required this.busy,
    required this.ok,
    required this.problem,
    required this.onVerify,
  });

  final String buyer;
  final TextEditingController controller;
  final bool busy;
  final bool ok;
  final String? problem;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    final problem = this.problem;
    final border = ok
        ? context.musubi.success
        : (problem != null ? _bad : _white);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(
            'Código de $buyer',
            style: MusubiType.style(
              15,
              weight: FontWeight.w800,
              line: 20,
              color: _white,
            ),
          ),
          Container(
            height: 76,
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 2),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('verify-code'),
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              cursorColor: _ink,
              style: MusubiType.style(
                34,
                weight: FontWeight.w800,
                em: 0.3,
                color: _ink,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              decoration: InputDecoration.collapsed(
                hintText: '000000',
                hintStyle: MusubiType.style(
                  34,
                  weight: FontWeight.w800,
                  em: 0.3,
                  color: _offText,
                ),
              ).copyWith(counterText: ''),
              onSubmitted: (_) => onVerify?.call(),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 22),
            child: Semantics(
              liveRegion: true,
              child: Row(
                spacing: 6,
                children: [
                  if (ok) ...[
                    const MusubiIcon(
                      MusubiIcons.circleCheck,
                      size: 16,
                      strokeWidth: 2.8,
                      color: _good,
                    ),
                    _status('Código correcto', _good),
                  ] else if (problem != null) ...[
                    const MusubiIcon(
                      MusubiIcons.circleAlert,
                      size: 16,
                      strokeWidth: 2.4,
                      color: _bad,
                    ),
                    Expanded(child: _status(problem, _bad)),
                  ] else
                    Expanded(
                      child: Text(
                        'Son 6 números que $buyer ve en su app',
                        style: MusubiType.style(
                          13.5,
                          weight: FontWeight.w600,
                          line: 18,
                          color: _soft,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Pressable(
            key: const Key('verify-submit'),
            onTap: busy ? null : onVerify,
            semanticLabel: busy ? 'Verificando' : 'Verificar',
            builder: (context, pressed) {
              final c = context.musubi;
              final on = onVerify != null;
              return Container(
                height: MusubiSizes.buttonHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? (pressed ? c.brandPressed : c.brand) : _off,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: busy
                    ? const MusubiSpinner(color: _white)
                    : Text(
                        'Verificar',
                        style: MusubiType.style(
                          16,
                          weight: FontWeight.w700,
                          color: on ? c.onBrand : _offText,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _status(String text, Color color) => Text(
    text,
    style: MusubiType.style(
      13.5,
      weight: FontWeight.w700,
      line: 18,
      color: color,
    ),
  );
}

/// La tarjeta blanca de abajo: "APARTÓ", quien (con la insignia), "Juego de
/// escuadras · $180 · 3:00 p. m." y la foto.
class _BuyerCard extends StatelessWidget {
  const new({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final r = reservation;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottom > 30 ? bottom : 30),
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Row(
        spacing: 12,
        children: [
          _Initials(name: r.buyerName, size: 48, fontSize: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  'APARTÓ',
                  style: MusubiType.style(
                    11.5,
                    weight: FontWeight.w800,
                    line: 15,
                    em: 0.08,
                    color: _cardSoft,
                  ),
                ),
                Row(
                  spacing: 5,
                  children: [
                    Flexible(
                      child: Text(
                        r.buyerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          15,
                          weight: FontWeight.w800,
                          line: 20,
                          color: _cardText,
                        ),
                      ),
                    ),
                    const VerifiedBadge(size: 15),
                  ],
                ),
                Text(
                  '${r.title} · ${formatPrice(r.priceCents)} · '
                  '${clockTime(r.pickupAt.toLocal())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    13,
                    weight: FontWeight.w600,
                    line: 17,
                    color: _cardSoft,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox.square(
              dimension: 52,
              child: ColoredBox(
                color: c.surface,
                child: ProductPhoto(url: r.photoUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Iniciales en ambar (`#FDF4E1` / `#8F5B00`), como "LM" de la maqueta.
class _Initials extends StatelessWidget {
  const new({required this.name, required this.size, required this.fontSize});

  final String name;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.warningSoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initialsOf(name),
        style: MusubiType.style(
          fontSize,
          weight: FontWeight.w800,
          color: c.warningText,
        ),
      ),
    );
  }
}

/// `Apartado-verificado` (HU-52, quien vende): "Comprador verificado", quien
/// es (carrera y calificacion de su perfil), el producto y "Cobra en
/// efectivo". "Confirmar entrega" crea el pedido completado; "No es esta
/// persona" regresa a verificar.
class BuyerVerifiedScreen extends ConsumerStatefulWidget {
  const new({required this.reservationId, super.key});

  final String reservationId;

  @override
  ConsumerState<BuyerVerifiedScreen> createState() =>
      _BuyerVerifiedScreenState();
}

class _BuyerVerifiedScreenState extends ConsumerState<BuyerVerifiedScreen> {
  bool _sending = false;

  /// El apartado ya entregado ("¡Entregado!" y "Listo").
  Reservation? _delivered;

  Future<void> _deliver(Reservation r) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      final done = await ref.read(reservationRepositoryProvider).complete(r.id);
      if (!mounted) return;
      ref
        ..invalidate(myReservationsProvider)
        ..invalidate(salesProvider)
        ..invalidate(reservationProvider(r.id));
      setState(() {
        _sending = false;
        _delivered = done;
      });
      showMusubiSnack(
        messenger,
        'Entrega confirmada. ${_first(r.buyerName)} ya puede calificarte',
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _sending = false);
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  void _notThisPerson() => context.canPop()
      ? context.pop()
      : context.pushReplacement(AppRoutes.verifyBuyer(widget.reservationId));

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final reservation = ref.watch(reservationProvider(widget.reservationId));
    final value = _delivered ?? reservation.value;
    return Scaffold(
      backgroundColor: c.background,
      body: switch (reservation) {
        AsyncError(:final error) when value == null => SafeArea(
          child: ErrorView(
            message: error is ApiFailure
                ? error.message
                : 'No pudimos abrir el apartado.',
            onRetry: () =>
                ref.invalidate(reservationProvider(widget.reservationId)),
          ),
        ),
        _ when value == null => const LoadingView(),
        _ => _content(value),
      },
    );
  }

  Widget _content(Reservation r) {
    final c = context.musubi;
    final profile = ref.watch(publicProfileProvider(r.buyerId)).value;
    final delivered = r.status == ReservationStatus.collected;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final career = profile?.careerShortName;
    final rating = profile?.ratingAvg;
    final sub = [?career, profile?.campusShortName ?? 'UTTT'].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: MusubiSizes.minTouch,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Pressable(
                      key: const Key('verified-back'),
                      onTap: delivered
                          ? () => context.go(AppRoutes.myProducts)
                          : _notThisPerson,
                      semanticLabel: 'Regresar',
                      builder: (context, _) => SizedBox.square(
                        dimension: MusubiSizes.minTouch,
                        child: Center(
                          child: MusubiIcon(
                            MusubiIcons.chevronLeft,
                            strokeWidth: 1.9,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Entrega',
                    style: MusubiType.style(
                      17,
                      weight: FontWeight.w800,
                      line: 22,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Column(
                    children: [
                      const _VerifiedSeal(),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Comprador verificado',
                            textAlign: TextAlign.center,
                            style: MusubiType.style(
                              25,
                              weight: FontWeight.w800,
                              line: 31,
                              em: -0.025,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Es quien apartó tu producto.',
                          textAlign: TextAlign.center,
                          style: MusubiType.style(
                            14.5,
                            line: 21,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    children: [
                      _Row(
                        divider: true,
                        leading: _Initials(
                          name: r.buyerName,
                          size: 46,
                          fontSize: 15,
                        ),
                        title: Row(
                          spacing: 5,
                          children: [
                            Flexible(
                              child: Text(
                                r.buyerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MusubiType.style(
                                  15,
                                  weight: FontWeight.w800,
                                  line: 20,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            const VerifiedBadge(size: 15),
                          ],
                        ),
                        subtitle: sub,
                        trailing: rating == null
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 4,
                                children: [
                                  MusubiIcon(
                                    MusubiIcons.star,
                                    size: 14,
                                    color: c.warning,
                                  ),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: MusubiType.style(
                                      14,
                                      weight: FontWeight.w800,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      _Row(
                        divider: true,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox.square(
                            dimension: 46,
                            child: ProductPhoto(url: r.photoUrl),
                          ),
                        ),
                        title: Text(
                          r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MusubiType.style(
                            14.5,
                            weight: FontWeight.w700,
                            line: 19,
                            color: c.textPrimary,
                          ),
                        ),
                        subtitle: '1 pieza',
                        trailing: Text(
                          formatPrice(r.priceCents),
                          style:
                              MusubiType.style(
                                17,
                                weight: FontWeight.w800,
                                color: c.textPrimary,
                              ).copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                      ColoredBox(
                        color: c.surface,
                        child: _Row(
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: c.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: MusubiIcon(
                                MusubiIcons.banknote,
                                size: 22,
                                strokeWidth: 1.9,
                                color: c.successText,
                              ),
                            ),
                          ),
                          title: Text(
                            'Cobra en efectivo',
                            style: MusubiType.style(
                              14.5,
                              weight: FontWeight.w700,
                              line: 19,
                              color: c.textPrimary,
                            ),
                          ),
                          trailing: Text(
                            formatPrice(r.priceCents),
                            style:
                                MusubiType.style(
                                  20,
                                  weight: FontWeight.w800,
                                  color: c.successText,
                                ).copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.background,
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottom > 30 ? bottom : 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: delivered
                  ? [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: c.successSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          spacing: 10,
                          children: [
                            MusubiIcon(
                              MusubiIcons.circleCheck,
                              size: 20,
                              strokeWidth: 2.6,
                              color: c.successText,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 1,
                                children: [
                                  Text(
                                    '¡Entregado!',
                                    style: MusubiType.style(
                                      15,
                                      weight: FontWeight.w800,
                                      line: 20,
                                      color: c.successText,
                                    ),
                                  ),
                                  Text(
                                    'Quedó en tus ventas. '
                                    '${_first(r.buyerName)} ya puede '
                                    'calificarte.',
                                    style: MusubiType.style(
                                      12.5,
                                      weight: FontWeight.w600,
                                      line: 17,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Pressable(
                        key: const Key('verified-done'),
                        onTap: () => context.go(AppRoutes.myProducts),
                        semanticLabel: 'Listo',
                        builder: (context, pressed) => Container(
                          height: MusubiSizes.buttonHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: pressed ? c.textSecondary : c.textPrimary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Listo',
                            style: MusubiType.style(
                              16,
                              weight: FontWeight.w700,
                              color: c.background,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : [
                      MusubiButton(
                        key: const Key('verified-deliver'),
                        label: 'Confirmar entrega',
                        icon: MusubiIcons.package,
                        iconSize: 20,
                        loading: _sending,
                        loadingLabel: 'Confirmando…',
                        onPressed: r.active && r.verified
                            ? () => unawaited(_deliver(r))
                            : null,
                      ),
                      MusubiButton(
                        key: const Key('verified-not-them'),
                        label: 'No es esta persona',
                        kind: MusubiButtonKind.quiet,
                        height: MusubiSizes.minTouch,
                        fontSize: 14,
                        onPressed: _notThisPerson,
                      ),
                    ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Una fila de la tarjeta (`padding: 12px 14px`, separador `#F0F0F2`).
class _Row extends StatelessWidget {
  const new({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.divider = false,
  });

  final Widget leading;
  final Widget title;
  final String? subtitle;
  final Widget? trailing;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final subtitle = this.subtitle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: divider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: c.divider)),
            )
          : null,
      child: Row(
        spacing: 12,
        children: [
          leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 1,
              children: [
                title,
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      12.5,
                      weight: FontWeight.w600,
                      line: 17,
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// El sello verde de 92 con la onda que se abre (`__wave`, tres veces).
class _VerifiedSeal extends StatefulWidget {
  const new();

  @override
  State<_VerifiedSeal> createState() => _VerifiedSealState();
}

class _VerifiedSealState extends State<_VerifiedSeal>
    with SingleTickerProviderStateMixin {
  late final _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!still && !_wave.isAnimating && _wave.value == 0) {
      _wave.repeat(count: 3);
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return SizedBox.square(
      dimension: 92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _wave,
            builder: (context, child) => Opacity(
              opacity: _wave.isAnimating ? 0.7 * (1 - _wave.value) : 0,
              child: Transform.scale(
                scale: 1 + 0.5 * _wave.value,
                child: child,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: c.successSoft,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
            child: Center(
              child: MusubiIcon(
                MusubiIcons.check,
                size: 44,
                strokeWidth: 2.8,
                color: c.isDark ? c.background : c.onBrand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
