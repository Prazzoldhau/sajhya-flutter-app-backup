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
    final cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(cookieJar));
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // ✅ Exactly the same as your working version
    _dio.options.headers['Content-Type'] = 'application/json';
    // Do NOT add extra headers like Accept or User-Agent
    // Do NOT set responseType – keep default (json)
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
      );

      // If response is a Map, return it (normal case)
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      
      // If it's a String (maybe a JSON string), parse it
      if (response.data is String) {
        try {
          return jsonDecode(response.data) as Map<String, dynamic>;
        } catch (_) {
          // Not valid JSON – probably HTML
          throw Exception(
            'Server returned an HTML page.\n'
            'This might be a temporary issue or a bot protection.\n'
            'Please try again later or contact support.',
          );
        }
      }

      // Unexpected type
      throw Exception('Unexpected response format: ${response.data.runtimeType}');
    } on DioException catch (e) {
      if (e.response != null) {
        // Server responded with an error status
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['error'] ?? 'Login failed');
        } else {
          throw Exception('Login failed (${e.response?.statusCode})');
        }
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }
}