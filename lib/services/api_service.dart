import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://127.0.0.1:5001/project-30dd3c12-9d55-4261-bc5/us-central1';

  static Future<Map<String, dynamic>> getRecommendation(
    String prompt, {
    required String location,
    required double minPrice,
    required double maxPrice,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        'location': location,
        'minPrice': minPrice.round(),
        'maxPrice': maxPrice.round(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get recommendation: ${response.body}');
    }
  }
}