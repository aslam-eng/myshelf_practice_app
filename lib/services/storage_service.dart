import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class StorageService {
  // Key names in one place, so save and load never use different spellings.
  static const String _nameKey = 'display_name';
  static const String _savedProductsKey = 'saved_products';

  // ---------- Display name ----------
  Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  Future<String> loadName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? '';
  }

  // ---------- Saved products ----------
  // List<Product> -> List<Map> -> one JSON String -> disk
  Future<void> saveProducts(List<Product> products) async {
    final List<Map<String, dynamic>> jsonList = [];
    for (final product in products) {
      jsonList.add(product.toJson());
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedProductsKey, jsonEncode(jsonList));
  }

  // disk -> one JSON String -> List<Map> -> List<Product>
  Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? text = prefs.getString(_savedProductsKey);

    if (text == null) return []; // first launch: nothing saved yet

    try {
      final List<dynamic> decoded = jsonDecode(text);
      final List<Product> products = [];
      for (final item in decoded) {
        products.add(Product.fromJson(Map<String, dynamic>.from(item)));
      }
      return products;
    } on FormatException {
      return []; // text is not valid JSON
    } on TypeError {
      return []; // valid JSON, but the wrong shape
    }
  }
}
