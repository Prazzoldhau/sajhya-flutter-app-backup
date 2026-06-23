// lib/services/api_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';          // ✅ main import (includes PersistCookieJar)
import 'package:path_provider/path_provider.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();
  static const String baseUrl = 'https://sajhya.com/patient-app';

  Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(
      storage: FileStorage('${appDocDir.path}/.cookies/'), // cookies saved to disk
    );
    _dio.interceptors.add(CookieManager(cookieJar));

    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.responseType = ResponseType.plain; // raw string, we'll parse manually
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
      );

      final rawBody = response.data as String;
      dynamic parsed;
      try {
        parsed = jsonDecode(rawBody);
      } catch (_) {
        throw Exception(
          'Server returned an HTML page.\n'
          'This might be a temporary issue or a bot protection.\n'
          'Please try again later or contact support.',
        );
      }

      if (parsed is Map<String, dynamic>) {
        return parsed;
      } else {
        throw Exception('Unexpected response format: ${parsed.runtimeType}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Login failed (${e.response?.statusCode})');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  // Used by SplashScreen to check if user is already logged in
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/me/');  // adjust endpoint if needed
      final rawBody = response.data as String;
      return jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Not logged in');
    }
  }
}