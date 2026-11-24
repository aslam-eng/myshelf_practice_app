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
  // Disk first (same rule as ProfileProvider): build a COPY, write it,
  // and only then change _saved. If the write throws, nothing changed,
  // so there is nothing to undo; the error goes up to the button.
  Future<void> toggle(Product product) async {
    final newList = isSaved(product.id)
        ? _saved.where((p) => p.id != product.id).toList() // remove
        : [..._saved, product]; // add

    await _storage.saveProducts(newList); // may throw -> lines below skipped

    _saved
      ..clear()
      ..addAll(newList);
    notifyListeners(); // every listening screen updates
  }
}
