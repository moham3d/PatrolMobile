import 'package:dio/dio.dart';

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic data;
  
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.data,
  });
  
  /// Create ApiException from DioError
  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'CONNECTION_TIMEOUT',
        );
        
      case DioExceptionType.sendTimeout:
        return const ApiException(
          message: 'Request timeout. Please try again.',
          code: 'SEND_TIMEOUT',
        );
        
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Server response timeout. Please try again.',
          code: 'RECEIVE_TIMEOUT',
        );
        
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No internet connection. Please check your network.',
          code: 'CONNECTION_ERROR',
        );
        
      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Certificate error. Please check your connection.',
          code: 'BAD_CERTIFICATE',
        );
        
      case DioExceptionType.badResponse:
        return _handleResponseError(error);
        
      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled.',
          code: 'REQUEST_CANCELLED',
        );
        
      case DioExceptionType.unknown:
        return ApiException(
          message: 'An unexpected error occurred: ${error.message}',
          code: 'UNKNOWN_ERROR',
        );
    }
  }
  
  /// Handle HTTP response errors
  static ApiException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    
    switch (statusCode) {
      case 400:
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Invalid request',
          statusCode: statusCode,
          code: 'BAD_REQUEST',
          data: data,
        );
        
      case 401:
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Authentication failed',
          statusCode: statusCode,
          code: 'UNAUTHORIZED',
          data: data,
        );
        
      case 403:
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Access denied',
          statusCode: statusCode,
          code: 'FORBIDDEN',
          data: data,
        );
        
      case 404:
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Resource not found',
          statusCode: statusCode,
          code: 'NOT_FOUND',
          data: data,
        );
        
      case 422:
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Validation error',
          statusCode: statusCode,
          code: 'VALIDATION_ERROR',
          data: data,
        );
        
      case 429:
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Too many requests. Please try again later.',
          statusCode: statusCode,
          code: 'RATE_LIMIT_EXCEEDED',
          data: data,
        );
        
      case 500:
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Internal server error',
          statusCode: statusCode,
          code: 'INTERNAL_SERVER_ERROR',
          data: data,
        );
        
      case 502:
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Bad gateway',
          statusCode: statusCode,
          code: 'BAD_GATEWAY',
          data: data,
        );
        
      case 503:
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Service unavailable',
          statusCode: statusCode,
          code: 'SERVICE_UNAVAILABLE',
          data: data,
        );
        
      default:
        return ApiException(
          message: _extractErrorMessage(data) ?? 'An error occurred',
          statusCode: statusCode,
          code: 'HTTP_ERROR',
          data: data,
        );
    }
  }
  
  /// Extract error message from response data
  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    
    if (data is Map<String, dynamic>) {
      // Try different common error message fields
      return data['detail'] ?? 
             data['message'] ?? 
             data['error'] ?? 
             data['msg'];
    }
    
    if (data is String) {
      return data;
    }
    
    return null;
  }
  
  @override
  String toString() {
    return 'ApiException(message: $message, statusCode: $statusCode, code: $code)';
  }
}

/// Authentication specific exception
class AuthException extends ApiException {
  const AuthException({
    required super.message,
    super.statusCode,
    super.code,
    super.data,
  });
  
  factory AuthException.fromApiException(ApiException e) {
    return AuthException(
      message: e.message,
      statusCode: e.statusCode,
      code: e.code,
      data: e.data,
    );
  }
}

/// Network specific exception
class NetworkException extends ApiException {
  const NetworkException({
    required super.message,
    super.code,
  });
}

/// Emergency system specific exception
class EmergencyException extends ApiException {
  const EmergencyException({
    required super.message,
    super.statusCode,
    super.code,
    super.data,
  });
}