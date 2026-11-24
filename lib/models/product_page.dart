import 'product.dart';

// ONE page of products from the API, plus how many exist on the server.
// total lets the provider know when to stop: hasMore = loaded < total.
class ProductPage {
  final List<Product> products;
  final int total;

  const ProductPage({required this.products, required this.total});
}
