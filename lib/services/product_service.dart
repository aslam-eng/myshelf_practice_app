import 'dart:convert'; // jsonDecode

import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/product_page.dart';
import 'api_exception.dart';

class ProductService {
  // One place to change the time limit for every request.
  static const Duration _timeout = Duration(seconds: 10);

  // How many products one page holds.
  static const int pageSize = 12;

  // skip = how many products we already have (0 = first page).
  Future<ProductPage> fetchProducts({int skip = 0}) async {
    final url = Uri.parse(
      'https://dummyjson.com/products?limit=$pageSize&skip=$skip',
    );

    try {
      final response = await http.get(url).timeout(_timeout);

      // 404, 500, etc. -> error, NOT an empty list.
      if (response.statusCode != 200) {
        throw ApiException('Server error (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final products = data['products'] as List<dynamic>;

      final List<Product> productList = [];
      for (final item in products) {
        productList.add(Product.fromJson(Map<String, dynamic>.from(item)));
      }
      // total comes from the same response: {"products": [...], "total": 194, ...}
      return ProductPage(products: productList, total: data['total'] as int);
    } catch (e) {
      throw ApiException.from(e); // one place turns any error into a clean message
    }
  }

  // Sends a new product. Returns the id the server gives back.
  Future<int> addProduct({required String title, required double price}) async {
    final url = Uri.parse('https://dummyjson.com/products/add');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'title': title, 'price': price}),
          )
          .timeout(_timeout);

      // Any 2xx code means success (DummyJSON returns 201 Created).
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException('Server error (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['id'] as int;
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
