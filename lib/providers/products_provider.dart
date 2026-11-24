import 'dart:async'; // Timer

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

  // ---------- Search ----------
  String _searchText = ''; // what is in the search box right now
  String _activeQuery = ''; // the query the CURRENT list belongs to
  Timer? _debounce; // waits until the user stops typing

  // ---------- Pagination ----------
  int _total = 0; // how many products match on the server
  bool _isLoadingMore = false; // a NEXT page is loading right now
  String? _loadMoreError; // set when a NEXT page failed

  // ---------- Stale responses ----------
  // Every new list load takes the next "ticket". When an answer arrives,
  // it is only used if its ticket is still the latest one.
  int _requestId = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchText => _searchText;
  String get activeQuery => _activeQuery;
  int get total => _total;
  bool get isLoadingMore => _isLoadingMore;
  String? get loadMoreError => _loadMoreError;
  bool get hasMore => _products.length < _total;

  // What the list shows. The SERVER already searched, so no local filter.
  List<Product> get visibleProducts => _products;

  // Called on every letter typed. Debounce: each letter cancels the
  // previous timer, so only a 400 ms pause sends ONE request.
  void setSearchText(String value) {
    _searchText = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), loadProducts);
  }

  // Loads the FIRST page for the current search text.
  // showLoader = true : app start, Retry, new search -> clear and show spinner.
  // showLoader = false: pull-to-refresh -> keep the list, SnackBar on failure.
  Future<void> loadProducts({bool showLoader = true}) async {
    final requestId = ++_requestId; // take a ticket
    _activeQuery = _searchText.trim();
    final query = _activeQuery; // remember it: the user may keep typing

    if (showLoader) {
      _isLoading = true;
      _error = null;
      _products = []; // old results don't belong to the new query
      _total = 0;
      notifyListeners();
    }

    try {
      final page = await _service.fetchProducts(query: query);
      if (requestId != _requestId) return; // a newer load started: ignore
      _products = page.products; // REPLACE, never duplicate
      _total = page.total;
      _error = null;
      _loadMoreError = null; // a fresh start: allow loading more again
    } catch (e) {
      if (requestId != _requestId) return; // outdated failure: ignore too
      if (_products.isEmpty) {
        _error = e.toString(); // nothing to show -> error page
      } else {
        rethrow; // refresh failed: keep the products; the screen shows a SnackBar
      }
    } finally {
      // Only the LATEST load may end the loading state: an outdated one
      // finishing must not hide the spinner of the newer one.
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Loads the NEXT page and ADDS it to the end of the list.
  // Called many times per second by the scroll listener: the guard
  // below makes sure only ONE request runs at a time.
  Future<void> loadMore() async {
    // Guard: one request at a time, not during the first load,
    // not after the last page, and not after a failure (user taps Retry).
    if (_isLoadingMore || _isLoading || !hasMore || _loadMoreError != null) {
      return;
    }

    // Use the CURRENT ticket (don't take a new one): if a new search or
    // refresh starts while this page loads, this page is outdated.
    final requestId = _requestId;
    _isLoadingMore = true;
    notifyListeners(); // bottom spinner

    try {
      // skip = how many we already have, so we never get the same ones twice.
      // _activeQuery (not _searchText): the page must match the list on screen,
      // even if the user has typed more letters that are not searched yet.
      final page = await _service.fetchProducts(
        skip: _products.length,
        query: _activeQuery,
      );
      if (requestId != _requestId) return; // list was replaced: ignore
      _products = [..._products, ...page.products]; // ADD, don't replace
      _total = page.total;
    } catch (e) {
      if (requestId != _requestId) return;
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

  // We created the Timer, so we cancel it (same rule as controllers).
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
