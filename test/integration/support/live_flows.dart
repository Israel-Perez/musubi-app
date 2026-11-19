import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

import 'live_api.dart';

/// Pasos que se repiten en varios flujos (02-10): publicar, abrir el chat y
/// hacer un pedido, siempre por los repositorios reales de la app.

/// "Vender": sube la foto y publica (HU-06).
Future<ProductSummary> publishProduct(
  LiveSession seller, {
  required String title,
  int priceCents = 45000,
  int quantity = 1,
  String category = 'calculadoras',
}) async {
  final listings = seller.read(listingsRepositoryProvider);
  final photo = await listings.uploadPhoto(livePhoto().path);
  return await listings.publish(
    NewListing(
      title: title,
      description: 'La usé un semestre. Entrego en la biblioteca.',
      category: category,
      priceCents: priceCents,
      condition: ProductCondition.used,
      usedDetail: UsedDetail.good,
      quantity: quantity,
      photoKeys: [photo.key],
    ),
  );
}

/// "Enviar mensaje" desde `Producto` (HU-20).
Future<Conversation> openChat(LiveSession buyer, String productId) =>
    buyer.read(chatRepositoryProvider).start(productId);

/// Mañana a las 13:00 (hora del campus): siempre dentro del horario.
DateTime tomorrowAtOne() {
  final now = DateTime.now().toUtc().subtract(const Duration(hours: 6));
  return DateTime.utc(now.year, now.month, now.day + 1, 19);
}

/// "Hacer pedido" desde el chat (HU-23).
Future<Order> placeOrder(LiveSession buyer, String conversationId) async {
  final orders = buyer.read(orderRepositoryProvider);
  final points = await orders.meetingPoints();
  return await orders.create(
    NewOrder(
      conversationId: conversationId,
      quantity: 1,
      meetingPoint: points.first.slug,
      deliveryAt: tomorrowAtOne(),
    ),
  );
}
