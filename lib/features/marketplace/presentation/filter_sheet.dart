import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_controls.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

/// Abre "Filtrar" (maqueta `Inicio-visitante`, HU-10): elige una categoria
/// y "Ocultar agotados"; se aplica al tocar "Ver N productos".
Future<void> showFilterSheet(
  BuildContext context,
  List<CatalogCategory> categories,
) => showMusubiSheet<void>(
  context,
  style: MusubiSheetStyle.screen,
  builder: (_) => FilterSheet(categories: categories),
);

class FilterSheet extends ConsumerStatefulWidget {
  const new({required this.categories, super.key});

  final List<CatalogCategory> categories;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late CatalogFilter _draft = ref.read(catalogFilterProvider);

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final preview = ref.watch(filterPreviewProvider(_draft)).value;
    final cta = switch (preview) {
      null => 'Ver productos',
      1 => 'Ver 1 producto',
      final n => 'Ver $n productos',
    };

    return Column(
      key: const Key('filter-sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Filtrar',
                  style: MusubiType.style(
                    22,
                    weight: FontWeight.w800,
                    line: 28,
                    em: -0.02,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            Pressable(
              onTap: () => setState(() => _draft = const CatalogFilter()),
              semanticLabel: 'Limpiar',
              builder: (context, _) => Container(
                height: MusubiSizes.minTouch,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                child: Text(
                  'Limpiar',
                  style: MusubiType.style(
                    14.5,
                    weight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 104,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _CategoryTile(
              name: 'Todo',
              photoUrl: null,
              selected: _draft.category == null,
              onTap: () => setState(
                () => _draft = CatalogFilter(hideSoldOut: _draft.hideSoldOut),
              ),
            ),
            for (final category in widget.categories)
              _CategoryTile(
                name: category.name,
                photoUrl: category.photoUrl,
                selected: _draft.category == category.slug,
                onTap: () => setState(
                  () => _draft = CatalogFilter(
                    category: category.slug,
                    hideSoldOut: _draft.hideSoldOut,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.only(left: 14, right: 4),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ocultar agotados',
                  style: MusubiType.style(
                    15,
                    weight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              MusubiSwitch(
                value: _draft.hideSoldOut,
                semanticLabel: 'Ocultar agotados',
                width: 50,
                height: 30,
                knob: 24,
                onChanged: (value) => setState(
                  () => _draft = CatalogFilter(
                    category: _draft.category,
                    hideSoldOut: value,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MusubiSizes.space4),
        MusubiButton(
          label: cta,
          onPressed: () {
            ref.read(catalogFilterProvider.notifier).apply(_draft);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

/// Tarjeta de una categoria: foto, nombre en pastilla y palomita si esta
/// elegida (borde rojo de 2.5). "Todo" lleva la cuadricula en un circulo rojo.
class _CategoryTile extends StatelessWidget {
  const new({
    required this.name,
    required this.photoUrl,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String? photoUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: name,
      selected: selected,
      pressScale: 0.97,
      builder: (context, _) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.brandSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.brand : c.background,
            width: 2.5,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null)
              ProductPhoto(url: photoUrl)
            else
              // `top: 40%` del area interior (sin el borde de 2.5), centrado.
              Positioned(
                top: 2.5 + 99 * 0.4 - 22,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.brand,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: MusubiIcon(
                        MusubiIcons.layoutGrid,
                        size: 22,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 8.5,
              bottom: 8.5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                ),
                child: Text(
                  name,
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w800,
                    line: 16,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 8.5,
                right: 8.5,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: MusubiIcon(
                      MusubiIcons.check,
                      size: 14,
                      strokeWidth: 3,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
