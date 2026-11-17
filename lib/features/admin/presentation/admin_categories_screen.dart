import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_dialog.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/presentation/admin_providers.dart';
import 'package:musubi_app/features/admin/presentation/admin_widgets.dart';

/// "Categorías" en "Administración" (HU-41, sin pantalla en la maqueta):
/// agregar, renombrar, desactivar y volver a activar las del campus.
class AdminCategoriesScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, [
    AdminCategory? category,
  ]) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = await showMusubiPanel<String>(
      context,
      builder: (_) => CategorySheet(category: category),
    );
    if (done == null) return;
    refreshCategories(ref);
    showMusubiSnack(messenger, done, icon: MusubiIcons.circleCheck);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final categories = ref.watch(adminCategoriesProvider);
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MusubiTopBar(
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.settings),
            title: 'Categorías',
          ),
          Expanded(
            child: switch (categories) {
              AsyncData(:final value) => ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                children: [
                  const PanelNote(
                    'Las activas salen al publicar y en los filtros. Una '
                    'desactivada ya no se puede elegir, pero sus '
                    'publicaciones siguen visibles.',
                  ),
                  const SizedBox(height: 14),
                  MusubiButton(
                    key: const Key('admin-category-add'),
                    label: 'Agregar categoría',
                    icon: MusubiIcons.plus,
                    kind: MusubiButtonKind.secondary,
                    onPressed: () => unawaited(_open(context, ref)),
                  ),
                  const SizedBox(height: 18),
                  for (final category in value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CategoryCard(
                        category: category,
                        onTap: () => unawaited(_open(context, ref, category)),
                      ),
                    ),
                ],
              ),
              AsyncError(:final error) => ErrorView(
                message: error is ApiFailure
                    ? error.message
                    : 'No pudimos cargar las categorías. Intenta de nuevo.',
                onRetry: () => ref.invalidate(adminCategoriesProvider),
              ),
              _ => const LoadingView(message: 'Cargando las categorías…'),
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const new({required this.category, required this.onTap});

  final AdminCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return AdminCard(
      key: Key('admin-category-${category.slug}'),
      semanticLabel:
          '${category.name}, '
          '${category.active ? 'activa' : 'desactivada'}. Editar',
      onTap: onTap,
      child: Row(
        spacing: 10,
        children: [
          MusubiIcon(MusubiIcons.tag, size: 18, color: c.textSecondary),
          Expanded(
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.style(
                15,
                weight: FontWeight.w700,
                line: 20,
                color: category.active ? c.textPrimary : c.textSecondary,
              ),
            ),
          ),
          StatusPill(
            category.active ? 'Activa' : 'Desactivada',
            tone: category.active ? PillTone.success : PillTone.neutral,
          ),
          MusubiIcon(MusubiIcons.chevronRight, size: 18, color: c.textTertiary),
        ],
      ),
    );
  }
}

/// "Agregar categoría" (sin [category]) o "Editar categoría": el nombre y
/// "Desactivar" o "Activar". Al cerrar devuelve el aviso para el snack, o
/// `null` si no cambio nada.
class CategorySheet extends ConsumerStatefulWidget {
  const new({super.key, this.category});

  final AdminCategory? category;

  @override
  ConsumerState<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<CategorySheet> {
  late final _name = TextEditingController(text: widget.category?.name);
  String? _error;
  int _shake = 0;
  bool _saving = false;
  bool _toggling = false;

  bool get _busy => _saving || _toggling;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _fail(String message) => setState(() {
    _saving = false;
    _toggling = false;
    _error = message;
    _shake++;
  });

  Future<void> _save() async {
    final name = _name.text.trim();
    final category = widget.category;
    if (name.length < adminCategoryNameMin) {
      _fail('Escribe un nombre de 2 a 40 caracteres.');
      return;
    }
    if (category != null && name == category.name) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = ref.read(adminRepositoryProvider);
    try {
      if (category == null) {
        await repository.createCategory(name);
      } else {
        await repository.updateCategory(category.slug, name: name);
      }
    } on ApiFailure catch (failure) {
      if (mounted) _fail(failure.message);
      return;
    }
    if (mounted) {
      Navigator.of(context).pop(
        category == null ? 'Agregamos la categoría' : 'Guardamos el nombre',
      );
    }
  }

  Future<void> _toggle(AdminCategory category) async {
    if (category.active) {
      final yes = await showMusubiDialog(
        context,
        icon: MusubiIcons.eyeOff,
        title: '¿Desactivar ${category.name}?',
        message:
            'Ya no se podrá elegir al publicar ni en los filtros. Las '
            'publicaciones que ya la usan siguen visibles.',
        confirmLabel: 'Desactivar',
        danger: true,
        confirmKey: const Key('admin-category-deactivate-confirm'),
      );
      if (!yes || !mounted) return;
    }
    setState(() {
      _toggling = true;
      _error = null;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateCategory(category.slug, active: !category.active);
    } on ApiFailure catch (failure) {
      if (mounted) _fail(failure.message);
      return;
    }
    if (mounted) {
      Navigator.of(context).pop(
        category.active
            ? 'Desactivamos la categoría'
            : 'Activamos la categoría',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    return MusubiPanel(
      key: const Key('admin-category-sheet'),
      title: category == null ? 'Agregar categoría' : 'Editar categoría',
      actions: [
        MusubiButton(
          key: const Key('admin-category-save'),
          label: category == null ? 'Agregar categoría' : 'Guardar nombre',
          loadingLabel: 'Guardando…',
          loading: _saving,
          height: MusubiSizes.buttonHeightSheet,
          onPressed: _busy ? null : _save,
        ),
        if (category != null)
          MusubiButton(
            key: const Key('admin-category-toggle'),
            label: category.active
                ? 'Desactivar categoría'
                : 'Activar categoría',
            loadingLabel: category.active ? 'Desactivando…' : 'Activando…',
            kind: MusubiButtonKind.secondary,
            loading: _toggling,
            height: 46,
            onPressed: _busy ? null : () => unawaited(_toggle(category)),
          ),
        MusubiButton(
          label: 'Cancelar',
          kind: MusubiButtonKind.quiet,
          height: 46,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const SizedBox(height: 4),
          MusubiTextField(
            label: 'Nombre',
            hint: 'Por ejemplo: Ropa y batas',
            fieldKey: const Key('admin-category-name'),
            controller: _name,
            enabled: !_busy,
            sheet: true,
            errorText: _error,
            shakeTrigger: _shake,
            inputFormatters: [
              LengthLimitingTextInputFormatter(adminCategoryNameMax),
            ],
          ),
          PanelNote(
            category == null
                ? 'Sale al final de la lista, ya activa.'
                : 'Las publicaciones y solicitudes que ya la usan conservan '
                      'la categoría.',
          ),
        ],
      ),
    );
  }
}
