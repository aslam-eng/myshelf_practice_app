import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

// Shared because Home ("Hello, name") and Profile (edit name) both use it.
// The photo preview is NOT here: only Profile uses it, so it stays in setState.
class ProfileProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  String _name = '';

  String get name => _name;

  // Called once at app start.
  Future<void> load() async {
    _name = await _storage.loadName();
    notifyListeners();
  }

  // Awaited by the Profile screen, so "Profile saved" only shows
  // after the name is really written to disk.
  Future<void> saveName(String newName) async {
    _name = newName.trim();
    notifyListeners();
    await _storage.saveName(_name);
  }
}
