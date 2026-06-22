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
    _dio.options.responseType = ResponseType.plain;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error (${response.statusCode}) – please check the URL or contact support.\n'
          'Response: ${response.data.toString().substring(0, 100)}...',
        );
      }

      final rawBody = response.data as String;
      dynamic parsed;
      try {
        parsed = jsonDecode(rawBody);
      } on FormatException {
        // ✅ ADDED: show URL and full 300 chars of response
        throw Exception(
          'HTML instead of JSON.\n'
          'URL: ${_dio.options.baseUrl}/api/login/\n'
          'Response:\n${rawBody.length > 300 ? rawBody.substring(0, 300) : rawBody}',
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