import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  final String baseUrl;
  final AuthService _authService;

  ApiService({required this.baseUrl, required AuthService authService})
      : _authService = authService;

  Future<Map<String, String>> _headers({
    bool isMultipart = false,
    bool forceRefreshToken = false,
  }) async {
    final token = await _authService.getIdToken(forceRefresh: forceRefreshToken);
    return {
      if (!isMultipart) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, String>>> suggestOutfits({
    String style = 'Simple',
    int count = 3,
    String? seasonKey,
    List<String>? weatherTags,
  }) async {
    final headers = await _headers();
    final body = <String, dynamic>{
      'style': style,
      'count': count,
      if (seasonKey != null && seasonKey.isNotEmpty) 'season_key': seasonKey,
      if (weatherTags != null && weatherTags.isNotEmpty)
        'weather_tags': weatherTags,
    };
    final resp = await http.post(
      Uri.parse('$baseUrl/ai/suggest'),
      headers: headers,
      body: jsonEncode(body),
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

  /// Analyse une image de vêtement avec le backend IA et renvoie
  /// des attributs structurés (couleurs, catégorie, style, etc.).
  Future<Map<String, dynamic>> analyzeGarmentImage(
      Uint8List imageBytes, String filename) async {
    Future<http.Response> postAnalyze({required bool refreshToken}) async {
      final token = await _authService.getIdToken(forceRefresh: refreshToken);
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }
      final uri = Uri.parse('$baseUrl/ai/analyze-garment');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    var resp = await postAnalyze(refreshToken: false);
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      resp = await postAnalyze(refreshToken: true);
    }
    if (resp.statusCode != 200) {
      throw Exception('Erreur analyse IA: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Upload une image via l'API backend
  /// [imageBytes] : les bytes de l'image
  /// [filename] : le nom du fichier original
  /// [folder] : le dossier de stockage (garments, outfits, profiles, posts)
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String filename,
    required String folder,
    bool removeBackground = false,
  }) async {
    Future<http.Response> postUpload({required bool refreshToken}) async {
      final token = await _authService.getIdToken(forceRefresh: refreshToken);
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }
      final uri = Uri.parse('$baseUrl/upload/image').replace(
        queryParameters: {
          'folder': folder,
          'remove_bg': removeBackground.toString(),
        },
      );
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception(
            'Timeout: Le traitement de l\'image prend trop de temps. Vérifie que le backend est démarré et que rembg fonctionne correctement.',
          );
        },
      );
      return http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: Impossible de recevoir la réponse du serveur.');
        },
      );
    }

    try {
      var response = await postUpload(refreshToken: false);
      if (response.statusCode == 401 || response.statusCode == 403) {
        response = await postUpload(refreshToken: true);
      }

      if (response.statusCode != 200) {
        final errorBody = response.body;
        String errorMessage = 'Erreur upload: ${response.statusCode}';
        try {
          final errorData = jsonDecode(errorBody);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'] as String;
          } else {
            errorMessage = errorBody;
          }
        } catch (_) {
          errorMessage = errorBody.isNotEmpty ? errorBody : errorMessage;
        }
        throw Exception(errorMessage);
      }

      final data = jsonDecode(response.body);
      if (data['url'] == null) {
        throw Exception('Réponse invalide du serveur: URL manquante');
      }
      return data['url'] as String;
    } on http.ClientException {
      throw Exception(
        'Erreur de connexion: Impossible de contacter le serveur. Vérifie que le backend est démarré sur $baseUrl',
      );
    } catch (e) {
      if (e.toString().contains('Timeout')) {
        rethrow;
      }
      throw Exception('Erreur lors de l\'upload: ${e.toString()}');
    }
  }
}
