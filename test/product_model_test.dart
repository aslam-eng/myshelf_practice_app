
import 'package:flutter_test/flutter_test.dart';
import 'package:my_product_shelf/models/product.dart';

void main() {
  test('converts JSON into a Product', () {
    final json = {
      'id': 1,
      'title': 'Travel Mug',
      'category': 'Kitchen',
      'price': 19.99,
      'thumbnail': 'https://example.com/mug.jpg',
    };

    final product = Product.fromJson(json);

    expect(product.id, 1);
    expect(product.title, 'Travel Mug');
    expect(product.price, 19.99);
  });
}
