import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../services/storage_service.dart';

// Saved profile data: the display name (Home + Profile) and the photo path.
// Both are loaded at app start in main(), so they live here, not in setState.
class ProfileProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  String _name = '';
  String? _photoPath; // null = show the initials avatar

  String get name => _name;
  String? get photoPath => _photoPath;

  // Called once at app start.
  Future<void> load() async {
    _name = await _storage.loadName();
    final path = await _storage.loadPhotoPath();
    // The file may be gone (e.g. app data cleared): then show initials.
    _photoPath = (path != null && File(path).existsSync()) ? path : null;
    notifyListeners();
  }

  // Awaited by the Profile screen, so "Profile saved" only shows
  // after the name is really written to disk.
  // Disk first: if the write fails, _name keeps the old value,
  // so Home never shows a name that was not really saved.
  Future<void> saveName(String newName) async {
    final trimmed = newName.trim();
    await _storage.saveName(trimmed); // may throw -> lines below are skipped
    _name = trimmed;
    notifyListeners();
  }

  // Disk first (same rule as saveName): copy the file, save its path,
  // and only THEN update the screen.
  Future<void> savePhoto(String pickedPath) async {
    // 1. image_picker's file is in the CACHE folder, which Android may clean.
    //    Copy it into the app's PERMANENT documents folder.
    final dir = await getApplicationDocumentsDirectory();
    // A NEW name each time: Flutter caches images by path, so reusing
    // one name would keep showing the OLD photo.
    final newPath =
        '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(pickedPath).copy(newPath);

    // 2. Save the new path. May throw -> lines below are skipped.
    await _storage.savePhotoPath(newPath);

    // 3. Update the screen.
    final oldPath = _photoPath;
    _photoPath = newPath;
    notifyListeners();

    // 4. Delete the previous copy so old photos don't pile up on the phone.
    if (oldPath != null) {
      try {
        await File(oldPath).delete();
      } catch (_) {
        // Not important: the new photo is already saved and shown.
      }
    }
  }
}
