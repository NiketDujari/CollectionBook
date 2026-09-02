import 'package:hive/hive.dart';

class StorageService {

  static final Box box = Hive.box("collectionBook");

  static dynamic get(String key) {
    return box.get(key);
  }

  static Future<void> set(String key, dynamic value) async {
    await box.put(key, value);
  }

  static Future<void> remove(String key) async {
    await box.delete(key);
  }

  static Future<void> clear() async {
    await box.clear();
  }
}