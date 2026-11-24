
import 'package:flutter_test/flutter_test.dart';
import 'package:my_product_shelf/services/product_service.dart';

void main() {
  test('fetches the first page of products from DummyJSON', () async {
    final service = ProductService();

    final page = await service.fetchProducts();

    expect(page.products.length, ProductService.pageSize);
    expect(page.total, greaterThan(page.products.length));
  });

  test('searches products on DummyJSON', () async {
    final service = ProductService();

    final page = await service.fetchProducts(query: 'phone');

    expect(page.products, isNotEmpty);
    // The server searched ALL products, so total is the number of matches,
    // not the 194 products of the whole catalogue.
    expect(page.total, lessThan(194));
  });
}
