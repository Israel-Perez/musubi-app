import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/domain/product_share.dart';

ProductDetail _detail({String status = 'active', int priceCents = 45000}) =>
    ProductDetail(
      id: '6716a0000000000000000099',
      title: 'Calculadora Casio fx-991ES Plus',
      description: 'La usé un semestre.',
      categoryName: 'Calculadoras',
      priceCents: priceCents,
      condition: 'used',
      stock: 1,
      status: status,
      photoUrls: const [],
      publishedAt: DateTime.utc(2026, 11, 6),
      sellerId: '6716a0000000000000000001',
      sellerName: 'Valeria C.',
    );

// HU-61: el enlace y el texto que se comparten.
void main() {
  test('el enlace es la landing con el id del producto', () {
    expect(
      ProductShare.link('6716a0000000000000000099'),
      'https://musubiapp.com.mx/p/6716a0000000000000000099',
    );
    // Un id raro no rompe la ruta.
    expect(ProductShare.link('a/b?c'), 'https://musubiapp.com.mx/p/a%2Fb%3Fc');
  });

  test('nombre, precio y enlace; nunca quien vende (RNF-05)', () {
    final shared = ProductShare.of(_detail(priceCents: 125050));

    expect(shared.subject, 'Calculadora Casio fx-991ES Plus');
    expect(
      shared.text,
      'Calculadora Casio fx-991ES Plus · \$1,250.50 en Musubi\n'
      'https://musubiapp.com.mx/p/6716a0000000000000000099',
    );
    expect(shared.text, isNot(contains('Valeria')));
    expect(shared.text, isNot(contains('6716a0000000000000000001')));
  });

  test('se comparte lo que esta en la vitrina; pausada o vendida no', () {
    expect(ProductShare.canShare(_detail()), isTrue);
    expect(ProductShare.canShare(_detail(status: 'soldOut')), isTrue);
    expect(ProductShare.canShare(_detail(status: 'hidden')), isFalse);
    expect(ProductShare.canShare(_detail(status: 'sold')), isFalse);
  });

  test('el prefijo es el mismo del intent-filter de Android', () {
    expect(ProductShare.pathPrefix, '/p/');
  });
}
