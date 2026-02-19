import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  final String baseUrl;
  final AuthService _authService;

  ApiService({required this.baseUrl, required AuthService authService})
      : _authService = authService;

  Future<Map<String, String>> _headers({bool isMultipart = false}) async {
    final token = await _authService.getIdToken();
    return {
      if (!isMultipart) 'Content-Type': 'application/json',
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

  /// Upload une image via l'API backend
  /// [imageBytes] : les bytes de l'image
  /// [filename] : le nom du fichier original
  /// [folder] : le dossier de stockage (garments, outfits, profiles, posts)
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String filename,
    required String folder,
  }) async {
    final token = await _authService.getIdToken();
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final uri = Uri.parse('$baseUrl/upload/image').replace(queryParameters: {'folder': folder});
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Erreur upload: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['url'] as String;
  }
}
