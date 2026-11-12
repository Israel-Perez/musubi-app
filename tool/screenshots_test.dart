// Capturas de la app para compararlas con la maqueta (SCRUM-82): cada
// pantalla a 390 x 844 puntos a 3x (otro tamano con SHOT_WIDTH/SHOT_HEIGHT),
// con Plus Jakarta Sans, sombras y fotos reales, y la barra de estado de la
// maqueta (54 arriba, 24 abajo).
//
// No corre con `flutter test` (vive en tool/). Para generarlas:
//   flutter test tool/screenshots_test.dart --dart-define=SHOTS=<carpeta>
// Opcionales: --dart-define=ONLY=inicio-visitante,registro (solo esas),
// --dart-define=DARK=true (modo noche) y --dart-define=RECTS=true (imprime la
// caja de cada texto, para compararla con la del DOM de la maqueta).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/platform/email_inbox.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/genai/domain/agreement_models.dart';
import 'package:musubi_app/features/genai/presentation/agreement_providers.dart';
import 'package:musubi_app/features/listings/data/photo_picker.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/data/demo_catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/favorite_models.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';
import 'package:musubi_app/features/notifications/presentation/notification_providers.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/profile/presentation/theme_preference_providers.dart';
import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../test/helpers/fake_agreements.dart';
import '../test/helpers/fake_auth_repository.dart';
import '../test/helpers/fake_catalog_repository.dart';
import '../test/helpers/fake_chat.dart';
import '../test/helpers/fake_favorites_repository.dart';
import '../test/helpers/fake_listings_repository.dart';
import '../test/helpers/fake_notifications.dart';
import '../test/helpers/fake_orders.dart';
import '../test/helpers/fake_profile_repository.dart';
import '../test/helpers/fake_reputation.dart';
import '../test/helpers/fake_session_api.dart';
import '../test/helpers/fake_status_repository.dart';
import '../test/helpers/fake_theme_preference_repository.dart';
import '../test/helpers/fake_wanted.dart';
import '../test/helpers/in_memory_token_store.dart';

const _out = String.fromEnvironment('SHOTS');
const _only = String.fromEnvironment('ONLY');
const _dark = bool.fromEnvironment('DARK');
const _rects = bool.fromEnvironment('RECTS');

/// Tamano en pt (390 x 844 = maqueta). Google Play pide capturas 9:16:
/// 360 x 640 da 1080 x 1920 (02-02).
const _width = int.fromEnvironment('SHOT_WIDTH', defaultValue: 390);
const _height = int.fromEnvironment('SHOT_HEIGHT', defaultValue: 844);

/// Hora de la maqueta ("hace 20 min" sale igual que en el prototipo).
final _now = DateTime.utc(2026, 10, 5, 20);

const _ana = SessionProfile(
  fullName: 'Ana Sofía Ramírez',
  email: 'ana.ramirez@uttt.edu.mx',
  campus: 'UTTT',
);

final _anaUser = AuthUser(
  id: 'u1',
  fullName: _ana.fullName,
  email: _ana.email,
  emailVerified: true,
  campus: uttt,
);

/// El perfil de la maqueta (`Perfil`): "Ing. en Sistemas · 6º semestre",
/// 4.9 con 27 calificaciones, 12 ventas y 8 compras.
final _anaProfile = MyProfile(
  id: '6716a0000000000000000001',
  fullName: _ana.fullName,
  email: _ana.email,
  emailVerifiedAt: DateTime.utc(2025, 1, 15),
  campusShortName: 'UTTT',
  campusName: 'Universidad Tecnológica de Tula-Tepeji',
  academicTerm: const AcademicTerm(unit: 'semestre', count: 12),
  career: const Career(
    slug: 'ing-sistemas',
    name: 'Ingeniería en Sistemas',
    shortName: 'Ing. en Sistemas',
    firstTerm: 1,
    lastTerm: 12,
    level: CareerLevel.engineering,
  ),
  term: 6,
  stats: const ProfileStats(
    ratingAvg: 4.9,
    ratingCount: 27,
    sales: 12,
    purchases: 8,
  ),
);

/// Fotos reales para `Vender-1` (la de la maqueta, copiada a archivos).
final List<String> _photoFiles = [];

class _FilePicker implements PhotoPicker {
  @override
  Future<String?> takePhoto() async => _photoFiles.first;

  @override
  Future<List<String>> pickFromGallery({required int max}) async =>
      _photoFiles.take(max).toList();
}

/// Hora local de la maqueta (los mensajes de "Ayer, 6:40 p. m.").
DateTime _local(int day, int hour, int minute) =>
    DateTime(2026, 10, day, hour, minute).toUtc();

/// `Chat-Valeria`: Ana pregunta por la calculadora de Valeria.
/// El pedido de `Pedido-pago` (HU-23): la calculadora, en la Biblioteca el
/// jueves 8 de octubre a la 1:00 p. m.
/// Los avisos de `Notificaciones` (HU-31), como la maqueta.
final _notices = FakeNotificationRepository(
  items: [
    sampleNotification(createdAt: DateTime.utc(2026, 10, 6, 3, 14)),
    sampleNotification(
      id: 'n2',
      type: 'offer_received',
      category: 'requests',
      title: 'Alguien tiene lo que buscas',
      body:
          'Diego respondió “Yo tengo este producto” a tu solicitud de '
          r'Calculadora Casio · $500.',
      target: NotificationTarget.wanted,
      targetId: 'w1',
      createdAt: DateTime.utc(2026, 10, 6, 2, 5),
    ),
    sampleNotification(
      id: 'n3',
      type: 'request_expiring',
      category: 'requests',
      title: 'Tu solicitud vence mañana',
      body: 'Física Universitaria, Sears-Zemansky. ¿Quieres extender la fecha?',
      target: NotificationTarget.wanted,
      targetId: 'w2',
      read: true,
      createdAt: DateTime.utc(2026, 10, 5, 1),
    ),
  ],
);

