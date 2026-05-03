import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use this for production/any device:
  // flutter run --dart-define=API_BASE_URL=https://your-backend-url.com

  // For iOS simulator local testing:
  // flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-live-backend-url.com',
  );

  static Future<Map<String, dynamic>> getRecommendation(
    String prompt, {
    required String location,
    required double minPrice,
    required double maxPrice,
  }) async {
    final uri = Uri.parse('$baseUrl/recommend');

    debugPrint('🌐 Backend URL => $baseUrl');
    debugPrint('🌐 POST => $uri');

    try {
      final requestBody = {
        'prompt': prompt.trim(),
        'location': location,
        'minPrice': minPrice.round(),
        'maxPrice': maxPrice.round(),
      };

      debugPrint('📤 REQUEST => ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('📥 STATUS => ${response.statusCode}');
      debugPrint('📥 BODY => ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server error ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('❌ API ERROR => $e');
      throw Exception('Failed to connect to backend');
    }
  }
}