
import 'package:flutter_test/flutter_test.dart';
import 'package:my_product_shelf/services/product_service.dart';

void main() {
  test('fetches the first page of products from DummyJSON', () async {
    final service = ProductService();

    final page = await service.fetchProducts();

    expect(page.products.length, ProductService.pageSize);
    expect(page.total, greaterThan(page.products.length));
  });
}