/// La IA de las escenas (HU-32/33/34); cada escena la ajusta.
final _ai = FakeAgreementRepository();

final Order _order = _orderOf('o1');

/// HU-24: el mismo pedido como "Tu venta" (pendiente y pagado en efectivo) y
/// como "Tu pedido" confirmado, listo para "Confirmar entrega".
final Order _sale = _orderOf('o2', isBuyer: false, paysCash: true);
final Order _accepted = _orderOf(
  'o3',
  status: OrderStatus.confirmed,
  paysCash: true,
);

/// HU-25: las otras compras de la seccion "Mis pedidos" de `Perfil`.
final Order _algebra = _orderOf(
  'o4',
  title: 'Álgebra lineal, Grossman',
  priceCents: 29000,
  photo: 'calculo',
);
final Order _arduino = _orderOf(
  'o5',
  status: OrderStatus.completed,
  paysCash: true,
  title: 'Kit Arduino UNO con sensores',
  priceCents: 42000,
  photo: 'arduino',
  updatedAt: DateTime(2026, 9, 26, 13).toUtc(),
);

Order _orderOf(
  String id, {
  OrderStatus status = OrderStatus.pending,
  bool isBuyer = true,
  bool paysCash = false,
  String title = 'Calculadora Casio fx-991ES Plus',
  int priceCents = 45000,
  String photo = 'casio',
  DateTime? updatedAt,
}) => Order(
  id: id,
  number: 'MS-2481',
  status: status,
  isBuyer: isBuyer,
  paysCash: paysCash,
  // Otra conversacion: la de `c1` sigue sin pedido ("Resumir acuerdo").
  conversationId: 'c9',
  item: OrderItem(
    title: title,
    priceCents: priceCents,
    quantity: 1,
    totalCents: priceCents,
    photoUrl: 'asset:assets/products/$photo.webp',
  ),
  buyerName: 'Ana Sofía Ramírez',
  sellerName: 'Valeria Cruz',
  pointName: 'Biblioteca',
  deliveryAt: DateTime(2026, 10, 8, 13).toUtc(),
  updatedAt: updatedAt,
);

final _chat = FakeChatRepository(
  conversationValue: const Conversation(
    id: 'c1',
    role: ChatRole.buyer,
    counterpart: valeria,
    context: ChatContext(
      id: 'p1',
      title: 'Calculadora Casio fx-991ES Plus',
      available: true,
      priceCents: 45000,
      condition: 'used',
      conditionDetail: 'fair',
      photoUrl: 'asset:assets/products/casio.webp',
    ),
  ),
  messages: [
    ChatMessage(
      id: 'm1',
      conversationId: 'c1',
      senderId: myId,
      text: '¡Hola, Valeria! ¿Sigue disponible la calculadora?',
      sentAt: _local(4, 18, 38),
    ),
    ChatMessage(
      id: 'm2',
      conversationId: 'c1',
      senderId: valeria.id,
      text: 'Claro, sigue disponible. ¿Cuándo la quieres ver?',
      sentAt: _local(4, 18, 40),
    ),
  ],
  inboxEntries: [
    InboxEntry(
      id: 'c2',
      role: ChatRole.buyer,
      counterpart: const ChatCounterpart(id: 'u-dh', name: 'Diego Hernández'),
      contextTitle: 'Calculadora Casio',
      contextPhotoUrl: 'asset:assets/products/casio.webp',
      lastSenderId: 'u-dh',
      lastText:
          'Perfecto, en la biblioteca. Esta semana tengo libre en las '
          'tardes.',
      lastAt: _local(5, 20, 31),
      unread: 2,
    ),
    InboxEntry(
      id: 'c1',
      role: ChatRole.buyer,
      counterpart: valeria,
      contextTitle: 'Casio fx-991ES Plus',
      contextPhotoUrl: 'asset:assets/products/casio.webp',
      lastSenderId: valeria.id,
      lastText: 'Claro, sigue disponible. ¿Cuándo la quieres ver?',
      lastAt: _local(4, 18, 40),
      unread: 0,
    ),
    InboxEntry(
      id: 'c3',
      role: ChatRole.seller,
      counterpart: const ChatCounterpart(id: 'u-js', name: 'Jorge Salinas'),
      contextTitle: 'Cálculo, Stewart',
      contextPhotoUrl: 'asset:assets/products/calculo.webp',
      lastSenderId: 'u-js',
      lastText: r'¿Aceptas $350 por el libro?',
      lastAt: _local(5, 9, 12).subtract(const Duration(days: 4)),
      unread: 0,
    ),
    InboxEntry(
      id: 'c4',
      role: ChatRole.seller,
      counterpart: const ChatCounterpart(id: 'u-pn', name: 'Paola Núñez'),
      contextTitle: 'Escuadras y compás',
      contextPhotoUrl: 'asset:assets/products/compas.webp',
      lastSenderId: 'u-pn',
      lastText: '¿Las escuadras traen estuche?',
      lastAt: _local(5, 9, 12).subtract(const Duration(days: 5)),
      unread: 0,
    ),
  ],
);

class _InboxStub implements EmailInbox {
  @override
  Future<bool> open() async => true;
}

/// `Se-busca` (`REQUESTS` de la maqueta): nombre completo y carrera.
final List<WantedRequest> _memberBoard = [
  boardWanted(
    neededBy: DateTime(2026, 10, 5),
    createdAt: _now.subtract(const Duration(minutes: 20)),
  ),
  boardWanted(
    id: 'r-laptop',
    title: 'Laptop para programación con 16 GB de RAM',
    category: 'laptops',
    categoryName: 'Laptops',
    budgetCents: 1200000,
    neededBy: DateTime(2026, 10, 15),
    requester: 'Mariana López',
    requesterId: 'u-ml',
    career: 'Ing. en Software',
    offers: 2,
    createdAt: _now.subtract(const Duration(hours: 1)),
  ),
  boardWanted(
    id: 'r-fisica',
    title: 'Física Universitaria, Sears-Zemansky',
    category: 'libros',
    categoryName: 'Libros',
    budgetCents: 40000,
    neededBy: DateTime(2026, 10, 9),
    requester: 'Luis Martínez',
    requesterId: 'u-lm',
    career: 'Actuaría',
    offers: 1,
    createdAt: _now.subtract(const Duration(hours: 3)),
  ),
];

