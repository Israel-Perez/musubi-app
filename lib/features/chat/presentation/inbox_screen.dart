import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';

/// `Mensajes` (HU-22): mis conversaciones por actividad reciente, con Todos,
/// Compras y Ventas y los no leidos. Se actualiza sola al llegar un mensaje.
///
/// NOTE (HU-16): filas de solicitudes y ofertas ("Tu solicitud", "Tu oferta").
class InboxScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  InboxFilter _filter = InboxFilter.all;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    ref.watch(chatConnectionProvider);
    final inbox = ref.watch(inboxProvider(_filter));
    final now = ref.watch(clockProvider)().toLocal();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.brand,
          onRefresh: () => ref.refresh(inboxProvider(_filter).future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Mensajes',
                          style: MusubiType.style(
                            28,
                            weight: FontWeight.w800,
                            line: 34,
                            em: -0.03,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Pressable(
                        onTap: () => showMusubiSnack(
                          ScaffoldMessenger.of(context),
                          'Buscar en mensajes llega muy pronto.',
                          icon: MusubiIcons.clock,
                          tone: SnackTone.info,
                        ),
                        semanticLabel: 'Buscar en mensajes',
                        builder: (context, _) => SizedBox.square(
                          dimension: MusubiSizes.minTouch,
                          child: Center(
                            child: MusubiIcon(
                              MusubiIcons.search,
                              strokeWidth: 1.9,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _Segments(
                    selected: _filter,
                    onSelect: (filter) => setState(() => _filter = filter),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ...switch (inbox) {
                AsyncData(:final value) when value.items.isEmpty => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(filter: _filter),
                  ),
                ],
                AsyncData(:final value) => [
                  SliverList.separated(
                    itemCount: value.items.length,
                    separatorBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.only(left: 80),
                      child: Divider(height: 1, thickness: 1, color: c.divider),
                    ),
                    itemBuilder: (context, index) {
                      final entry = value.items[index];
                      return _Row(
                        entry: entry,
                        now: now,
                        onTap: () => unawaited(
                          context.push(AppRoutes.conversation(entry.id)),
                        ),
                      );
                    },
                  ),
                ],
                AsyncError(:final error) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: InlineMessage(
                          message: error is ApiFailure
                              ? error.message
                              : 'No pudimos cargar tus mensajes. '
                                    'Desliza hacia abajo para reintentar.',
                        ),
                      ),
                    ),
                  ),
                ],
                _ => [const SliverToBoxAdapter(child: _RowsSkeleton())],
              },
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Todos / Compras / Ventas (control segmentado de la maqueta).
class _Segments extends StatelessWidget {
  const new({required this.selected, required this.onSelect});

  final InboxFilter selected;
  final ValueChanged<InboxFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      height: MusubiSizes.minTouch,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
      ),
      child: Row(
        spacing: 3,
        children: [
          for (final filter in InboxFilter.values)
            Expanded(
              child: Pressable(
                onTap: () => onSelect(filter),
                selected: filter == selected,
                semanticLabel: filter.label,
                builder: (context, _) {
                  final on = filter == selected;
                  return Container(
                    decoration: on
                        ? BoxDecoration(
                            color: c.elevated,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F1C1C1E),
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          )
                        : null,
                    alignment: Alignment.center,
                    child: Text(
                      filter.label,
                      style: MusubiType.style(
                        13.5,
                        weight: on ? FontWeight.w800 : FontWeight.w600,
                        color: on ? c.textPrimary : c.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Una conversacion: avatar, nombre, hora, ultimo mensaje con sus no leidos,
/// "Compra · …" / "Venta · …" y la foto de la publicacion.
class _Row extends StatelessWidget {
  const new({required this.entry, required this.now, required this.onTap});

  final InboxEntry entry;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final unread = entry.unread > 0;
    return Pressable(
      onTap: onTap,
      semanticLabel:
          '${entry.counterpart.name}. ${entry.lastText}. ${entry.contextLine}'
          '${unread ? '. ${entry.unread} sin leer' : ''}',
      builder: (context, pressed) => ColoredBox(
        color: pressed ? c.surface : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              InitialsAvatar(
                initials: entry.counterpart.initials,
                size: 48,
                fontSize: 16,
                palette: entry.counterpart.palette,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Row(
                            spacing: 4,
                            children: [
                              Flexible(
                                child: Text(
                                  entry.counterpart.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: MusubiType.style(
                                    15,
                                    weight: unread
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              // Como la maqueta: insignia si hay sin leer.
                              if (unread) const VerifiedBadge(size: 15),
                            ],
                          ),
                        ),
                        Text(
                          inboxStamp(entry.lastAt.toLocal(), now),
                          style: MusubiType.style(
                            12,
                            weight: unread ? FontWeight.w700 : FontWeight.w600,
                            color: unread ? c.brandText : c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Text(
                            entry.lastText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MusubiType.style(
                              13.5,
                              weight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: unread ? c.textPrimary : c.textSecondary,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: c.brand,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              entry.unread > 99 ? '99+' : '${entry.unread}',
                              style: MusubiType.style(
                                11,
                                weight: FontWeight.w800,
                                color: c.onBrand,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        MusubiIcon(
                          entry.role == ChatRole.buyer
                              ? MusubiIcons.shoppingBag
                              : MusubiIcons.tag,
                          size: 13,
                          strokeWidth: 2.2,
                          color: unread ? c.brandStrongText : c.textSecondary,
                        ),
                        Expanded(
                          child: Text(
                            entry.contextLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MusubiType.style(
                              12,
                              weight: FontWeight.w700,
                              color: unread
                                  ? c.brandStrongText
                                  : c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox.square(
                  dimension: 44,
                  child: ProductPhoto(url: entry.contextPhotoUrl),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const new({required this.filter});

  final InboxFilter filter;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final (title, message) = switch (filter) {
      InboxFilter.all => (
        'Aún no tienes conversaciones',
        'Toca un producto en Inicio para escribirle a quien lo vende.',
      ),
      InboxFilter.purchases => (
        'Aún no le escribes a nadie',
        'Cuando preguntes por un producto, la conversación aparece aquí.',
      ),
      InboxFilter.sales => (
        'Aún no te escriben',
        'Cuando alguien pregunte por tus publicaciones, lo verás aquí.',
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          MusubiIcon(
            MusubiIcons.messageCircle,
            size: 40,
            strokeWidth: 1.8,
            color: c.textSecondary,
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: MusubiType.style(
              17,
              weight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: MusubiType.style(14, line: 20, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RowsSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => SkeletonShimmer(
    child: Column(
      children: [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              spacing: 12,
              children: [
                SkeletonBox(width: 48, height: 48, radius: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      SkeletonBox(width: 140, height: 14),
                      SkeletonBox(height: 12),
                      SkeletonBox(width: 120, height: 11),
                    ],
                  ),
                ),
                SkeletonBox(width: 44, height: 44, radius: 10),
              ],
            ),
          ),
      ],
    ),
  );
}
