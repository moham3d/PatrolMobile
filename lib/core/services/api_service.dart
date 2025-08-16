import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../exceptions/api_exception.dart';

/// Core API service for PatrolShield backend communication
class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._internal();
  
  ApiService._internal();
  
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _authToken;
  
  /// Initialize the API service
  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Version': AppConstants.apiVersion,
      },
    ));
    
    // Load stored auth token
    _authToken = await _storage.read(key: AppConstants.authTokenKey);
    
    _setupInterceptors();
  }
  
  /// Setup Dio interceptors for authentication and error handling
  void _setupInterceptors() {
    // Request interceptor - add auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      
      onError: (error, handler) async {
        // Handle token expiry
        if (error.response?.statusCode == 401) {
          await _handleTokenExpiry();
        }
        
        // Convert DioError to custom ApiException
        final apiException = ApiException.fromDioError(error);
        handler.reject(DioException.badResponse(
          statusCode: error.response?.statusCode ?? 500,
          requestOptions: error.requestOptions,
          response: error.response,
          message: apiException.message,
        ));
      },
    ));
    
    // Logging interceptor for development
    if (const bool.fromEnvironment('DEBUG', defaultValue: false)) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
      ));
    }
  }
  
  /// Handle token expiry
  Future<void> _handleTokenExpiry() async {
    _authToken = null;
    await _storage.delete(key: AppConstants.authTokenKey);
    // TODO: Navigate to login screen or trigger refresh
  }
  
  /// Set authentication token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    await _storage.write(key: AppConstants.authTokenKey, value: token);
  }
  
  /// Clear authentication token
  Future<void> clearAuthToken() async {
    _authToken = null;
    await _storage.delete(key: AppConstants.authTokenKey);
  }
  
  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  
  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  
  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  
  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  
  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  
  /// Upload file
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        ...?data,
      });
      
      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => _authToken != null;
  
  /// Get current auth token
  String? get authToken => _authToken;
}