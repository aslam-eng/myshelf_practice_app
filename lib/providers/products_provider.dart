import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/product_service.dart';

// Owns Home's data: the products, loading / error state and the search text.
// The screen only DRAWS this state and calls the methods below.
class ProductsProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error; // null = no error
  String _searchText = '';

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchText => _searchText;

  // What the list shows: all products, filtered by the search text.
  List<Product> get visibleProducts => filter(_products);

  void setSearchText(String value) {
    _searchText = value;
    notifyListeners();
  }

  // Still used by HomeScreen; removed once Home switches to visibleProducts.
  List<Product> filter(List<Product> products) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products
        .where((p) => p.title.toLowerCase().contains(query))
        .toList();
  }

  // showLoader = false for pull-to-refresh (RefreshIndicator has its own spinner).
  Future<void> loadProducts({bool showLoader = true}) async {
    if (showLoader) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _products = await _service.fetchProducts(); // REPLACE, never duplicate
      _error = null;
    } catch (e) {
      if (_products.isEmpty) {
        _error = e.toString(); // nothing to show -> error page
      } else {
        rethrow; // keep old products; the screen shows a SnackBar
      }
    } finally {
      // Runs on success AND failure: loading always ends, screen redraws.
      _isLoading = false;
      notifyListeners();
    }
  }
}
