import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/features/auth/presentation/sign_out_button.dart';

/// Pestana Perfil. NOTE (HU-04): perfil, datos del campus y calificaciones.
/// NOTE (HU-54): "Cerrar sesion" pasa a `Ajustes` como en la maqueta.
class ProfileScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil')),
    body: const SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: EmptyView(
              title: 'Perfil',
              message: 'Aquí estarán tu perfil y tus ajustes.',
              icon: Icons.person_outline,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(MusubiSizes.gutter),
            child: SignOutButton(),
          ),
        ],
      ),
    ),
  );
}
