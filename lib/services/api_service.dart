import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();

  static const String baseUrl = 'https://sajhya.com/patient-app';

  Future<void> init() async {
    // Use in‑memory cookie jar for now
    final cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(cookieJar));

    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // 🔑 Add browser‑like headers to avoid bot protection
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json, text/plain, */*';
    _dio.options.headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 10; SM-G960F) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/89.0.4389.90 Mobile Safari/537.36';

    // Get raw text to inspect responses
    _dio.options.responseType = ResponseType.plain;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
        options: Options(
          // Ensure headers are sent with the request too
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; SM-G960F) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/89.0.4389.90 Mobile Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
          },
          responseType: ResponseType.plain,
        ),
      );

      // Check HTTP status
      if (response.statusCode != 200) {
        throw Exception(
          'Server error (${response.statusCode}) – please check the URL or contact support.',
        );
      }

      final rawBody = response.data as String;

      // 🔍 Detect HTML responses (bot verification or error pages)
      if (rawBody.trim().startsWith('<!DOCTYPE html>') ||
          rawBody.trim().startsWith('<html')) {
        // Try to extract the <title> for a more user‑friendly error
        String title = '';
        final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false)
            .firstMatch(rawBody);
        if (titleMatch != null) {
          title = titleMatch.group(1)?.trim() ?? '';
        }
        if (title.contains('Bot Verification') || title.contains('CAPTCHA')) {
          throw Exception(
            '🚫 Security check blocked the request.\n'
            'The server is asking for a bot verification (CAPTCHA).\n'
            'Please try again later or contact support.',
          );
        } else {
          throw Exception(
            '⚠️ Server returned an HTML page instead of JSON.\n'
            'Title: $title\n'
            'URL: ${_dio.options.baseUrl}/api/login/\n'
            'Response start: ${rawBody.substring(0, 200)}...',
          );
        }
      }

      // Try to parse JSON
      dynamic parsed;
      try {
        parsed = jsonDecode(rawBody);
      } on FormatException {
        throw Exception(
          'Invalid JSON from server.\n'
          'Response start: ${rawBody.length > 100 ? rawBody.substring(0, 100) : rawBody}',
        );
      }

      if (parsed is Map<String, dynamic>) {
        return parsed;
      } else {
        throw Exception('Unexpected data format: ${parsed.runtimeType}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorBody = e.response?.data;
        throw Exception('Network error: $errorBody');
      } else {
        throw Exception('No internet connection: ${e.message}');
      }
    }
  }
}