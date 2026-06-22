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
    _dio.options.headers['Content-Type'] = 'application/json';
    // 👇 Important: get raw string to avoid Dio's automatic parsing
    _dio.options.responseType = ResponseType.plain;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
        options: Options(responseType: ResponseType.plain),
      );

      // Check status code
      if (response.statusCode != 200) {
        throw Exception(
          'Server error (${response.statusCode}) – please check the URL or contact support.\n'
          'Response: ${response.data.toString().substring(0, 100)}...',
        );
      }

      // Try to parse the raw response
      final rawBody = response.data as String;
      dynamic parsed;
      try {
        parsed = jsonDecode(rawBody);
      } on FormatException {
        // Not JSON – show the raw message
        throw Exception(
          'Server returned HTML/plain text instead of JSON.\n'
          'Response start: ${rawBody.substring(0, 100)}...',
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