/// `Se-busca-visitante`: solo el nombre corto.
final List<WantedRequest> _visitorBoard = [
  boardWanted(
    title: 'Bata de laboratorio talla M',
    neededBy: DateTime(2026, 10, 5),
    requester: 'Fernanda O.',
    requesterId: null,
    career: null,
    createdAt: _now.subtract(const Duration(minutes: 20)),
  ),
  boardWanted(
    id: 'r-laptop',
    title: 'Laptop para programación con 16 GB de RAM',
    category: 'laptops',
    categoryName: 'Laptops',
    budgetCents: 1200000,
    neededBy: DateTime(2026, 10, 15),
    requester: 'Mariana L.',
    requesterId: null,
    career: null,
    offers: 2,
    createdAt: _now.subtract(const Duration(hours: 1)),
  ),
  boardWanted(
    id: 'r-anatomia',
    title: 'Anatomía de Moore, 8a edición',
    category: 'libros',
    categoryName: 'Libros',
    budgetCents: 60000,
    neededBy: DateTime(2026, 10, 9),
    requester: 'Andrea R.',
    requesterId: null,
    career: null,
    createdAt: _now.subtract(const Duration(hours: 3)),
  ),
];

/// "Compara las ofertas" de `Mis-solicitudes` (HU-17).
final List<ReceivedOffer> _receivedOffers = [
  ReceivedOffer(
    id: 'o-diego',
    kind: OfferKind.direct,
    title: 'Casio fx-991ES Plus',
    priceCents: 50000,
    condition: 'used',
    conditionDetail: 'likeNew',
    photoUrl: 'asset:assets/products/casio.webp',
    message: 'La usé un semestre, incluye tapa y pilas nuevas.',
    offerer: const Offerer(
      id: 'u-dh',
      name: 'Diego Hernández',
      career: 'Ing. Civil',
      ratingAvg: 4.9,
      ratingCount: 32,
    ),
    createdAt: _now.subtract(const Duration(hours: 2)),
  ),
  ReceivedOffer(
    id: 'o-valeria',
    kind: OfferKind.listing,
    productId: 'casio-991es',
    title: 'Calculadora Casio fx-991ES Plus',
    priceCents: 45000,
    condition: 'used',
    conditionDetail: 'fair',
    photoUrl: 'asset:assets/products/casio.webp',
    message: 'Funciona bien, tiene un rayón en la tapa.',
    offerer: const Offerer(
      id: 'u-vc',
      name: 'Valeria Cruz',
      career: 'Arquitectura',
      ratingAvg: 4.6,
      ratingCount: 18,
    ),
    createdAt: _now.subtract(const Duration(hours: 1)),
  ),
];

/// Fecha de la venta de ejemplo (HU-08).
final DateTime _soldAt = DateTime.utc(2026, 9, 28, 18);

/// Mis publicaciones de `Yo-tengo-vincular` (HU-16).
final List<OwnListing> _myListings = [
  const OwnListing(
    product: ProductSummary(
      id: 'p-bata',
      title: 'Bata de laboratorio blanca, talla M',
      priceCents: 25000,
      stock: 1,
      condition: 'Usado',
      photoUrl: 'asset:assets/products/bata.webp',
      category: 'laboratorio',
    ),
    status: ListingStatus.active,
    description: 'La usé un cuatrimestre.',
  ),
  const OwnListing(
    product: ProductSummary(
      id: 'p-stewart',
      title: 'Cálculo de una variable, Stewart',
      priceCents: 38000,
      stock: 1,
      condition: 'Usado',
      photoUrl: 'asset:assets/products/calculo.webp',
      category: 'libros',
    ),
    status: ListingStatus.active,
    description: 'La usé un cuatrimestre.',
  ),
  const OwnListing(
    product: ProductSummary(
      id: 'p-escuadras',
      title: 'Juego de escuadras y compás',
      priceCents: 18000,
      stock: 1,
      condition: 'Nuevo',
      photoUrl: 'asset:assets/products/compas.webp',
      category: 'dibujo',
    ),
    status: ListingStatus.active,
    description: 'La usé un cuatrimestre.',
  ),
  // HU-50: una agotada con "Reponer" (la maqueta: "Cálculo de una variable").
  const OwnListing(
    product: ProductSummary(
      id: 'p-quimica',
      title: 'Química general, Chang',
      priceCents: 30000,
      stock: 0,
      condition: 'Usado',
      photoUrl: 'asset:assets/products/quimica.webp',
      category: 'libros',
    ),
    status: ListingStatus.soldOut,
    description: 'Con algunas notas a lápiz.',
  ),
  // HU-08: una vendida (la maqueta: "Calculadora Casio fx-82LA Plus", 28 sep).
  OwnListing(
    product: const ProductSummary(
      id: 'p-casio-82',
      title: 'Calculadora Casio fx-82LA Plus',
      priceCents: 25000,
      stock: 1,
      condition: 'Usado',
      photoUrl: 'asset:assets/products/casio.webp',
      category: 'calculadoras',
    ),
    status: ListingStatus.sold,
    soldAt: _soldAt,
  ),
];

