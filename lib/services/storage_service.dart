import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../core/constants/storage_keys.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;

  StorageService(this._secureStorage);

  // ─── Secure Storage (Token / Sensitive) ────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: StorageKeys.authToken, value: token);
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: StorageKeys.authToken);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: StorageKeys.authToken);
  }

  Future<void> saveFcmToken(String token) async {
    await _secureStorage.write(key: StorageKeys.fcmToken, value: token);
  }

  Future<String?> getFcmToken() async {
    return _secureStorage.read(key: StorageKeys.fcmToken);
  }

  // ─── Hive Storage (Cache) ──────────────────────────────────────────────────

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final box = await _getSettingsBox();
    await box.put(StorageKeys.userData, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final box = await _getSettingsBox();
    final encoded = box.get(StorageKeys.userData) as String?;
    if (encoded == null) return null;
    return jsonDecode(encoded) as Map<String, dynamic>;
  }

  Future<void> saveTimetableCache(List<Map<String, dynamic>> data) async {
    final box = await _getTimetableBox();
    await box.put(StorageKeys.timetableCache, jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>?> getTimetableCache() async {
    final box = await _getTimetableBox();
    final encoded = box.get(StorageKeys.timetableCache) as String?;
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> saveHolidayCache(List<Map<String, dynamic>> data) async {
    final box = await _getSettingsBox();
    await box.put(StorageKeys.holidayCache, jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>?> getHolidayCache() async {
    final box = await _getSettingsBox();
    final encoded = box.get(StorageKeys.holidayCache) as String?;
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> saveString(String key, String value) async {
    final box = await _getSettingsBox();
    await box.put(key, value);
  }

  Future<String?> getString(String key) async {
    final box = await _getSettingsBox();
    return box.get(key) as String?;
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final settingsBox = await _getSettingsBox();
    final timetableBox = await _getTimetableBox();
    await settingsBox.clear();
    await timetableBox.clear();
  }

  Future<Box> _getSettingsBox() async {
    if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
      return Hive.box(StorageKeys.settingsBox);
    }
    return Hive.openBox(StorageKeys.settingsBox);
  }

  Future<Box> _getTimetableBox() async {
    if (Hive.isBoxOpen(StorageKeys.timetableBox)) {
      return Hive.box(StorageKeys.timetableBox);
    }
    return Hive.openBox(StorageKeys.timetableBox);
  }
}

// Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  return StorageService(secureStorage);
});
