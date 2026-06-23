// lib/services/api_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();
  late PersistCookieJar _cookieJar;
  bool _initialized = false;
  static const String baseUrl = 'https://sajhya.com/patient-app';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final appDocDir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${appDocDir.path}/.cookies/'),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));

    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.responseType = ResponseType.plain;
  }

  Future<void> _ensureCsrfToken() async {
    await _dio.get('/api/csrf/');
  }

  Future<String> _getCsrfToken() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    final csrf = cookies.firstWhere(
      (c) => c.name == 'csrftoken',
      orElse: () => Cookie('csrftoken', ''),
    );
    return csrf.value;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      await _ensureCsrfToken();
      final csrf = await _getCsrfToken();

      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
        options: Options(headers: {'X-CSRFToken': csrf}),
      );

      final rawBody = response.data as String;
      dynamic parsed;
      try {
        parsed = jsonDecode(rawBody);
      } catch (_) {
        throw Exception(
          'Server returned an HTML page.\n'
          'This might be a bot protection block.\n'
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

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/me/');
      final rawBody = response.data as String;
      return jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Not logged in');
    }
  }
  Future<String> debugCookies() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    if (cookies.isEmpty) return 'NO COOKIES FOUND';
    return cookies.map((c) => '${c.name}=${c.value}').join(', ');
  }

  Future<void> logout() async {
    try {
      final csrf = await _getCsrfToken();
      await _dio.post(
        '/api/logout/',
        options: Options(headers: {'X-CSRFToken': csrf}),
      );
    } catch (_) {
      // even if server call fails, clear cookies locally
    } finally {
      await _cookieJar.deleteAll();
    }
  }
}