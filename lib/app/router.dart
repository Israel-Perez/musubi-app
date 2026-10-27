import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/app/shell/app_shell.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:musubi_app/features/auth/presentation/legal_screens.dart';
import 'package:musubi_app/features/auth/presentation/sign_in_screen.dart';
import 'package:musubi_app/features/auth/presentation/sign_up_screen.dart';
import 'package:musubi_app/features/auth/presentation/verification_screen.dart';
import 'package:musubi_app/features/auth/presentation/welcome_screen.dart';
import 'package:musubi_app/features/listings/presentation/my_products_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_condition_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_details_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_done_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_photos_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_price_screen.dart';
import 'package:musubi_app/features/marketplace/presentation/home_screen.dart';
import 'package:musubi_app/features/profile/presentation/profile_screen.dart';

/// Rutas de la app (02-01). Cada modulo reemplaza su seccion al implementar su
/// HU; los nombres en espanol coinciden con la maqueta.
abstract final class AppRoutes {
  static const home = '/';
  static const wanted = '/se-busca';
  static const messages = '/mensajes';
  static const profile = '/perfil';
  static const signIn = '/iniciar-sesion';
  static const signUp = '/registro';
  static const verification = '/registro/verificacion';
  static const welcome = '/bienvenida';
  static const privacy = '/aviso-de-privacidad';
  static const terms = '/terminos';
  static const forgotPassword = '/recuperar-contrasena';
  static const search = '/buscar';
  static const notifications = '/notificaciones';
  static const settings = '/ajustes';

  /// "Vender un producto" (HU-06): `Vender-1…4` y `Vender-listo`.
  static const sell = '/vender';
  static const sellDetails = '/vender/detalles';
  static const sellPrice = '/vender/precio';
  static const sellCondition = '/vender/estado';
  static const sellDone = '/vender/listo';

  /// "Mis productos" (`Mis-productos`).
  static const myProducts = '/mis-productos';

  /// "Publicar lo que necesito" (HU-13).
  static const need = '/necesito';

  /// Parametro con la ruta a la que se vuelve despues de iniciar sesion.
  static const returnParam = 'desde';

  /// Requieren sesion. Desde la app, el visitante ve antes la hoja "Crea tu
  /// cuenta" (HU-48); esta guardia cubre los enlaces directos.
  static const Set<String> requiresSession = {
    messages,
    profile,
    settings,
    sell,
    sellDetails,
    sellPrice,
    sellCondition,
    sellDone,
    myProducts,
    need,
  };

  /// Solo para visitantes: con sesion se vuelve a Inicio.
  static const Set<String> visitorsOnly = {
    signIn,
    signUp,
    verification,
    forgotPassword,
  };

  /// Ruta de regreso segura: solo rutas internas conocidas (evita redirigir a
  /// un destino arbitrario con `?desde=`).
  static String safeReturn(String? candidate) {
    const known = {home, wanted, messages, profile};
    return candidate != null && known.contains(candidate) ? candidate : home;
  }
}

/// Decide a donde va una navegacion segun la sesion (pura: se prueba sola).
/// [rememberedReturn] es a donde volver si la ruta no trae `?desde=` (la
/// pantalla desde la que se abrio "Crea tu cuenta").
String? sessionRedirect({
  required bool signedIn,
  required Uri location,
  String? rememberedReturn,
}) {
  final path = location.path;
  if (!signedIn && AppRoutes.requiresSession.contains(path)) {
    return Uri(
      path: AppRoutes.signIn,
      queryParameters: {AppRoutes.returnParam: path},
    ).toString();
  }
  if (signedIn && AppRoutes.visitorsOnly.contains(path)) {
    return AppRoutes.safeReturn(
      location.queryParameters[AppRoutes.returnParam] ?? rememberedReturn,
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
      rememberedReturn: ref.read(returnPathProvider),
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
                  icon: MusubiIcons.megaphone,
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
                  icon: MusubiIcons.messageCircle,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.need,
        // NOTE (HU-13): publicar una necesidad (`Necesidad-1…3`).
        builder: (context, state) => const UpcomingSection(
          title: 'Lo que necesito',
          message: 'Aquí podrás decir qué buscas y cuánto quieres pagar.',
          icon: MusubiIcons.megaphone,
          canGoBack: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.sell,
        builder: (context, state) => const SellPhotosScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellDetails,
        builder: (context, state) => const SellDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellPrice,
        builder: (context, state) => const SellPriceScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellCondition,
        builder: (context, state) => const SellConditionScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellDone,
        builder: (context, state) => SellDoneScreen(
          published: state.extra is PublishedListing
              ? state.extra! as PublishedListing
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.myProducts,
        builder: (context, state) => const MyProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        // NOTE (HU-09): busqueda y filtros.
        builder: (context, state) => const UpcomingSection(
          title: 'Buscar',
          message: 'Aquí podrás buscar libros, laptops, batas y más.',
          icon: MusubiIcons.search,
          canGoBack: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        // NOTE (HU-31): avisos de la app.
        builder: (context, state) => const UpcomingSection(
          title: 'Notificaciones',
          message: 'Aquí verás ofertas, mensajes y avisos de tu campus.',
          icon: MusubiIcons.bell,
          canGoBack: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => SignInScreen(
          passwordChanged: state.extra is PasswordChanged
              ? state.extra! as PasswordChanged
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.verification,
        builder: (context, state) => VerificationScreen(
          registration: state.extra is Registration
              ? state.extra! as Registration
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => WelcomeScreen(
          user: state.extra is AuthUser ? state.extra! as AuthUser : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const PrivacyNoticeScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => ForgotPasswordScreen(
          email: state.extra is String ? state.extra! as String : null,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
