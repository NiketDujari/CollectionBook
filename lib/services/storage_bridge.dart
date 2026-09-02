import 'dart:convert';

class StorageBridge {

  static Map<String, dynamic> decode(String message) {
    return jsonDecode(message);
  }

}