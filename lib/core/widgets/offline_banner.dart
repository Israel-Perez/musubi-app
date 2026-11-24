import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/network/offline_cache.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';

/// "Sin conexión · lo que ves puede no estar al día" (HU-63): sale arriba de la
/// barra de pestanas mientras la ultima peticion no llego a la API. Las
/// acciones que necesitan la API avisan con su mensaje al tocarlas.
class OfflineBanner extends ConsumerWidget {
  const new({super.key});

  /// El texto del criterio de HU-63.
  static const text = 'Sin conexión · lo que ves puede no estar al día';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final offline = ref.watch(offlineProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: !offline
          ? const SizedBox.shrink()
          : Semantics(
              liveRegion: true,
              child: Container(
                key: const Key('offline-banner'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: c.textPrimary,
                child: Row(
                  spacing: 8,
                  children: [
                    MusubiIcon(
                      MusubiIcons.wifiOff,
                      size: 16,
                      color: c.background,
                    ),
                    Expanded(
                      child: Text(
                        text,
                        style: MusubiType.style(
                          13,
                          line: 18,
                          weight: FontWeight.w700,
                          color: c.background,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
