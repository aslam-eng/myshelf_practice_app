import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/storage_service.dart';

class FavouritesProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  // The ONE shared list. Private (_) so only this class can change it.
  final List<Product> _saved = [];

  // Screens can READ the list, but cannot add/remove directly
  // (that would skip notifyListeners and screens would not update).
  List<Product> get saved => List.unmodifiable(_saved);

  int get count => _saved.length;

  // Compare by id: after a refresh the API returns NEW objects
  // for the same product, but the id stays the same.
  bool isSaved(int id) {
    return _saved.any((product) => product.id == id);
  }

  // Called once at app start: loads favourites from the phone.
  Future<void> load() async {
    final products = await _storage.loadProducts();
    _saved
      ..clear()
      ..addAll(products);
    notifyListeners();
  }

  // Save if not saved, remove if already saved.
  void toggle(Product product) {
    if (isSaved(product.id)) {
      _saved.removeWhere((p) => p.id == product.id);
    } else {
      _saved.add(product);
    }
    notifyListeners(); // 1. update every listening screen instantly
    _storage.saveProducts(_saved); // 2. then write to disk in the background
  }
}
