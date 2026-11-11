import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';
import 'package:musubi_app/features/listings/presentation/sell_layout.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

// "Editar publicacion" (HU-07): `Vender-2…4` con los datos de la publicacion,
// sin `Vender-1` (las fotos no se editan). "Guardar" (arriba) y "Guardar
// cambios" (en `Vender-4`) mandan lo mismo.

/// Encabezado de los pasos al editar (maqueta: "Editar publicación").
const sellEditHeading = 'Editar publicación';

/// Vuelve a `Mis-productos`, debajo de los pasos de editar.
void leaveSellEdit(BuildContext context) => Navigator.of(context).popUntil(
  (route) => route.settings.name == AppRoutes.myProducts || route.isFirst,
);

/// "Guardar cambios": manda la publicacion editada y, si sale bien, vuelve a
/// `Mis-productos` con el aviso de la maqueta. Devuelve `false` si algo fallo
/// (el aviso ya se mostro).
Future<bool> saveSellEdit(BuildContext context, WidgetRef ref) async {
  final draft = ref.read(sellEditDraftProvider);
  final messenger = ScaffoldMessenger.of(context);
  if (!draft.titleValid || draft.priceCents <= 0 || draft.category == null) {
    showMusubiSnack(
      messenger,
      'Revisa el nombre, el precio y la categoría.',
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
      bottomOffset: sellActionsHeight,
    );
    return false;
  }
  // El borrador y las listas se tocan con el contenedor: al volver, esta
  // pantalla ya no existe.
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await ref.read(sellEditDraftProvider.notifier).saveEdit();
  } on ApiFailure catch (failure) {
    showMusubiSnack(
      messenger,
      failure.message,
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
      bottomOffset: sellActionsHeight,
    );
    // Ya no existe (la eliminaron en otro telefono): la lista se refresca.
    if (failure.code == 'listings.product_not_found') {
      container.invalidate(myListingsProvider);
    }
    return false;
  }
  container
    ..invalidate(myListingsProvider)
    ..invalidate(homeFeedProvider);
  if (context.mounted) leaveSellEdit(context);
  showMusubiSnack(messenger, 'Guardamos los cambios de tu publicación');
  return true;
}
