/// API service for communicating with the Price Ninja backend.
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import '../models/product.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[API] $obj'),
    // Auth token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              // Keep X-User-Id for backwards compatibility on backend temporarily
              options.headers['X-User-Id'] = user.uid;
            }
          }
        } catch (e) {
          print('[AuthInterceptor] Error fetching token: $e');
        }
        return handler.next(options);
      },
    ));
  }

  // ─────────── Products ───────────

  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/api/products');
      final data = response.data['data'] as List? ?? [];
      return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Product> getProduct(String id) async {
    try {
      final response = await _dio.get('/api/products/$id');
      return Product.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Product> addProduct({
    required String url,
    String? name,
    double targetPrice = 0,
    bool emailEnabled = true,
    bool whatsappEnabled = false,
    String emailAddress = '',
    String whatsappNumber = '',
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _dio.post('/api/products/add', data: {
        'url': url,
        'name': name,
        'target_price': targetPrice,
        'email_enabled': emailEnabled,
        'whatsapp_enabled': whatsappEnabled,
        'email_address': emailAddress,
        'whatsapp_number': whatsappNumber,
        'expires_at': expiresAt?.toIso8601String(),
      });
      return Product.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put('/api/products/$id', data: updates);
      return Product.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _dio.delete('/api/products/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────── Price History ───────────

  Future<Map<String, dynamic>> getPriceHistory(
    String productId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/api/products/$productId/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPriceTrend(
    String productId, {
    int limit = 30,
  }) async {
    try {
      final response = await _dio.get(
        '/api/products/$productId/trend',
        queryParameters: {'limit': limit},
      );
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPrediction(String productId, {int days = 7}) async {
    try {
      final response = await _dio.get(
        '/api/products/$productId/prediction',
        queryParameters: {'days': days},
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────── Scraping ───────────

  Future<Map<String, dynamic>> scrapeAll() async {
    try {
      final response = await _dio.post('/api/scrape/now');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> scrapeProduct(String productId) async {
    try {
      final response = await _dio.post('/api/scrape/$productId');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────── Alerts ───────────

  Future<bool> sendTestAlert({
    required String alertType,
    String? productId,
    String? emailAddress,
    String? whatsappNumber,
  }) async {
    try {
      final response = await _dio.post('/api/alerts/test', data: {
        'alert_type': alertType,
        'product_id': productId,
        'email_address': emailAddress,
        'whatsapp_number': whatsappNumber,
      });
      return response.data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<List<AlertRecord>> getAlertHistory({int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/api/alerts/history',
        queryParameters: {'limit': limit},
      );
      final data = response.data['data'] as List? ?? [];
      return data.map((e) => AlertRecord.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAlertStatus() async {
    try {
      final response = await _dio.get('/api/alerts/status');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────── Health ───────────

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────── Error Handling ───────────

  Exception _handleError(Object e) {
    if (e is DioException) {
      final message = e.response?.data?['detail'] ??
          e.response?.data?['message'] ??
          e.message ??
          'Network error';
      return Exception(message);
    }
    return Exception('$e');
  }
}