/// Favoritos de la maqueta `Favoritos` (HU-53): dos disponibles y uno agotado.
final List<FavoriteItem> _favoriteItems = [
  FavoriteItem(
    productId: 'set-dibujo',
    savedAt: _now.subtract(const Duration(hours: 1)),
    status: FavoriteStatus.available,
    product: const ProductSummary(
      id: 'set-dibujo',
      title: 'Set de dibujo técnico: escuadras y lápices',
      priceCents: 32000,
      stock: 2,
      photoUrl: 'asset:assets/products/set-dibujo.webp',
      condition: 'Nuevo',
      sellerName: 'Paola N.',
    ),
  ),
  FavoriteItem(
    productId: 'casio-991es',
    savedAt: _now.subtract(const Duration(hours: 2)),
    status: FavoriteStatus.available,
    product: const ProductSummary(
      id: 'casio-991es',
      title: 'Calculadora Casio fx-991ES Plus',
      priceCents: 45000,
      stock: 1,
      photoUrl: 'asset:assets/products/casio.webp',
      condition: 'Usado',
      sellerName: 'Valeria C.',
    ),
  ),
  FavoriteItem(
    productId: 'casio-lax',
    savedAt: _now.subtract(const Duration(hours: 3)),
    status: FavoriteStatus.soldOut,
    product: const ProductSummary(
      id: 'casio-lax',
      title: 'Calculadora Casio fx-82LA Plus',
      priceCents: 25000,
      stock: 0,
      photoUrl: 'asset:assets/products/casio-lax.webp',
      condition: 'Usado',
      sellerName: 'Diego H.',
    ),
  ),
];

/// La app con la vitrina de muestra, lista para tomar capturas.
class _Shot {
  new(this.tester, {required this.member, CatalogRepository? catalog})
    : catalog = catalog ?? DemoCatalogRepository(() => _now);

  final WidgetTester tester;
  final bool member;
  final CatalogRepository catalog;
  final auth = FakeAuthRepository(now: _now);
  final GlobalKey _boundary = GlobalKey();
  late ProviderContainer container;

  /// Con [wait] espera a que todo se acomode (sin el: estados que animan
  /// sin fin, como el esqueleto de carga).
  Future<void> open({bool wait = true}) async {
    final tokens = member
        ? SessionTokens(
            // Con forma de JWT: el chat sabe que mensajes son mios (HU-20).
            accessToken: jwtFor(myId),
            accessExpiresAt: _now.add(const Duration(minutes: 15)),
            refreshToken: 'refresh',
            profile: _ana,
          )
        : null;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: ProviderScope(
          overrides: [
            brandSplashEnabledProvider.overrideWithValue(false),
            catalogRepositoryProvider.overrideWithValue(catalog),
            favoritesRepositoryProvider.overrideWithValue(
              FakeFavoritesRepository(
                favorites: Favorites(items: _favoriteItems),
              ),
            ),
            authRepositoryProvider.overrideWithValue(auth),
            sessionApiProvider.overrideWithValue(FakeSessionApi()),
            clockProvider.overrideWithValue(() => _now),
            emailInboxProvider.overrideWithValue(_InboxStub()),
            listingsRepositoryProvider.overrideWithValue(
              FakeListingsRepository(
                range: const PriceRange(lowCents: 38000, highCents: 52000),
              )..own = _myListings,
            ),
            photoPickerProvider.overrideWithValue(_FilePicker()),
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(initial: _anaProfile)
                // Tarjeta de quien vende en `Producto` (HU-11) y cabecera de
                // `Perfil-vendedor` (HU-05).
                ..publicProfiles['demo-valeria-c'] = PublicProfile(
                  id: 'demo-valeria-c',
                  fullName: 'Valeria Cruz',
                  campusShortName: 'UTTT',
                  memberSince: DateTime(2025, 2, 15),
                  careerShortName: 'Arquitectura',
                  term: 8,
                  ratingAvg: 4.6,
                  ratingCount: 18,
                  sales: 15,
                )
                // `Perfil-vendedor` sin calificaciones (RN-26).
                ..publicProfiles['demo-diego-h'] = PublicProfile(
                  id: 'demo-diego-h',
                  fullName: 'Diego Hernández',
                  campusShortName: 'UTTT',
                  memberSince: DateTime(2024, 8, 20),
                  careerShortName: 'Ing. Civil',
                  term: 7,
                  ratingCount: 0,
                )
                // `Perfil-vendedor` sin publicaciones activas.
                ..publicProfiles['demo-paulina-r'] = PublicProfile(
                  id: 'demo-paulina-r',
                  fullName: 'Paulina Ruiz',
                  campusShortName: 'UTTT',
                  memberSince: DateTime(2025, 3, 10),
                  careerShortName: 'Diseño Industrial',
                  term: 5,
                  ratingAvg: 5,
                  ratingCount: 3,
                  sales: 2,
                ),
            ),
            themePreferenceRepositoryProvider.overrideWithValue(
              FakeThemePreferenceRepository(),
            ),
            statusRepositoryProvider.overrideWithValue(
              FakeStatusRepository([const ApiOnline(version: 'v1')]),
            ),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore(tokens)),
            initialSessionTokensProvider.overrideWithValue(tokens),
            chatRepositoryProvider.overrideWithValue(_chat),
            // HU-23: el pedido de la calculadora (`Pedido-pago`).
            orderRepositoryProvider.overrideWithValue(
              // Del mas viejo al mas nuevo: "Mis pedidos" de Perfil muestra
              // la Casio confirmada, el libro sin pago y el Arduino (HU-25).
              FakeOrderRepository(
                orders: [_order, _sale, _arduino, _algebra, _accepted],
              ),
            ),
            chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
            // HU-31: los avisos de `Notificaciones` (sin Firebase aqui).
            notificationRepositoryProvider.overrideWithValue(_notices),
            pushServiceProvider.overrideWithValue(
              FakePushService(available: false),
            ),
            // HU-32/33/34: la IA de cada escena (`_ai`, se ajusta en ella).
            agreementRepositoryProvider.overrideWithValue(_ai),
            aiNoticeStoreProvider.overrideWithValue(
              FakeAiNoticeStore(wasSeen: true),
            ),
            // HU-57: Diego bloqueado, como `APP.blocked` de la maqueta.
            reputationRepositoryProvider.overrideWithValue(
              FakeReputationRepository(
                blockedUsers: [
                  BlockedUser(
                    id: 'diego',
                    name: 'Diego Hernández',
                    blockedAt: _now,
                  ),
                ],
              ),
            ),
            // `Mis-solicitudes`: 2 activas y 4 cerradas (HU-13); el tablero
            // de `Se-busca` y `Se-busca-visitante` (HU-15).
            wantedRepositoryProvider.overrideWithValue(
              FakeWantedRepository(
                board: member ? _memberBoard : _visitorBoard,
                received: {'w1': _receivedOffers},
                mine: [
                  sampleWanted(offers: 3, neededBy: DateTime(2026, 10, 9)),
                  sampleWanted(id: 'w2', title: 'Bata de laboratorio talla M'),
                  for (var i = 3; i <= 6; i++)
                    sampleWanted(id: 'w$i', status: WantedStatus.closed),
                ],
              ),
            ),
          ],
          child: const MusubiApp(),
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    if (wait) {
      await settle();
    } else {
      await tester.pump(const Duration(milliseconds: 700));
      await _images();
      await tester.pump(const Duration(milliseconds: 700));
    }
  }

  Future<void> settle() async {
    await tester.pumpAndSettle();
    await _images();
    await tester.pumpAndSettle();
  }

  /// Las fotos se decodifican fuera del reloj falso de la prueba.
  Future<void> _images() async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        await precacheImage(image.image, element);
      }
    });
    await tester.pump();
  }

  Future<void> go(String location, {Object? extra}) async {
    container.read(routerProvider).go(location, extra: extra);
    await settle();
  }

  Future<void> tap(Finder finder) async {
    await tester.tap(finder.first, warnIfMissed: false);
    await settle();
  }

  Future<void> type(String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  Future<void> scroll(double offset) async {
    final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
    // Como el navegador: no pasa del final.
    state.position.jumpTo(
      offset.clamp(0, state.position.maxScrollExtent).toDouble(),
    );
    await tester.pump();
    await _images();
  }

  /// Caja de cada texto visible (en pt, como `getBoundingClientRect`).
  void printRects(String name) {
    for (final element in find.byType(RichText).evaluate()) {
      final box = element.renderObject! as RenderBox;
      if (!box.hasSize || !box.attached) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.bottom <= 0 || rect.top >= _height) continue;
      final text = (element.widget as RichText).text
          .toPlainText()
          .split('\n')
          .join(' ');
      // ignore: avoid_print, salida de la herramienta (no corre en la app).
      print(
        '$name | top ${rect.top.toStringAsFixed(3)} '
        'bottom ${rect.bottom.toStringAsFixed(3)} '
        'alto ${rect.height.toStringAsFixed(3)} '
        'x ${rect.left.toStringAsFixed(1)} | '
        '${text.characters.take(40)}',
      );
    }
  }

  Future<void> save(String name) async {
    if (_rects) printRects(name);
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }
}

