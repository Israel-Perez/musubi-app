import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';

/// Guarda o quita un producto y muestra el aviso de la maqueta ("Ver" o
/// "Deshacer"). El estado solo cambia cuando la API confirma.
Future<void> toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  ProductSummary product,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final saved = await ref.read(favoritesProvider.notifier).toggle(product);
    if (saved == null || !context.mounted) return;
    showMusubiSnack(
      messenger,
      saved ? 'Guardaste «${product.title}»' : 'Lo quitaste de Favoritos',
      icon: MusubiIcons.heart,
      tone: saved ? SnackTone.success : SnackTone.info,
      actionLabel: saved ? 'Ver' : 'Deshacer',
      onAction: () {
        if (!context.mounted) return;
        if (saved) {
          unawaited(context.push(AppRoutes.favorites));
        } else {
          unawaited(toggleFavorite(context, ref, product));
        }
      },
    );
  } on ApiFailure catch (failure) {
    if (!context.mounted) return;
    showMusubiSnack(
      messenger,
      failure.message,
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
    );
  } on Object {
    if (!context.mounted) return;
    showMusubiSnack(
      messenger,
      'No pudimos actualizar tus favoritos.',
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
    );
  }
}
