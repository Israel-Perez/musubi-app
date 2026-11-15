import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/presentation/saved_search_providers.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

/// `Busqueda-vacia` (HU-09 y HU-12): "No encontramos lo que buscas", "Publicar
/// lo que necesito" (HU-13, con el nombre ya escrito), "Avísame cuando
/// aparezca" (guarda la busqueda por 30 dias) y "Prueba con" (las palabras de
/// la busqueda, una por una).
class SearchNothingFound extends ConsumerStatefulWidget {
  const new({
    required this.query,
    required this.filter,
    required this.onTry,
    super.key,
  });

  final String query;
  final SearchFilter filter;
  final ValueChanged<String> onTry;

  /// "Prueba con": cada palabra de la busqueda (de 3 letras o mas), hasta 3.
  static List<String> suggestionsFor(String query) {
    final words = query
        .split(RegExp(r'\s+'))
        .where((word) => word.length >= 3)
        .toList();
    return words.length < 2 ? const [] : words.take(3).toList();
  }

  @override
  ConsumerState<SearchNothingFound> createState() => _SearchNothingFoundState();
}

class _SearchNothingFoundState extends ConsumerState<SearchNothingFound> {
  bool _alertOn = false;
  bool _saving = false;

  @override
  void didUpdateWidget(SearchNothingFound oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query || oldWidget.filter != widget.filter) {
      _alertOn = false;
    }
  }

  bool get _signedIn => ref.read(sessionControllerProvider) is SignedIn;

  void _publish() {
    if (!_signedIn) {
      unawaited(
        showAccountGate(
          context,
          motive: AccountGateMotive.request,
          returnTo: AppRoutes.search,
        ),
      );
      return;
    }
    final query = widget.query.trim();
    ref
        .read(needDraftProvider.notifier)
        .setTitle(
          query.isEmpty ? query : query[0].toUpperCase() + query.substring(1),
        );
    unawaited(context.push(AppRoutes.need));
  }

  Future<void> _alert() async {
    if (!_signedIn) {
      unawaited(
        showAccountGate(
          context,
          motive: AccountGateMotive.save,
          returnTo: AppRoutes.search,
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (_alertOn) {
      showMusubiSnack(
        messenger,
        'Ya tienes activa esta alerta',
        icon: MusubiIcons.bell,
        tone: SnackTone.info,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(savedSearchRepositoryProvider)
          .save(query: widget.query, filter: widget.filter);
      ref.invalidate(mySavedSearchesProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _alertOn = true;
      });
      showMusubiSnack(
        messenger,
        saved.created
            ? 'Listo. Te avisamos cuando alguien lo publique.'
            : 'Ya tienes activa esta alerta',
        icon: MusubiIcons.bell,
        tone: saved.created ? SnackTone.success : SnackTone.info,
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final session = ref.watch(sessionControllerProvider);
    final campus = session is SignedIn
        ? session.tokens.profile?.campus ?? 'UTTT'
        : 'UTTT';
    final query = widget.query.trim();
    final suggestions = SearchNothingFound.suggestionsFor(query);
    return ListView(
      key: const Key('search-nothing-found'),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 44, 28, 0),
          child: Column(
            children: [
              SizedBox(
                width: 180,
                height: 150,
                child: Stack(
                  // La etiqueta sale 4 a la derecha y su sombra no se recorta.
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 30,
                      top: 6,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: c.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: MusubiIcon(
                            MusubiIcons.searchX,
                            size: 54,
                            strokeWidth: 1.5,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: c.brandSoft,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x29D7191F),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          spacing: 5,
                          children: [
                            MusubiIcon(
                              MusubiIcons.megaphone,
                              size: 13,
                              strokeWidth: 2.4,
                              color: c.brandStrongText,
                            ),
                            Text(
                              'SE BUSCA',
                              style: MusubiType.style(
                                11,
                                weight: FontWeight.w800,
                                em: 0.06,
                                color: c.brandStrongText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No encontramos lo que buscas',
                textAlign: TextAlign.center,
                style: MusubiType.style(
                  24,
                  weight: FontWeight.w800,
                  line: 30,
                  em: -0.025,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Nadie en la $campus ha publicado «$query». Pídelo y te '
                'avisamos.',
                textAlign: TextAlign.center,
                style: MusubiType.style(15, line: 22, color: c.textSecondary),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: Column(
            spacing: 10,
            children: [
              MusubiButton(
                key: const Key('search-need'),
                label: 'Publicar lo que necesito',
                icon: MusubiIcons.megaphone,
                onPressed: _publish,
              ),
              _AlertButton(on: _alertOn, saving: _saving, onTap: _alert),
            ],
          ),
        ),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  'Prueba con',
                  style: MusubiType.style(
                    13,
                    weight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final word in suggestions)
                      Pressable(
                        key: Key('search-try-$word'),
                        onTap: () => widget.onTry(word),
                        semanticLabel: 'Buscar $word',
                        builder: (context, pressed) => SizedBox(
                          height: 44,
                          child: Align(
                            widthFactor: 1,
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: pressed ? c.border : c.surface,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 6,
                                children: [
                                  MusubiIcon(
                                    MusubiIcons.search,
                                    size: 14,
                                    color: c.textPrimary,
                                  ),
                                  Text(
                                    word,
                                    style: MusubiType.style(
                                      14,
                                      weight: FontWeight.w600,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Avísame cuando aparezca"; ya guardada, "Te avisaremos cuando aparezca" en
/// verde con palomita (como la maqueta).
class _AlertButton extends StatelessWidget {
  const new({required this.on, required this.saving, required this.onTap});

  final bool on;
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final ink = on ? c.successText : c.textPrimary;
    final label = on
        ? 'Te avisaremos cuando aparezca'
        : 'Avísame cuando aparezca';
    return Pressable(
      key: const Key('search-alert'),
      onTap: saving ? null : onTap,
      semanticLabel: label,
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: on
              ? c.successSoft
              : pressed
              ? c.surface
              : c.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? c.successBand : c.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            MusubiIcon(
              on ? MusubiIcons.check : MusubiIcons.bell,
              size: 20,
              strokeWidth: 1.9,
              color: ink,
            ),
            Text(
              label,
              style: MusubiType.style(16, weight: FontWeight.w700, color: ink),
            ),
          ],
        ),
      ),
    );
  }
}