typedef _Scene = Future<void> Function(_Shot shot);

/// Nombre → (con sesion, como llegar a la pantalla).
/// Elige una opcion de una hoja: se marca, se cierra a los 160 ms y la
/// maqueta abre lo siguiente 240 ms despues.
Future<void> _pick(_Shot s, String label) async {
  await s.tester.tap(find.text(label).last, warnIfMissed: false);
  await s.tester.pump(const Duration(milliseconds: 200));
  await s.settle();
  await s.tester.pump(const Duration(milliseconds: 300));
  await s.settle();
}

/// `chatMoreSheet` sobre `Chat-Valeria` (HU-28, HU-57).
Future<void> _chatMore(_Shot s) async {
  await s.go(AppRoutes.conversation('c1'));
  await s.tap(find.bySemanticsLabel('Más opciones'));
}

final Map<String, (bool, _Scene)> _scenes = {
  // HU-07: el menu de una publicacion en `Mis-productos` y "Editar
  // publicación" (`Vender-2` y `Vender-4` con las piezas sin cambiarse).
  'mis-productos-menu': (
    true,
    (s) async {
      await s.go(AppRoutes.myProducts);
      await s.tap(find.byKey(const Key('my-product-p-bata')));
    },
  ),
  'editar-publicacion': (
    true,
    (s) async {
      await s.go(AppRoutes.myProducts);
      await s.tap(find.byKey(const Key('my-product-p-bata')));
      await _pick(s, 'Editar');
    },
  ),
  'editar-publicacion-estado': (
    true,
    (s) async {
      await s.go(AppRoutes.myProducts);
      await s.tap(find.byKey(const Key('my-product-p-bata')));
      await _pick(s, 'Editar');
      await s.tap(find.text('Continuar'));
      await s.tap(find.text('Continuar'));
    },
  ),
  // HU-50: "Cambiar piezas" y "Reponer" en Agotados.
  'cambiar-piezas': (
    true,
    (s) async {
      await s.go(AppRoutes.myProducts);
      await s.tap(find.byKey(const Key('my-product-p-bata')));
      await _pick(s, 'Cambiar piezas');
    },
  ),
  'mis-productos-agotados': (
    true,
    (s) async {
      await s.go(AppRoutes.myProducts);
      await s.tap(find.text('Agotados (1)'));
    },
  ),
  // HU-08: "Vendidos" y el dialogo de "Marcar como vendido".
  'mis-productos-vendidos': (
    true,
    (s) async {
      await s.go(AppRoutes.myProducts);
      await s.tap(find.text('Vendidos (1)'));
    },
  ),
  'marcar-vendido': (
    true,
    (s) async {
      await s.go(AppRoutes.myProducts);
      await s.tap(find.byKey(const Key('my-product-p-bata')));
      await _pick(s, 'Marcar como vendido');
    },
  ),
  'chat-mas': (true, _chatMore),
  'chat-bloquear': (
    true,
    (s) async {
      await _chatMore(s);
      await _pick(s, 'Bloquear a Valeria');
    },
  ),
  'reportar': (
    true,
    (s) async {
      await _chatMore(s);
      await _pick(s, 'Reportar');
    },
  ),
  'reportar-detalle': (
    true,
    (s) async {
      await _chatMore(s);
      await _pick(s, 'Reportar');
      await _pick(s, 'Me pidió pagar fuera de Musubi');
      FocusManager.instance.primaryFocus?.unfocus();
      await s.settle();
    },
  ),
  'bloqueados': (
    true,
    (s) async {
      await s.go(AppRoutes.accountPrivacy);
      await s.tap(find.byKey(const Key('privacy-blocked')));
    },
  ),
  'chat-valeria': (true, (s) => s.go(AppRoutes.conversation('c1'))),
  'mensajes': (true, (s) => s.go(AppRoutes.messages)),
  'producto': (true, (s) => s.go(AppRoutes.product('casio-991es'))),
  'producto-visitante': (false, (s) => s.go(AppRoutes.product('casio-991es'))),
  'perfil-vendedor': (
    true,
    (s) => s.go(AppRoutes.sellerProfile('demo-valeria-c')),
  ),
  'perfil-vendedor-sin-calificaciones': (
    true,
    (s) => s.go(AppRoutes.sellerProfile('demo-diego-h')),
  ),
  'perfil-vendedor-vacio': (
    true,
    (s) => s.go(AppRoutes.sellerProfile('demo-paulina-r')),
  ),
  'inicio-visitante': (false, (s) async {}),
  'busqueda': (
    false,
    (s) async {
      await s.go(AppRoutes.search);
      await s.type('search-input', 'calculadora');
      await s.tester.testTextInput.receiveAction(TextInputAction.search);
      FocusManager.instance.primaryFocus?.unfocus();
      await s.settle();
    },
  ),
  'busqueda-vacia': (
    false,
    (s) async {
      await s.go(AppRoutes.search);
      await s.type('search-input', 'TI-84');
      await s.tester.testTextInput.receiveAction(TextInputAction.search);
      FocusManager.instance.primaryFocus?.unfocus();
      await s.settle();
    },
  ),
  'inicio-visitante-scroll1': (false, (s) => s.scroll(650)),
  'inicio-visitante-scroll2': (false, (s) => s.scroll(1300)),
  'inicio-visitante-scroll3': (false, (s) => s.scroll(5000)),
  'gate-guardar': (false, (s) => s.tap(find.byType(SaveButton))),
  'gate-campus': (false, (s) => s.tap(find.byKey(const Key('campus-chip')))),
  'gate-perfil': (false, (s) => s.tap(find.bySemanticsLabel('Perfil'))),
  'gate-mensajes': (false, (s) => s.tap(find.bySemanticsLabel('Mensajes'))),
  'gate-publicar': (false, (s) => s.tap(find.bySemanticsLabel('Publicar'))),
  'gate-yotengo': (
    false,
    (s) async {
      await s.scroll(1300);
      await s.tap(find.text('Yo tengo este producto'));
    },
  ),
  'filtro': (
    false,
    (s) async {
      await s.scroll(400);
      await s.tap(find.byKey(const Key('home-filter')));
    },
  ),
  'iniciar-sesion': (
    false,
    (s) async {
      await s.go(AppRoutes.signIn);
      await s.type('signin-email', 'ana.ramirez@uttt.edu.mx');
      await s.type('signin-password', 'musubi2025');
      FocusManager.instance.primaryFocus?.unfocus();
      await s.settle();
    },
  ),
  'iniciar-sesion-error': (
    false,
    (s) async {
      await s.go(AppRoutes.signIn);
      await s.type('signin-email', 'ana.ramirez@uttt.edu.mx');
      await s.type('signin-password', 'musubi2025');
      await s.tap(find.text('Iniciar sesión'));
      FocusManager.instance.primaryFocus?.unfocus();
      await s.settle();
    },
  ),
  'registro': (
    false,
    (s) async {
      await s.go(AppRoutes.signUp);
      await s.type('signup-email', 'ana.ramirez@uttt.edu.mx');
      await s.tester.pump(const Duration(milliseconds: 600));
      await s.settle();
      await s.type('signup-name', 'Ana Sofía Ramírez');
      await s.tap(find.byKey(const Key('signup-consent')));
      await s.type('signup-password', 'musubi2026');
      await s.settle();
    },
  ),
  'registro-error': (
    false,
    (s) async {
      await s.go(AppRoutes.signUp);
      await s.type('signup-email', 'ana.ramirez@gmail.com');
      await s.tester.pump(const Duration(milliseconds: 600));
      await s.settle();
      await s.type('signup-name', 'Ana Sofía Ramírez');
      await s.type('signup-password', 'musubi2026');
      await s.tap(find.byKey(const Key('signup-consent')));
      FocusManager.instance.primaryFocus?.unfocus();
      await s.settle();
    },
  ),
  'verificacion': (
    false,
    (s) async {
      await s.go(
        AppRoutes.verification,
        extra: Registration(
          email: _ana.email,
          codeExpiresAt: _now.add(const Duration(minutes: 10)),
          resendAvailableAt: _now.add(const Duration(seconds: 42)),
        ),
      );
      await s.type('verification-code', '4827');
      await s.settle();
    },
  ),
  'verificacion-lista': (
    false,
    (s) async {
      await s.go(AppRoutes.welcome, extra: _anaUser);
      await s.tester.pump(const Duration(seconds: 2));
    },
  ),
  'aviso-privacidad': (false, (s) => s.go(AppRoutes.privacy)),
  'inicio': (true, (s) async {}),
  'inicio-scroll': (true, (s) => s.scroll(5000)),
  'perfil': (true, (s) => s.tap(find.bySemanticsLabel('Perfil'))),
  'favoritos': (true, (s) => s.go(AppRoutes.favorites)),
  'ajustes': (true, (s) => s.go(AppRoutes.settings)),
  'privacidad': (true, (s) => s.go(AppRoutes.accountPrivacy)),
  'datos-personales': (
    true,
    (s) async {
      await s.go(AppRoutes.settings);
      await s.tap(find.byKey(const Key('settings-account')));
    },
  ),
  'correo': (
    true,
    (s) async {
      await s.go(AppRoutes.settings);
      await s.tap(find.byKey(const Key('settings-email')));
    },
  ),
  'cambiar-contrasena': (
    true,
    (s) async {
      await s.go(AppRoutes.settings);
      await s.tap(find.byKey(const Key('settings-password')));
      await s.tester.enterText(
        find.byKey(const Key('change-password-current')),
        'musubi2025',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await s.settle();
    },
  ),
  'publicar': (true, (s) => s.tap(find.text('Publicar'))),
  'vender-1': (true, (s) => _sellTo(s, 1)),
  'vender-2': (true, (s) => _sellTo(s, 2)),
  'vender-3': (true, (s) => _sellTo(s, 3)),
  'vender-4': (true, (s) => _sellTo(s, 4)),
  'vender-listo': (true, (s) => _sellTo(s, 5)),
  'necesidad-1': (true, (s) => _needTo(s, 1)),
  'necesidad-2': (true, (s) => _needTo(s, 2)),
  'necesidad-3': (true, (s) => _needTo(s, 3)),
  'necesidad-publicada': (true, (s) => _needTo(s, 4)),
  'mis-solicitudes': (true, (s) => s.go(AppRoutes.myWanted)),
  'mis-solicitudes-ofertas': (
    true,
    (s) async {
      await s.go(AppRoutes.myWanted);
      await s.scroll(5000);
    },
  ),
  // HU-14: "Cambiar" abre "Tu solicitud"; "Editar solicitud" con ofertas.
  'mis-solicitudes-gestionar': (
    true,
    (s) async {
      await s.go(AppRoutes.myWanted);
      await s.tap(find.byKey(const Key('my-wanted-change-button')));
    },
  ),
  'editar-solicitud': (
    true,
    (s) async {
      await s.go(AppRoutes.myWanted);
      await s.tap(find.byKey(const Key('my-wanted-change-button')));
      await s.tap(find.text('Editar solicitud'));
    },
  ),
  // HU-23: "Resumen del acuerdo" sin IA (como `Acuerdo-esperando`: falta la
  // fecha) y "Tu pedido" (`Pedido-pago`).
  'resumen-acuerdo': (
    true,
    (s) async {
      _ai
        ..current = null
        ..requestFailure = aiUnavailable;
      await s.go(AppRoutes.conversation('c1'));
      await s.tap(find.byKey(const Key('chat-summarize')));
      await s.tap(
        find.descendant(
          of: find.byKey(const Key('order-place')),
          matching: find.text('Agregar'),
        ),
      );
      await s.tap(find.byKey(const Key('order-point-biblioteca')));
      await s.tap(find.byKey(const Key('order-place-done')));
    },
  ),
  'pedido-pago': (true, (s) => s.go(AppRoutes.order('o1'))),
  // HU-24: quien vende acepta o rechaza ("Tu venta"), quien compra confirma la
  // entrega (`Pedido-entrega`) y el motivo de "Rechazar pedido".
  'tu-venta': (true, (s) => s.go(AppRoutes.order('o2'))),
  'pedido-entrega': (true, (s) => s.go(AppRoutes.order('o3'))),
  'mis-pedidos': (true, (s) => s.go(AppRoutes.myOrders)),
  'pedido-cancelar': (
    true,
    (s) async {
      await s.go(AppRoutes.order('o2'));
      await s.tap(find.byKey(const Key('order-cancel')));
    },
  ),
  // HU-31: `Notificaciones` (Hoy y Ayer, dos sin leer).
  'notificaciones': (true, (s) => s.go(AppRoutes.notifications)),
  // HU-32/33/34: la propuesta de la IA (`Acuerdo-esperando`, sin fecha) y el
  // acuerdo confirmado por los dos (`Acuerdo-confirmado`).
  'acuerdo-esperando': (
    true,
    (s) async {
      _ai
        ..current = null
        ..requestFailure = null
        ..proposal = sampleAgreement(priceCents: 50000);
      await s.go(AppRoutes.conversation('c1'));
      await s.tap(find.byKey(const Key('chat-summarize')));
    },
  ),
  'acuerdo-confirmado': (
    true,
    (s) async {
      _ai
        ..requestFailure = null
        ..current = sampleAgreement(
          priceCents: 50000,
          status: AgreementStatus.confirmed,
          deliveryAt: DateTime(2026, 10, 8, 13),
          buyerConfirmedAt: _now,
          sellerConfirmedAt: _now,
        );
      await s.go(AppRoutes.conversation('c1'));
      await s.tap(find.byKey(const Key('chat-open-agreement')));
    },
  ),
  'se-busca': (true, (s) => s.go(AppRoutes.wanted)),
  'se-busca-filtros': (
    true,
    (s) async {
      await s.go(AppRoutes.wanted);
      await s.tap(find.byKey(const Key('wanted-filter')));
    },
  ),
  'se-busca-lupa': (
    true,
    (s) async {
      await s.go(AppRoutes.wanted);
      await s.tap(find.byKey(const Key('wanted-search')));
    },
  ),
  'yo-tengo-vincular': (true, (s) => _offerTo(s, 1)),
  'yo-tengo-oferta': (true, (s) => _offerTo(s, 2)),
  'yo-tengo-enviada': (true, (s) => _offerTo(s, 3)),
  'se-busca-visitante': (false, (s) => s.go(AppRoutes.wanted)),
  'se-busca-visitante-scroll': (
    false,
    (s) async {
      await s.go(AppRoutes.wanted);
      await s.scroll(5000);
    },
  ),
  'cerrar-sesion': (
    true,
    (s) async {
      await s.go(AppRoutes.settings);
      await s.tap(find.bySemanticsLabel('Cerrar sesión'));
    },
  ),
};

/// Publicar → Vender-1…4 → Vender-listo con los datos del prototipo.
Future<void> _sellTo(_Shot s, int step) async {
  final tester = s.tester;
  Future<void> quiet() async {
    // Sin el aviso breve en la captura (la maqueta no lo muestra).
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
        .removeCurrentSnackBar();
    await s.settle();
  }

  // Las fotos se leen fuera del reloj falso: si `Image.file` empieza a
  // leerlas dentro de la prueba, la lectura nunca termina.
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final path in _photoFiles) {
      await precacheImage(FileImage(File(path)), context);
    }
  });
  await s.tap(find.text('Publicar'));
  await s.tap(find.byKey(const Key('publish-sell')));
  await s.tap(find.byKey(const Key('sell-gallery')));
  await quiet();
  if (step < 2) return;
  await s.tap(find.text('Continuar'));
  await s.type('sell-title', 'Calculadora científica Casio fx-991ES Plus');
  await s.type(
    'sell-description',
    'La usé un semestre para Cálculo y Física. Funciona perfecto, incluye su '
        'tapa y pilas nuevas. Tiene un rayón pequeño en la parte de atrás, se '
        've en la foto 3.',
  );
  await s.settle();
  if (step < 3) return;
  await s.tap(find.text('Continuar'));
  await s.type('sell-price', '450');
  await s.tap(find.byKey(const Key('sell-category-calculadoras')));
  FocusManager.instance.primaryFocus?.unfocus();
  await s.settle();
  if (step < 4) return;
  await s.tap(find.text('Continuar'));
  if (step < 5) return;
  await s.tap(find.byKey(const Key('sell-publish')));
}

