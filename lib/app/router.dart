import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/shell/app_shell.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/status/presentation/home_screen.dart';

/// Rutas de la app (02-01). Cada modulo reemplaza su seccion al implementar su
/// HU; los nombres en espanol coinciden con la maqueta.
abstract final class AppRoutes {
  static const home = '/';
  static const wanted = '/se-busca';
  static const messages = '/mensajes';
  static const profile = '/perfil';
  static const publish = '/publicar';
  static const signIn = '/iniciar-sesion';
  static const signUp = '/registro';
  static const forgotPassword = '/recuperar-contrasena';

  /// Parametro con la ruta a la que se vuelve despues de iniciar sesion.
  static const returnParam = 'desde';

  /// Requieren sesion: el visitante va a iniciar sesion.
  /// NOTE (HU-48): mostrar antes el aviso "Crea tu cuenta" de la maqueta.
  static const Set<String> requiresSession = {publish, messages, profile};

  /// Solo para visitantes: con sesion se vuelve a Inicio.
  static const Set<String> visitorsOnly = {signIn, signUp, forgotPassword};

  /// Ruta de regreso segura: solo rutas internas conocidas (evita redirigir a
  /// un destino arbitrario con `?desde=`).
  static String safeReturn(String? candidate) {
    const known = {home, wanted, messages, profile, publish};
    return candidate != null && known.contains(candidate) ? candidate : home;
  }
}

/// Decide a donde va una navegacion segun la sesion (pura: se prueba sola).
String? sessionRedirect({required bool signedIn, required Uri location}) {
  final path = location.path;
  if (!signedIn && AppRoutes.requiresSession.contains(path)) {
    return Uri(
      path: AppRoutes.signIn,
      queryParameters: {AppRoutes.returnParam: path},
    ).toString();
  }
  if (signedIn && AppRoutes.visitorsOnly.contains(path)) {
    return AppRoutes.safeReturn(
      location.queryParameters[AppRoutes.returnParam],
    );
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // El router reevalua la guardia cuando cambia la sesion, sin recrearse.
  final sessionChanges = ValueNotifier<SessionState>(
    ref.read(sessionControllerProvider),
  );
  ref
    ..listen(
      sessionControllerProvider,
      (_, next) => sessionChanges.value = next,
    )
    ..onDispose(sessionChanges.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: sessionChanges,
    redirect: (context, state) => sessionRedirect(
      signedIn: ref.read(sessionControllerProvider) is SignedIn,
      location: state.uri,
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wanted,
                // NOTE (HU-15): tablero "Se busca".
                builder: (context, state) => const UpcomingSection(
                  title: 'Se busca',
                  message: 'Aquí verás lo que buscan en tu campus.',
                  icon: Icons.campaign_outlined,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                // NOTE (HU-22): bandeja de conversaciones.
                builder: (context, state) => const UpcomingSection(
                  title: 'Mensajes',
                  message: 'Aquí estarán tus conversaciones.',
                  icon: Icons.chat_bubble_outline,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                // NOTE (HU-04): perfil; NOTE (HU-02): cerrar sesion.
                builder: (context, state) => const UpcomingSection(
                  title: 'Perfil',
                  message: 'Aquí estarán tu perfil y tus ajustes.',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.publish,
        // NOTE (HU-06): vender un producto.
        // NOTE (HU-13): publicar una necesidad.
        builder: (context, state) => const UpcomingSection(
          title: 'Publicar',
          message: 'Aquí podrás vender un producto o pedir lo que necesitas.',
          icon: Icons.add_circle_outline,
        ),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        // NOTE (HU-02): pantalla "Iniciar sesion" de la maqueta.
        builder: (context, state) => const UpcomingSection(
          title: 'Iniciar sesión',
          message: 'Entra con tu correo institucional.',
          icon: Icons.login,
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        // NOTE (HU-01): pantalla "Crea tu cuenta" de la maqueta.
        builder: (context, state) => const UpcomingSection(
          title: 'Crea tu cuenta',
          message: 'Usa el correo de tu universidad.',
          icon: Icons.person_add_alt,
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        // NOTE (HU-56): recuperar la contrasena.
        builder: (context, state) => const UpcomingSection(
          title: 'Recuperar contraseña',
          message: 'Te enviaremos un código a tu correo institucional.',
          icon: Icons.lock_reset,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
