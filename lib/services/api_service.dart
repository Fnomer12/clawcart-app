import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  /// 🔥 CHANGE THIS AFTER DEPLOYMENT
  /// Local testing (ONLY for emulator/dev)
  static const String _localUrl = 'http://10.0.2.2:3000'; // Android emulator
  static const String _webLocalUrl = 'http://127.0.0.1:3000'; // Web/iOS local

  /// 🌍 PRODUCTION URL (REPLACE THIS)
  static const String _prodUrl = 'https://your-backend.onrender.com';

  /// Automatically switch based on environment
  static String get baseUrl {
    if (kDebugMode) {
      // 👇 Handles emulator vs web
      if (kIsWeb) return _webLocalUrl;
      return _localUrl;
    }
    return _prodUrl;
  }

  static Future<Map<String, dynamic>> getRecommendation(
    String prompt, {
    required String location,
    required double minPrice,
    required double maxPrice,
  }) async {
    final uri = Uri.parse('$baseUrl/recommend');

    debugPrint('🌐 POST => $uri');

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'prompt': prompt.trim(),
              'location': location,
              'minPrice': minPrice.round(),
              'maxPrice': maxPrice.round(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 STATUS => ${response.statusCode}');
      debugPrint('📥 BODY => ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid server response format');
      }

      return decoded;
    } catch (e) {
      debugPrint('❌ ApiService error: $e');
      rethrow;
    }
  }
}