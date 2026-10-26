import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';

/// Por que se pide la cuenta (maqueta, `GATE` del modo visitante, HU-48):
/// icono, titulo y texto de la hoja "Crea tu cuenta".
enum AccountGateMotive {
  buy(
    Icons.shopping_bag_outlined,
    'Crea tu cuenta para comprar',
    'Acuerda el precio con quien vende, paga por transferencia o en efectivo '
        'y recibe en el campus.',
  ),
  chat(
    Icons.chat_bubble_outline,
    'Crea tu cuenta para chatear',
    'Pregunta por el producto, negocia el precio y acuerda la entrega sin '
        'salir de Musubi.',
  ),
  save(
    Icons.favorite_border,
    'Crea tu cuenta para guardar',
    'Guarda lo que te gusta y encuéntralo rápido cuando vuelvas.',
  ),
  offer(
    Icons.front_hand_outlined,
    'Crea tu cuenta para ofrecerlo',
    'Responde «Yo tengo este producto» y véndeselo a quien lo está buscando.',
  ),
  request(
    Icons.campaign_outlined,
    'Crea tu cuenta para pedirlo',
    'Publica lo que necesitas y recibe ofertas de quien ya lo tiene.',
  ),
  publish(
    Icons.add_box_outlined,
    'Crea tu cuenta para publicar',
    'Vende lo que ya no usas o pide lo que necesitas a tu comunidad.',
  ),
  messages(
    Icons.chat_bubble_outline,
    'Aquí verás tus mensajes',
    'Crea tu cuenta o inicia sesión para chatear con quien compra y quien '
        'vende.',
  ),
  profile(
    Icons.person_outline,
    'Crea tu perfil',
    'Tu reputación, tus pedidos y tus publicaciones, en un solo lugar.',
  ),
  follow(
    Icons.person_add_alt,
    'Crea tu cuenta para seguir',
    'Sigue a quien vende lo que te interesa y entérate cuando publique algo '
        'nuevo.',
  );

  new(this.icon, this.title, this.message);

  final IconData icon;
  final String title;
  final String message;
}

/// Abre la hoja "Crea tu cuenta" sin salir de la pantalla. [returnTo] es a
/// donde se vuelve al terminar el registro o el inicio de sesion.
Future<void> showAccountGate(
  BuildContext context, {
  required AccountGateMotive motive,
  required String returnTo,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: context.musubi.background,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(MusubiSizes.radiusSheet),
    ),
  ),
  builder: (_) => AccountGateSheet(motive: motive, returnTo: returnTo),
);

/// Cierra la hoja y abre el registro o el inicio de sesion recordando a donde
/// volver al terminar.
void continueToAccount(
  BuildContext context,
  WidgetRef ref, {
  required String route,
  required String returnTo,
}) {
  ref.read(returnPathProvider.notifier).remember(returnTo);
  final router = GoRouter.of(context);
  Navigator.of(context).pop();
  // go (no push): al entrar, la guardia del router saca de la pantalla de
  // visitante hacia `?desde=`.
  router.go(
    Uri(
      path: route,
      queryParameters: {AppRoutes.returnParam: returnTo},
    ).toString(),
  );
}

/// X de "Iniciar sesion" y "Crea tu cuenta" cuando no hay a donde hacer pop:
/// vuelve a la pantalla desde la que se abrio (`?desde=` o la recordada).
class ExitToExploreButton extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(Icons.close),
    tooltip: 'Seguir explorando',
    onPressed: () => context.go(
      AppRoutes.safeReturn(
        GoRouterState.of(context).uri.queryParameters[AppRoutes.returnParam] ??
            ref.read(returnPathProvider),
      ),
    ),
  );
}

/// Contenido de la hoja (maqueta: `.gate` + acciones + pie).
class AccountGateSheet extends ConsumerWidget {
  const new({required this.motive, required this.returnTo, super.key});

  final AccountGateMotive motive;
  final String returnTo;

  void _continue(BuildContext context, WidgetRef ref, String route) =>
      continueToAccount(context, ref, route: route, returnTo: returnTo);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          MusubiSizes.gutter,
          0,
          MusubiSizes.gutter,
          MusubiSizes.space4,
        ),
        child: Column(
          key: Key('account-gate-${motive.name}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.brandSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(motive.icon, size: 30, color: c.brandText),
              ),
            ),
            const SizedBox(height: MusubiSizes.space4),
            Text(
              motive.title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: MusubiSizes.space2),
            Text(
              motive.message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: MusubiSizes.space4),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MusubiSizes.space3,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined, size: 16, color: c.brandText),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Solo necesitas tu correo de la universidad',
                        style: MusubiType.label.copyWith(color: c.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MusubiSizes.space6),
            MusubiButton(
              label: 'Crear cuenta',
              onPressed: () => _continue(context, ref, AppRoutes.signUp),
            ),
            const SizedBox(height: MusubiSizes.space2),
            MusubiButton(
              label: 'Ya tengo cuenta',
              kind: MusubiButtonKind.secondary,
              onPressed: () => _continue(context, ref, AppRoutes.signIn),
            ),
            MusubiButton(
              label: 'Seguir explorando',
              kind: MusubiButtonKind.text,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: MusubiSizes.space1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.undo, size: 14, color: c.textSecondary),
                const SizedBox(width: MusubiSizes.space1),
                Flexible(
                  child: Text(
                    'Al terminar, te regresamos a donde estabas.',
                    style: textTheme.bodySmall?.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
