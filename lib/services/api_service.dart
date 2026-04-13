import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../utils/logger.dart';

class ApiService {
  static String get baseUrl => Env.baseUrl;

  static Future<Map<String, dynamic>> getRecommendation(
    String prompt, {
    required String location,
    required double minPrice,
    required double maxPrice,
  }) async {
    final uri = Uri.parse('$baseUrl/recommend');

    final body = {
      'prompt': prompt.trim(),
      'location': location,
      'minPrice': minPrice.round(),
      'maxPrice': maxPrice.round(),
    };

    try {
      AppLogger.log('Sending request to: $uri');
      AppLogger.log('Request body: ${jsonEncode(body)}');

      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      AppLogger.log('Response status: ${response.statusCode}');
      AppLogger.log('Response body: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        throw Exception('Invalid response format');
      } else {
        if (decoded is Map<String, dynamic>) {
          throw Exception(
            decoded['error']?.toString() ?? 'Server error occurred',
          );
        }
        throw Exception('Server error occurred');
      }
    } on TimeoutException {
      AppLogger.error('Request timed out');
      throw Exception('Request timed out. Please try again.');
    } on FormatException {
      AppLogger.error('Invalid JSON response');
      throw Exception('Invalid server response.');
    } on http.ClientException catch (e) {
      AppLogger.error('Client error: $e');
      throw Exception('Network error. Check your connection or server.');
    } catch (e) {
      AppLogger.error('ApiService error: $e');
      throw Exception(e.toString());
    }
  }
}