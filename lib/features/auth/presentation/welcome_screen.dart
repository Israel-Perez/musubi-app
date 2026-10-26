import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';

/// "Correo verificado" (maqueta `Verificacion-lista`, HU-03).
class WelcomeScreen extends ConsumerWidget {
  const new({required this.user, super.key});

  final AuthUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final c = context.musubi;
    final user = this.user;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MusubiSizes.gutter),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.verified, size: 56, color: c.success),
              const SizedBox(height: MusubiSizes.space3),
              Text('CORREO VERIFICADO', style: textTheme.labelSmall),
              const SizedBox(height: MusubiSizes.space2),
              Text(
                user == null
                    ? '¡Listo! Ya eres parte de Musubi'
                    : '¡Listo, ${user.firstName}! Ya eres parte de Musubi',
                style: textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MusubiSizes.space2),
              Text(
                user == null
                    ? 'Compra, vende y pide en tu campus.'
                    : 'Ya eres parte de la ${user.campus.shortName}. '
                          'Compra, vende y pide.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (user != null) ...[
                const SizedBox(height: MusubiSizes.space6),
                Container(
                  padding: const EdgeInsets.all(MusubiSizes.space4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(
                      MusubiSizes.radiusButton,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: c.brandSoft,
                        child: Text(
                          user.initials,
                          style: textTheme.titleMedium?.copyWith(
                            color: c.brandText,
                          ),
                        ),
                      ),
                      const SizedBox(width: MusubiSizes.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName, style: textTheme.titleMedium),
                            Text(user.email, style: textTheme.bodyMedium),
                            Text(
                              'Campus ${user.campus.shortName}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: c.successText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              MusubiButton(
                label: 'Empezar a explorar',
                // Vuelve a donde estaba al abrir "Crea tu cuenta" (HU-48).
                onPressed: () =>
                    context.go(ref.read(returnPathProvider.notifier).take()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
