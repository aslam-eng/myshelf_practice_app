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

  // ---------- Pagination ----------
  int _total = 0; // how many products exist on the server
  bool _isLoadingMore = false; // a NEXT page is loading right now
  String? _loadMoreError; // set when a NEXT page failed

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchText => _searchText;
  bool get isLoadingMore => _isLoadingMore;
  String? get loadMoreError => _loadMoreError;
  bool get hasMore => _products.length < _total;

  // Load more only when NOT searching: search filters loaded products only
  // (API search comes in the next feature).
  bool get canLoadMore => hasMore && _searchText.trim().isEmpty;

  // What the list shows: all products, filtered by the search text.
  List<Product> get visibleProducts {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return _products;
    return _products
        .where((p) => p.title.toLowerCase().contains(query))
        .toList();
  }

  void setSearchText(String value) {
    _searchText = value;
    notifyListeners();
  }

  // showLoader = false for pull-to-refresh (RefreshIndicator has its own spinner).
  Future<void> loadProducts({bool showLoader = true}) async {
    if (showLoader) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final page = await _service.fetchProducts(); // first page (skip = 0)
      _products = page.products; // REPLACE, never duplicate
      _total = page.total;
      _error = null;
      _loadMoreError = null; // a fresh start: allow loading more again
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

  // Loads the NEXT page and ADDS it to the end of the list.
  // Called many times per second by the scroll listener: the guard
  // below makes sure only ONE request runs at a time.
  Future<void> loadMore() async {
    // Guard: one request at a time, not during the first load,
    // not after the last page, and not after a failure (user taps Retry).
    if (_isLoadingMore ||
        _isLoading ||
        !canLoadMore ||
        _loadMoreError != null) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners(); // bottom spinner

    try {
      // skip = how many we already have, so we never get the same ones twice.
      final page = await _service.fetchProducts(skip: _products.length);
      _products = [..._products, ...page.products]; // ADD, don't replace
      _total = page.total;
    } catch (e) {
      // Keep the products we have; stop auto-loading until Retry
      // (otherwise every scroll offline would fire another request).
      _loadMoreError = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Called by the Retry button at the bottom of the list.
  void retryLoadMore() {
    _loadMoreError = null;
    loadMore();
  }
}
