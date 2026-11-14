import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/features/auth/presentation/auth_layout.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/presentation/interests_providers.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_widgets.dart';

/// "¿Qué te interesa?" (HU-66). La maqueta no la tiene: se arma con las piezas
/// de `Verificacion-lista` (esqueleto de cuenta) y los chips de `Necesidad-1`.
///
/// Con [onboarding] sale una vez, después de verificar el correo, y se puede
/// saltar; desde `Ajustes` cambia los intereses guardados.
class InterestsScreen extends ConsumerStatefulWidget {
  const new({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  /// `null` hasta saber lo guardado (en `Ajustes`); al entrar no hay nada.
  List<String>? _selected;
  bool _saving = false;

  bool get _onboarding => widget.onboarding;

  @override
  void initState() {
    super.initState();
    if (_onboarding) _selected = [];
  }

  void _toggle(String slug) => setState(() {
    final selected = [...?_selected];
    selected.contains(slug) ? selected.remove(slug) : selected.add(slug);
    _selected = selected;
  });

  /// Sigue a donde iba antes de crear la cuenta (HU-48), como "Empezar a
  /// explorar" de `Verificacion-lista`.
  void _continue() => context.go(ref.read(returnPathProvider.notifier).take());

  /// De vuelta a `Ajustes`, también si se abrió con un enlace directo.
  void _leave() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.settings);

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null || _saving) return;
    if (_onboarding && selected.isEmpty) return _continue();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(interestsRepositoryProvider).save(selected);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _saving = false);
      showMusubiSnack(messenger, failure.message, tone: SnackTone.warn);
      return;
    }
    ref.invalidate(myInterestsProvider);
    if (!mounted) return;
    if (_onboarding) {
      _continue();
      return;
    }
    showMusubiSnack(messenger, 'Guardamos tus intereses');
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final categories = ref.watch(categoriesProvider);
    if (!_onboarding && _selected == null) {
      final saved = ref.watch(myInterestsProvider);
      if (saved case AsyncData(:final value)) {
        // Se toma una vez: después manda lo que la persona toca.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selected == null) setState(() => _selected = value);
        });
      } else if (saved case AsyncError(:final error)) {
        return _Failure(
          onBack: _leave,
          message: _messageOf(error),
          onRetry: () => ref.invalidate(myInterestsProvider),
        );
      }
    }
    final selected = _selected;

    return AuthLayout(
      onBack: _onboarding ? null : _leave,
      actions: [
        MusubiButton(
          key: const Key('interests-save'),
          label: _onboarding ? 'Continuar' : 'Guardar',
          loading: _saving,
          loadingLabel: 'Guardando…',
          dimmed: selected == null || (_onboarding && selected.isEmpty),
          onPressed: _save,
        ),
        if (_onboarding)
          MusubiButton(
            key: const Key('interests-skip'),
            label: 'Ahora no',
            kind: MusubiButtonKind.quiet,
            onPressed: _saving ? null : _continue,
          ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MusubiSizes.gutter,
            8,
            MusubiSizes.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: MusubiSizes.space2,
            children: [
              Semantics(
                header: true,
                child: Text(
                  _onboarding ? '¿Qué te interesa?' : 'Mis intereses',
                  style: MusubiType.style(
                    26,
                    weight: FontWeight.w800,
                    line: 32,
                    em: -0.025,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Text(
                _onboarding
                    ? 'Elige las categorías que quieres ver primero. Puedes '
                          'cambiarlas cuando quieras en Ajustes.'
                    : 'Te mostraremos primero lo de estas categorías.',
                style: MusubiType.body.copyWith(color: c.textSecondary),
              ),
              Text(
                'Solo tú las ves: no salen en tu perfil.',
                style: MusubiType.style(
                  13,
                  weight: FontWeight.w600,
                  color: c.textTertiary,
                ),
              ),
              const SizedBox(height: MusubiSizes.space2),
              switch (categories) {
                AsyncData(:final value) when selected != null => _Chips(
                  categories: value,
                  selected: selected,
                  onToggle: _toggle,
                ),
                AsyncError(:final error) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: MusubiSizes.space2,
                  children: [
                    InlineMessage(message: _messageOf(error)),
                    MusubiButton(
                      key: const Key('interests-retry'),
                      label: 'Reintentar',
                      kind: MusubiButtonKind.link,
                      onPressed: () => ref.invalidate(categoriesProvider),
                    ),
                  ],
                ),
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: MusubiSizes.space4),
                  child: Center(child: MusubiSpinner()),
                ),
              },
            ],
          ),
        ),
      ],
    );
  }

  static String _messageOf(Object error) => error is ApiFailure
      ? error.message
      : 'No pudimos cargar las categorías. Intenta de nuevo.';
}

class _Chips extends StatelessWidget {
  const new({
    required this.categories,
    required this.selected,
    required this.onToggle,
  });

  final List<CatalogCategory> categories;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: MusubiSizes.space2,
    children: [
      for (final category in categories)
        NeedChip(
          key: Key('interest-${category.slug}'),
          label: category.name,
          selected: selected.contains(category.slug),
          onTap: () => onToggle(category.slug),
        ),
    ],
  );
}

/// Sin poder leer lo guardado no se edita: se ofrece reintentar.
class _Failure extends StatelessWidget {
  const new({
    required this.onBack,
    required this.message,
    required this.onRetry,
  });

  final VoidCallback onBack;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AuthLayout(
    onBack: onBack,
    actions: const [],
    children: [
      Padding(
        padding: const EdgeInsets.all(MusubiSizes.gutter),
        child: ErrorView(message: message, onRetry: onRetry),
      ),
    ],
  );
}
