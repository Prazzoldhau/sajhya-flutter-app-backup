// import 'package:dio/dio.dart';
// import 'package:dio_cookie_manager/dio_cookie_manager.dart';
// import 'package:cookie_jar/cookie_jar.dart';

// class ApiService {
//   static final ApiService _instance = ApiService._internal();
//   factory ApiService() => _instance;
//   ApiService._internal();

//   final Dio _dio = Dio();

//   // ✅ CHANGE THIS TO YOUR LIVE SERVER URL
//   static const String baseUrl = 'https://sajhya.com/patient-app';

//   Future<void> init() async {
//     final cookieJar = CookieJar();
//     _dio.interceptors.add(CookieManager(cookieJar));
//     _dio.options.baseUrl = baseUrl;
//     _dio.options.connectTimeout = const Duration(seconds: 10);
//     _dio.options.receiveTimeout = const Duration(seconds: 10);
//     _dio.options.headers['Content-Type'] = 'application/json';
//   }

//   Future<Map<String, dynamic>> login(String username, String password) async {
//     try {
//       final response = await _dio.post(
//         '/api/login/',
//         data: {
//           'username': username,
//           'password': password,
//         },
//       );
//       return response.data;
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw Exception(e.response?.data['error'] ?? 'Login failed');
//       } else {
//         throw Exception('Network error: ${e.message}');
//       }
//     }
//   }
// }
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
    _dio.options.responseType = ResponseType.json; // ✅ force JSON parsing
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
        options: Options(responseType: ResponseType.json), // ✅ explicit
      );

      // ✅ Handle if response is a raw JSON string
      dynamic data = response.data;
      if (data is String) {
        data = jsonDecode(data);
      }
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
      return data;
    } on DioException catch (e) {
      if (e.response != null) {
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