import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/features/auth/presentation/account_gate_art.dart';

/// Por que se pide la cuenta (maqueta `Inicio-visitante`, HU-48): la
/// ilustracion, el titulo y el texto de la hoja "Crea tu cuenta".
enum AccountGateMotive {
  buy(
    'Crea tu cuenta para comprar',
    'Acuerda el precio, paga seguro y recibe en el campus.',
  ),
  chat(
    'Crea tu cuenta para chatear',
    'Pregunta, negocia y acuerda la entrega.',
  ),
  save(
    'Guarda lo que te gusta',
    'Crea tu cuenta y encuéntralo rápido después.',
  ),
  offer('¿Lo tienes? Véndelo', 'Crea tu cuenta y ofrécelo a quien lo busca.'),
  request(
    'Pide lo que necesitas',
    'Crea tu cuenta y recibe ofertas de tu campus.',
  ),
  publish('Vende en minutos', 'Crea tu cuenta, sube unas fotos y listo.'),
  messages(
    'Aquí verás tus chats',
    'Entra para hablar con quien compra y vende.',
  ),
  profile('Crea tu perfil', 'Tu reputación, ventas y compras en un lugar.'),
  campus(
    'Estás explorando la UTTT',
    'Tu campus se fija con tu correo institucional.',
  );

  new(this.title, this.message);

  final String title;
  final String message;

  Widget get art => switch (this) {
    buy => const BuyArt(),
    chat => const ChatArt(),
    save => const SaveArt(),
    offer => const OfferArt(),
    request => const RequestArt(),
    publish => const PublishArt(),
    messages => const MessagesArt(),
    profile => const ProfileArt(),
    campus => const CampusArt(),
  };
}

/// Abre la hoja "Crea tu cuenta" sin salir de la pantalla. [returnTo] es a
/// donde se vuelve al terminar el registro o el inicio de sesion.
Future<void> showAccountGate(
  BuildContext context, {
  required AccountGateMotive motive,
  required String returnTo,
}) => showMusubiSheet<void>(
  context,
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

/// Contenido de la hoja (maqueta: ilustracion + texto + "Solo con tu correo"
/// + acciones + "Al entrar, vuelves justo aquí.").
class AccountGateSheet extends ConsumerWidget {
  const new({required this.motive, required this.returnTo, super.key});

  final AccountGateMotive motive;
  final String returnTo;

  void _continue(BuildContext context, WidgetRef ref, String route) =>
      continueToAccount(context, ref, route: route, returnTo: returnTo);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          key: Key('account-gate-${motive.name}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            motive.art,
            const SizedBox(height: 18),
            Semantics(
              header: true,
              child: Text(
                motive.title,
                textAlign: TextAlign.center,
                style: MusubiType.style(
                  23,
                  weight: FontWeight.w800,
                  line: 29,
                  em: -0.025,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  motive.message,
                  textAlign: TextAlign.center,
                  style: MusubiType.style(
                    14.5,
                    line: 21,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: MusubiSizes.space4),
            const Center(child: InstitutionalEmailChip()),
            const SizedBox(height: 18),
            MusubiButton(
              label: 'Crear cuenta',
              onPressed: () => _continue(context, ref, AppRoutes.signUp),
            ),
            const SizedBox(height: 10),
            MusubiButton(
              label: 'Ya tengo cuenta',
              kind: MusubiButtonKind.secondary,
              onPressed: () => _continue(context, ref, AppRoutes.signIn),
            ),
            const SizedBox(height: 10),
            MusubiButton(
              label: 'Seguir explorando',
              kind: MusubiButtonKind.quiet,
              height: MusubiSizes.buttonHeightSmall,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                MusubiIcon(MusubiIcons.undo2, size: 14, color: c.textSecondary),
                Text(
                  'Al entrar, vuelves justo aquí.',
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w600,
                    line: 16,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        // X de la maqueta: 28 abajo del borde de la hoja y 26 de la derecha
        // (antes van 8 de relleno y 5 de la manija; a los lados, 20).
        Positioned(
          top: 15,
          right: 6,
          child: SheetCloseButton(onTap: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }
}

/// "VC PN JS DH · Solo con tu correo @uttt.edu.mx".
class InstitutionalEmailChip extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          CommunityAvatars(
            size: 26,
            overlap: 8,
            borderColor: c.surface,
            borderWidth: 2,
            fontSize: 9,
          ),
          Flexible(
            child: Text(
              'Solo con tu correo @uttt.edu.mx',
              style: MusubiType.style(
                12.5,
                weight: FontWeight.w700,
                line: 16,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
