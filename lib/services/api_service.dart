import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sprawl-petty-bakery.ngrok-free.dev',
  );

  static Future<Map<String, dynamic>> getRecommendation(
    String prompt, {
    required String location,
    required double minPrice,
    required double maxPrice,
    String city = '',
  }) async {
    final cleanPrompt = prompt.trim();

    if (cleanPrompt.isEmpty) {
      throw Exception('Please enter what you want to search for.');
    }

    final uri = Uri.parse('$baseUrl/recommend');

    final requestBody = {
      'prompt': cleanPrompt,
      'location': location,
      'city': city,
      'minPrice': minPrice.round(),
      'maxPrice': maxPrice.round(),
    };

    debugPrint('🌐 Backend URL: $baseUrl');
    debugPrint('📡 POST: $uri');
    debugPrint('📤 Body: ${jsonEncode(requestBody)}');

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Invalid response format from backend.');
      }

      final decodedBody = Map<String, dynamic>.from(decoded);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedBody;
      }

      throw Exception(
        decodedBody['error']?.toString() ?? 'Backend request failed.',
      );
    } catch (e) {
      debugPrint('❌ API ERROR: $e');

      final errorText = e.toString().replaceFirst('Exception: ', '');

      if (errorText.contains('Connection refused') ||
          errorText.contains('Failed host lookup') ||
          errorText.contains('SocketException')) {
        throw Exception(
          'Failed to connect to backend. Make sure ngrok and your Node server are running.',
        );
      }

      throw Exception(errorText);
    }
  }
}