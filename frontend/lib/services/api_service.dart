import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  final String baseUrl;
  final AuthService _authService;

  ApiService({required this.baseUrl, required AuthService authService})
      : _authService = authService;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, String>>> suggestOutfits({
    String style = 'Simple',
    int count = 3,
  }) async {
    final headers = await _headers();
    final resp = await http.post(
      Uri.parse('$baseUrl/ai/suggest'),
      headers: headers,
      body: jsonEncode({'style': style, 'count': count}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Erreur API: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body);
    final suggestions = (data['suggestions'] as List)
        .map((s) => Map<String, String>.from(s as Map))
        .toList();
    return suggestions;
  }
}