/// Necesidad-1…3 → Necesidad-publicada con los datos del prototipo (HU-13).
/// "Yo tengo este producto" (HU-16): 1 vincular, 2 oferta directa y 3
/// enviada (con la bata, como la maqueta).
Future<void> _offerTo(_Shot s, int step) async {
  await s.go(AppRoutes.wanted);
  await s.tap(find.text('Yo tengo este producto'));
  await s.type(
    'offer-message',
    '¡Hola! Tengo una bata talla M casi nueva. Te la llevo al edificio de '
        'laboratorios.',
  );
  FocusManager.instance.primaryFocus?.unfocus();
  await s.settle();
  if (step == 2) {
    await s.tap(find.byKey(const ValueKey('segment-OfferKind.direct')));
    await s.type(
      'offer-description',
      'Bata blanca de algodón, talla M. La usé dos semestres, sin manchas.',
    );
    await s.type('offer-price', '280');
    FocusManager.instance.primaryFocus?.unfocus();
    await s.settle();
  }
  if (step == 3) await s.tap(find.byKey(const Key('offer-send')));
}

Future<void> _needTo(_Shot s, int step) async {
  final tester = s.tester;
  Future<void> calm() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 600));
    await s.settle();
  }

  await s.go(AppRoutes.need);
  await s.type('need-title', 'Calculadora Casio fx-991ES Plus');
  await s.tap(find.byKey(const Key('need-category-calculadoras')));
  await calm();
  if (step < 2) return;
  await s.tap(find.byKey(const Key('need-continue')));
  await s.type(
    'need-description',
    'La necesito para Cálculo Integral y Física. Puede ser usada si funciona '
        'bien y trae su tapa.',
  );
  for (final feature in [
    'Modelo fx-991ES Plus',
    'Con tapa',
    'Pantalla sin rayones',
  ]) {
    await s.type('need-feature', feature);
    await s.tap(find.byKey(const Key('need-feature-add')));
  }
  await calm();
  if (step < 3) return;
  await s.tap(find.byKey(const Key('need-details-continue')));
  await s.type('need-budget', '600');
  await s.tap(find.byKey(const Key('need-when-friday')));
  await calm();
  if (step < 4) return;
  await s.tap(find.byKey(const Key('need-publish')));
  await calm();
}

