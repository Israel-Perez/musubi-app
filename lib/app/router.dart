import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/app/shell/app_shell.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:musubi_app/features/auth/presentation/legal_screens.dart';
import 'package:musubi_app/features/auth/presentation/sign_in_screen.dart';
import 'package:musubi_app/features/auth/presentation/sign_up_screen.dart';
import 'package:musubi_app/features/auth/presentation/verification_screen.dart';
import 'package:musubi_app/features/auth/presentation/welcome_screen.dart';
import 'package:musubi_app/features/chat/presentation/chat_controller.dart';
import 'package:musubi_app/features/chat/presentation/chat_screen.dart';
import 'package:musubi_app/features/chat/presentation/inbox_screen.dart';
import 'package:musubi_app/features/listings/presentation/my_products_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_condition_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_details_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_done_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_photos_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_price_screen.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_screen.dart';
import 'package:musubi_app/features/marketplace/presentation/home_screen.dart';
import 'package:musubi_app/features/marketplace/presentation/product_screen.dart';
import 'package:musubi_app/features/marketplace/presentation/search_screen.dart';
import 'package:musubi_app/features/notifications/presentation/notifications_screen.dart';
import 'package:musubi_app/features/orders/presentation/my_orders_screen.dart';
import 'package:musubi_app/features/orders/presentation/order_payment_screen.dart';
import 'package:musubi_app/features/profile/presentation/privacy_screen.dart';
import 'package:musubi_app/features/profile/presentation/profile_screen.dart';
import 'package:musubi_app/features/profile/presentation/seller_profile_screen.dart';
import 'package:musubi_app/features/profile/presentation/settings_screen.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/my_wanted_screen.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_budget_screen.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_details_screen.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_done_screen.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_product_screen.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_board_screen.dart';
import 'package:musubi_app/features/reputation/presentation/rate_screen.dart';

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

  /// `Privacidad` (HU-46; "Quien te ve" llega con HU-04).
  static const accountPrivacy = '/ajustes/privacidad';

  /// "Vender un producto" (HU-06): `Vender-1…4` y `Vender-listo`.
  static const sell = '/vender';
  static const sellDetails = '/vender/detalles';
  static const sellPrice = '/vender/precio';
  static const sellCondition = '/vender/estado';
  static const sellDone = '/vender/listo';

  /// "Mis productos" (`Mis-productos`).
  static const myProducts = '/mis-productos';

  /// "Ver todos" de "Mis pedidos" (HU-25); siempre con sesion.
  static const myOrders = '/mis-pedidos';

  /// "Publicar lo que necesito" (HU-13).
  static const need = '/necesito';

  /// `Necesidad-2`.
  static const needDetails = '/necesito/detalles';

  /// `Necesidad-3`.
  static const needBudget = '/necesito/presupuesto';

  /// `Necesidad-publicada`.
  static const needDone = '/necesito/listo';

  /// `Mis-solicitudes` (HU-13).
  static const myWanted = '/mis-solicitudes';

  /// `Mis-solicitudes` con una solicitud elegida (HU-30: el aviso de una
  /// oferta abre esa solicitud con sus ofertas). Sin id, la primera.
  static String myWantedRequest(String id) => id.isEmpty
      ? myWanted
      : '$myWanted?solicitud=${Uri.encodeQueryComponent(id)}';

  /// El tablero con "Yo tengo este producto" de una solicitud abierto (HU-19:
  /// el aviso de una solicitud compatible).
  static String wantedOffer(String id) =>
      '$wanted?ofrecer=${Uri.encodeQueryComponent(id)}';

  /// "Editar solicitud" (HU-14): `Necesidad-1` con los datos de la elegida.
  static const editNeed = '/editar-solicitud';

  /// "Editar solicitud", `Necesidad-2`.
  static const editNeedDetails = '/editar-solicitud/detalles';

  /// "Editar solicitud", `Necesidad-3`.
  static const editNeedBudget = '/editar-solicitud/presupuesto';

  /// "Editar publicación" (HU-07): `Vender-2` con los datos de la publicacion
  /// (sin `Vender-1`: las fotos no se editan).
  static const editListing = '/editar-publicacion';

  /// "Editar publicación", `Vender-3`.
  static const editListingPrice = '/editar-publicacion/precio';

  /// "Editar publicación", `Vender-4`.
  static const editListingCondition = '/editar-publicacion/estado';

  /// "Favoritos" (HU-53), dentro de la rama de Perfil.
  static const favorites = '/favoritos';

  /// Chat con quien vende (HU-20): `extra` lleva el `ProductSummary`.
  static const chat = '/chat';

  /// Detalle de una publicacion (HU-11), publico como la vitrina. `extra`
  /// puede llevar la tarjeta de Inicio para mostrarla mientras carga.
  static String product(String id) => '/producto/${Uri.encodeComponent(id)}';

  /// Una conversacion existente (desde `Mensajes`, HU-22).
  static String conversation(String id) => '$chat/${Uri.encodeComponent(id)}';

  /// "Tu pedido" (`Pedido-pago`, HU-23).
  static const orders = '/pedido';

  /// Un pedido (HU-23); siempre con sesion.
  static String order(String id) => '$orders/${Uri.encodeComponent(id)}';

  /// `Calificar` un pedido completado (HU-27, HU-45); siempre con sesion.
  static String rate(String id) => '${order(id)}/calificar';

  /// Perfil publico de otra persona (HU-05); siempre con sesion.
  static const seller = '/vendedor';

  static String sellerProfile(String id) =>
      '$seller/${Uri.encodeComponent(id)}';

  /// Parametro con la ruta a la que se vuelve despues de iniciar sesion.
  static const returnParam = 'desde';

  /// Requieren sesion. Desde la app, el visitante ve antes la hoja "Crea tu
  /// cuenta" (HU-48); esta guardia cubre los enlaces directos.
  static const Set<String> requiresSession = {
    messages,
    profile,
    settings,
    accountPrivacy,
    sell,
    sellDetails,
    sellPrice,
    sellCondition,
    sellDone,
    myProducts,
    myOrders,
    need,
    myWanted,
    editNeed,
    editNeedDetails,
    editNeedBudget,
    editListing,
    editListingPrice,
    editListingCondition,
    favorites,
    notifications,
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
  final needsSession =
      AppRoutes.requiresSession.contains(path) ||
      path == AppRoutes.chat ||
      path.startsWith('${AppRoutes.chat}/') ||
      path.startsWith('${AppRoutes.orders}/') ||
      path.startsWith('${AppRoutes.seller}/');
  if (!signedIn && needsSession) {
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
              // Con la barra e Inicio activo, como `Notificaciones` (HU-31).
              GoRoute(
                path: AppRoutes.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wanted,
                builder: (context, state) => WantedBoardScreen(
                  offerTo: state.uri.queryParameters['ofrecer'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
              // Con la barra y Perfil activo, como `Mis-solicitudes` (HU-13).
              GoRoute(
                path: AppRoutes.myWanted,
                builder: (context, state) => MyWantedScreen(
                  initialId: state.uri.queryParameters['solicitud'],
                ),
              ),
              GoRoute(
                path: AppRoutes.favorites,
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.need,
        builder: (context, state) => const NeedProductScreen(),
      ),
      GoRoute(
        path: AppRoutes.needDetails,
        builder: (context, state) => const NeedDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.needBudget,
        builder: (context, state) => const NeedBudgetScreen(),
      ),
      GoRoute(
        path: AppRoutes.editNeed,
        builder: (context, state) => const NeedProductScreen(editing: true),
      ),
      GoRoute(
        path: AppRoutes.editNeedDetails,
        builder: (context, state) => const NeedDetailsScreen(editing: true),
      ),
      GoRoute(
        path: AppRoutes.editNeedBudget,
        builder: (context, state) => const NeedBudgetScreen(editing: true),
      ),
      GoRoute(
        path: AppRoutes.needDone,
        builder: (context, state) => NeedDoneScreen(
          request: state.extra is WantedRequest
              ? state.extra! as WantedRequest
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        // Sin la publicacion (enlace directo) no hay con quien hablar.
        redirect: (context, state) =>
            state.extra is ProductSummary ? null : AppRoutes.messages,
        builder: (context, state) => ChatScreen(
          target: ChatTarget.product(state.extra! as ProductSummary),
        ),
      ),
      GoRoute(
        path: '/producto/:id',
        builder: (context, state) => ProductScreen(
          productId: state.pathParameters['id']!,
          preview: state.extra is ProductSummary
              ? state.extra! as ProductSummary
              : null,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.seller}/:id',
        builder: (context, state) => SellerProfileScreen(
          sellerId: state.pathParameters['id']!,
          origin: state.extra is SellerProfileOrigin
              ? state.extra! as SellerProfileOrigin
              : null,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.orders}/:id',
        builder: (context, state) =>
            OrderPaymentScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${AppRoutes.orders}/:id/calificar',
        builder: (context, state) =>
            RateScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${AppRoutes.chat}/:id',
        builder: (context, state) => ChatScreen(
          target: ChatTarget.conversation(state.pathParameters['id']!),
          // HU-17: "Aceptar oferta" deja el saludo escrito.
          draft: state.extra is String ? state.extra! as String : null,
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
        path: AppRoutes.myOrders,
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.editListing,
        builder: (context, state) => const SellDetailsScreen(editing: true),
      ),
      GoRoute(
        path: AppRoutes.editListingPrice,
        builder: (context, state) => const SellPriceScreen(editing: true),
      ),
      GoRoute(
        path: AppRoutes.editListingCondition,
        builder: (context, state) => const SellConditionScreen(editing: true),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountPrivacy,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
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
