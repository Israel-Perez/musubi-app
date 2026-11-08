import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';

/// "Usuarios bloqueados" (maqueta `aj-bloqueados`, HU-57): cada persona con
/// su avatar, su nombre y "Desbloquear". Se abre desde Privacidad.
Future<void> showBlockedUsersSheet(BuildContext context) =>
    showMusubiPanel<void>(context, builder: (_) => const BlockedUsersSheet());

class BlockedUsersSheet extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<BlockedUsersSheet> createState() => _BlockedUsersSheetState();
}

class _BlockedUsersSheetState extends ConsumerState<BlockedUsersSheet> {
  /// Los que se desbloquearon con la hoja abierta (se quitan al instante).
  final _unblocked = <String>{};
  String? _busy;

  Future<void> _unblock(BlockedUser person) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = person.id);
    try {
      await ref.read(reputationRepositoryProvider).unblock(person.id);
      if (!mounted) return;
      setState(() {
        _busy = null;
        _unblocked.add(person.id);
      });
      // Privacidad muestra cuantos quedan.
      ref.invalidate(blockedUsersProvider);
      showMusubiSnack(messenger, 'Desbloqueaste a ${person.firstName}');
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _busy = null);
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
    final blocked = ref.watch(blockedUsersProvider);
    final people = blocked.value
        ?.where((p) => !_unblocked.contains(p.id))
        .toList();
    return MusubiPanel(
      key: const Key('blocked-users'),
      title: 'Usuarios bloqueados',
      child: switch (blocked) {
        AsyncError(:final error) when people == null => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: InlineMessage(
            message: error is ApiFailure
                ? error.message
                : 'No pudimos cargar la lista. Inténtalo de nuevo.',
          ),
        ),
        _ when people == null => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: MusubiSpinner()),
        ),
        // `.s-empty`.
        _ when people.isEmpty => Padding(
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 6),
          child: Text(
            'No has bloqueado a nadie. Si alguien te molesta, bloquéalo desde '
            'el chat.',
            textAlign: TextAlign.center,
            style: MusubiType.style(
              14.5,
              weight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ),
        _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final person in people)
              _PersonRow(
                person: person,
                busy: _busy == person.id,
                onUnblock: _busy == null
                    ? () => unawaited(_unblock(person))
                    : null,
              ),
          ],
        ),
      },
    );
  }
}

/// `.s-person`: avatar de 40, nombre y "Desbloquear" (36 de alto, borde de
/// 1.5 y radio 12).
class _PersonRow extends StatelessWidget {
  const new({
    required this.person,
    required this.busy,
    required this.onUnblock,
  });

  final BlockedUser person;
  final bool busy;
  final VoidCallback? onUnblock;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        spacing: 12,
        children: [
          ProfileAvatar(
            initials: person.initials,
            photoUrl: person.photoUrl,
            size: 40,
            fontSize: 14,
            palette: person.palette,
          ),
          Expanded(
            child: Text(
              person.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.style(
                15,
                weight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
          Pressable(
            key: ValueKey('unblock-${person.id}'),
            onTap: onUnblock,
            semanticLabel: 'Desbloquear a ${person.name}',
            builder: (context, pressed) => SizedBox(
              height: MusubiSizes.minTouch,
              child: Center(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: pressed ? c.surface : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: busy
                      ? MusubiSpinner(size: 16, color: c.textPrimary)
                      : Text(
                          'Desbloquear',
                          style: MusubiType.style(
                            13.5,
                            weight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
