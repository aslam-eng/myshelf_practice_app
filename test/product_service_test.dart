
import 'package:flutter_test/flutter_test.dart';
import 'package:my_product_shelf/services/product_service.dart';

void main() {
  test('fetches 12 products from DummyJSON', () async {
    final service = ProductService();

    final products = await service.fetchProducts();

    expect(products.length, 12);
  });
}
