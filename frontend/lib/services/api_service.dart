import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../l10n/api_error_l10n.dart';

class ApiException implements Exception {
  final String message;
  final String? errorCode;

  ApiException(this.message, {this.errorCode});

  @override
  String toString() => message;
}

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

  ApiException _apiException(String fallback, {String? body, int? statusCode}) {
    final code = body != null ? errorCodeFromResponseBody(body) : null;
    return ApiException(
      code != null ? code : (statusCode != null ? '$fallback: $statusCode' : fallback),
      errorCode: code,
    );
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
      throw _apiException('api_suggest_error', body: resp.body, statusCode: resp.statusCode);
    }
    final data = jsonDecode(resp.body);
    final suggestions = (data['suggestions'] as List)
        .map((s) => Map<String, String>.from(s as Map))
        .toList();
    return suggestions;
  }

  Future<Map<String, dynamic>> analyzeGarmentImage(
      Uint8List imageBytes, String filename) async {
    Future<http.Response> postAnalyze({required bool refreshToken}) async {
      final token = await _authService.getIdToken(forceRefresh: refreshToken);
      if (token == null) {
        throw ApiException('not_authenticated', errorCode: 'not_authenticated');
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
      throw _apiException('api_analyze_error', body: resp.body, statusCode: resp.statusCode);
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String filename,
    required String folder,
    bool removeBackground = false,
  }) async {
    Future<http.Response> postUpload({required bool refreshToken}) async {
      final token = await _authService.getIdToken(forceRefresh: refreshToken);
      if (token == null) {
        throw ApiException('not_authenticated', errorCode: 'not_authenticated');
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
        const Duration(seconds: 90),
        onTimeout: () {
          throw ApiException('upload_timeout', errorCode: 'upload_timeout');
        },
      );
      return http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw ApiException('upload_timeout', errorCode: 'upload_timeout');
        },
      );
    }

    bool shouldRetryUpload(int code) =>
        code == 401 ||
        code == 403 ||
        code == 408 ||
        code == 429 ||
        code == 500 ||
        code == 502 ||
        code == 503;

    try {
      http.Response? response;
      for (var attempt = 0; attempt < 3; attempt++) {
        final refreshFirst = attempt > 0;
        try {
          response = await postUpload(refreshToken: refreshFirst);
        } catch (e) {
          if (attempt < 2) {
            await Future.delayed(Duration(milliseconds: 350 * (attempt + 1)));
            continue;
          }
          rethrow;
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          response = await postUpload(refreshToken: true);
        }
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['url'] == null) {
            throw ApiException(
              'invalid_server_response',
              errorCode: 'invalid_server_response',
            );
          }
          return data['url'] as String;
        }
        if (shouldRetryUpload(response.statusCode) && attempt < 2) {
          await Future.delayed(Duration(milliseconds: 450 * (attempt + 1)));
          continue;
        }
        break;
      }

      final failed = response!;
      throw _apiException(
        'api_upload_error',
        body: failed.body,
        statusCode: failed.statusCode,
      );
    } on http.ClientException {
      throw ApiException('connection_error', errorCode: 'connection_error');
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('api_upload_error', errorCode: 'api_upload_error');
    }
  }
}