/// Escenas que necesitan otro catalogo (cargando o sin red).
final Map<String, (bool, CatalogRepository)> _states = {
  'inicio-cargando': (true, FakeCatalogRepository.pending()),
  'inicio-error': (
    true,
    FakeCatalogRepository([
      const ApiFailure(code: ApiFailure.networkOffline, message: 'Sin red.'),
    ]),
  ),
  'inicio-visitante-vacio': (false, FakeCatalogRepository()),
};

Future<void> _loadFonts() async {
  final loader = FontLoader(MusubiType.family);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
  }
  await loader.load();
}

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(_width * 3.0, _height * 3.0)
    ..devicePixelRatio = 3
    ..padding = const FakeViewPadding(top: 54 * 3, bottom: 24 * 3)
    ..viewPadding = const FakeViewPadding(top: 54 * 3, bottom: 24 * 3);
  if (_dark) {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
  }
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

bool _wanted(String name) => _only.isEmpty || _only.split(',').contains(name);

void main() {
  setUpAll(() async {
    await _loadFonts();
    final bytes = (await rootBundle.load('assets/products/casio.webp')).buffer
        .asUint8List();
    final dir = Directory.systemTemp.createTempSync('musubi-fotos-');
    for (var i = 1; i <= 3; i++) {
      _photoFiles.add(
        (File('${dir.path}/foto-$i.webp')..writeAsBytesSync(bytes)).path,
      );
    }
  });

  for (final MapEntry(key: name, value: (member, scene)) in _scenes.entries) {
    if (!_wanted(name)) continue;
    testWidgets(name, (tester) async {
      _phone(tester);
      debugDisableShadows = false;
      try {
        final shot = _Shot(tester, member: member);
        await shot.open();
        await scene(shot);
        await shot.save(name + (_dark ? '-dark' : ''));
      } finally {
        debugDisableShadows = true;
      }
    });
  }

  for (final MapEntry(key: name, value: (member, catalog)) in _states.entries) {
    if (!_wanted(name)) continue;
    testWidgets(name, (tester) async {
      _phone(tester);
      debugDisableShadows = false;
      try {
        final shot = _Shot(tester, member: member, catalog: catalog);
        await shot.open(wait: false);
        await shot.save(name + (_dark ? '-dark' : ''));
      } finally {
        debugDisableShadows = true;
      }
    });
  }
}
