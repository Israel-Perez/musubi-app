import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_layout.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

// "Editar solicitud" (HU-14): `Necesidad-1…3` con los datos de la solicitud.
// "Guardar" (arriba) y "Guardar cambios" (en `Necesidad-3`) mandan lo mismo.

/// Encabezado de los pasos al editar.
const needEditHeading = 'Editar solicitud';

/// Vuelve a `Mis-solicitudes` (la primera pagina del navegador raiz: el
/// flujo se abre encima de la barra de pestanas).
void leaveNeedEdit(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);

/// "Guardar cambios": manda la solicitud editada y, si sale bien, vuelve a
/// `Mis-solicitudes` con un aviso. Devuelve `false` si algo fallo (el aviso
/// ya se mostro).
Future<bool> saveNeedEdit(BuildContext context, WidgetRef ref) async {
  final draft = ref.read(needEditDraftProvider);
  final id = draft.editingId;
  final messenger = ScaffoldMessenger.of(context);
  if (id == null ||
      !draft.titleValid ||
      draft.category == null ||
      draft.budgetCents == null) {
    showMusubiSnack(
      messenger,
      'Revisa el producto, la categoría y el presupuesto.',
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
      bottomOffset: sellActionsHeight,
    );
    return false;
  }
  // El borrador y la lista se tocan con el contenedor: al volver, esta
  // pantalla ya no existe.
  final container = ProviderScope.containerOf(context, listen: false);
  final today = ref.read(clockProvider)().toLocal();
  try {
    await ref.read(wantedRepositoryProvider).update(id, draft.toRequest(today));
  } on ApiFailure catch (failure) {
    showMusubiSnack(
      messenger,
      failure.message,
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
      bottomOffset: sellActionsHeight,
    );
    return false;
  }
  container.invalidate(myWantedProvider);
  if (context.mounted) leaveNeedEdit(context);
  container.read(needEditDraftProvider.notifier).reset();
  showMusubiSnack(messenger, 'Guardamos los cambios de tu solicitud.');
  return true;
}
