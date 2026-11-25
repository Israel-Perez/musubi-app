import 'package:musubi_app/core/platform/share_sheet.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';

/// El enlace para compartir un producto (HU-61).
///
/// `https://musubiapp.com.mx/p/{id}` lo atiende la landing (`musubi-landing`,
/// `worker/`): muestra la vista previa con Open Graph para WhatsApp y el botón
/// de Google Play. Con la app instalada, Android lo abre directo en el producto
/// (App Links: `/.well-known/assetlinks.json` de la landing y el
/// `intent-filter` de `AndroidManifest.xml`), y el router lo lleva a
/// `/producto/{id}`.
abstract final class ProductShare {
  static const site = 'https://musubiapp.com.mx';

  /// El prefijo de la ruta, el mismo del `intent-filter` y del router.
  static const pathPrefix = '/p/';

  static String link(String productId) =>
      '$site$pathPrefix${Uri.encodeComponent(productId)}';

  /// Solo se comparte lo que se ve en la vitrina: una publicacion pausada o
  /// vendida (que solo ve su dueno) mostraria "Ya no está disponible".
  static bool canShare(ProductDetail product) =>
      product.status == 'active' || product.status == 'soldOut';

  /// "Calculadora Casio · $450 en Musubi" y el enlace. Sin datos de quien
  /// vende: el enlace es solo el id (RNF-05).
  static ShareText of(ProductDetail product) => ShareText(
    subject: product.title,
    text:
        '${product.title} · ${formatPrice(product.priceCents)} en Musubi\n'
        '${link(product.id)}',
  );
}
