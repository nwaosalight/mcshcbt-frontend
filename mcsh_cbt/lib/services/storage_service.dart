import 'package:hive/hive.dart';

class StorageService {
  static const String _boxName = 'app_storage';
  Box<dynamic>? _box;
  
  Future<void> init() async {
    // Open the box if it's not already open
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }
  
  String? readString(String key) {
    if (_box == null) {
      // Return null if box isn't initialized
      return null;
    }
    return _box!.get(key) as String?;
  }
  
  Future<void> saveString(String key, String value) async {
    if (_box == null) {
      // Initialize if not already done
      await init();
    }
    await _box!.put(key, value);
  }
  
  Future<void> delete(String key) async {
    if (_box == null) {
      // Initialize if not already done
      await init();
    }
    await _box!.delete(key);
  }
}