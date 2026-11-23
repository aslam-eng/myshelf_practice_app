import 'package:flutter/foundation.dart';

import '../models/product.dart';

class ProductsProvider extends ChangeNotifier {
  String _searchText = '';

  String get searchText => _searchText;

  void setSearchText(String value) {
    _searchText = value;
    notifyListeners();
  }

  List<Product> filter(List<Product> products) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products
        .where((p) => p.title.toLowerCase().contains(query))
        .toList();
  }
}
