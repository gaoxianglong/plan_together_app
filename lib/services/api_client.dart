import 'dart:async';
import 'dart:convert';
import 'dart:ui' show VoidCallback;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';

/// API 响应结构（对应后端统一响应格式）
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final String? traceId;
  final int? timestamp;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.traceId,
    this.timestamp,
  });

  bool get isSuccess => code == 0;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      traceId: json['traceId'] as String?,
      timestamp: json['timestamp'] as int?,
    );
  }
}

/// Token 刷新回调（用于通知 AuthService 更新本地存储）
typedef TokenRefreshCallback = Future<void> Function(
  String accessToken,
  String refreshToken,
);

/// API 客户端服务
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _uuid = const Uuid();
  String? _accessToken;
  String? _refreshToken;
  
  /// 401 未授权回调（用于跳转登录页）
  VoidCallback? _onUnauthorized;
  
  /// Token 刷新成功回调（用于更新本地存储）
  TokenRefreshCallback? _onTokenRefreshed;
  
  /// 是否正在刷新 Token（防止并发刷新）
  bool _isRefreshing = false;
  
  /// 等待刷新完成的 Completer 列表
  final List<Completer<bool>> _refreshWaiters = [];

  /// 设置 401 未授权回调
  void setOnUnauthorized(VoidCallback callback) {
    _onUnauthorized = callback;
  }
  
  /// 设置 Token 刷新成功回调
  void setOnTokenRefreshed(TokenRefreshCallback callback) {
    _onTokenRefreshed = callback;
  }

  /// 设置 Token
  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// 清除 Token
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// 获取 Access Token
  String? get accessToken => _accessToken;

  /// 获取 Refresh Token
  String? get refreshToken => _refreshToken;

  /// 生成请求 ID（用于幂等）
  String generateRequestId() => _uuid.v4();
  
  /// 处理 401 未授权（刷新失败后调用）
  void _handleUnauthorized() {
    if (_onUnauthorized != null) {
      clearTokens();
      _onUnauthorized!();
    }
  }
  
  /// 刷新 Access Token
  /// 返回 true 表示刷新成功，false 表示刷新失败
  Future<bool> _refreshAccessToken() async {
    // 如果没有 refresh token，直接返回失败
    if (_refreshToken == null) {
      return false;
    }
    
    // 如果已经在刷新中，等待刷新完成
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _refreshWaiters.add(completer);
      return completer.future;
    }
    
    _isRefreshing = true;
    
    try {
      final url = Uri.parse('${ApiConfig.apiPrefix}/auth/refresh');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      
      if (response.body.isEmpty) {
        _notifyRefreshWaiters(false);
        return false;
      }
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final code = jsonBody['code'] as int;
      
      if (code == 0 && jsonBody['data'] != null) {
        // 刷新成功，更新 Token
        final data = jsonBody['data'] as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;
        
        _accessToken = newAccessToken;
        _refreshToken = newRefreshToken;
        
        // 通知 AuthService 更新本地存储
        if (_onTokenRefreshed != null) {
          await _onTokenRefreshed!(newAccessToken, newRefreshToken);
        }
        
        _notifyRefreshWaiters(true);
        return true;
      } else {
        // 刷新失败（refresh_token 也过期了）
        _notifyRefreshWaiters(false);
        return false;
      }
    } catch (e) {
      _notifyRefreshWaiters(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
  
  /// 通知所有等待刷新的请求
  void _notifyRefreshWaiters(bool success) {
    for (final completer in _refreshWaiters) {
      completer.complete(success);
    }
    _refreshWaiters.clear();
  }
  
  /// 标记是否正在进行重试（防止无限重试）
  bool _isRetrying = false;
  
  /// 处理 Token 刷新并重试请求
  /// 返回重试后的响应，如果不需要重试或重试失败则返回 null
  Future<ApiResponse<T>?> _handleTokenRefreshAndRetry<T>(
    Future<ApiResponse<T>> Function() retryRequest,
  ) async {
    // 如果已经在重试中，不再重试
    if (_isRetrying) {
      return null;
    }
    
    // 尝试刷新 Token
    final refreshSuccess = await _refreshAccessToken();
    if (refreshSuccess) {
      // 刷新成功，重试原请求
      _isRetrying = true;
      try {
        return await retryRequest();
      } finally {
        _isRetrying = false;
      }
    } else {
      // 刷新失败，跳转登录页
      _handleUnauthorized();
      return null;
    }
  }

  /// 构建请求头
  Map<String, String> _buildHeaders({
    bool requireAuth = false,
    bool idempotent = false,
    String? requestId,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (idempotent) {
      headers['X-Request-Id'] = requestId ?? generateRequestId();
    }

    return headers;
  }

  /// POST 请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
    bool idempotent = false,
    String? requestId,
    T? Function(dynamic)? fromJsonT,
  }) async {
    final url = Uri.parse('${ApiConfig.apiPrefix}$path');
    final headers = _buildHeaders(
      requireAuth: requireAuth,
      idempotent: idempotent,
      requestId: requestId,
    );

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      // 解析响应体
      if (response.body.isEmpty) {
        return ApiResponse(
          code: response.statusCode,
          message: 'Empty response',
        );
      }

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<T>.fromJson(jsonBody, fromJsonT);
      
      // 检测 401 未授权，尝试刷新 Token 并重试
      if (apiResponse.code == 401 && requireAuth) {
        final retryResponse = await _handleTokenRefreshAndRetry<T>(
          () => post<T>(
            path,
            body: body,
            requireAuth: requireAuth,
            idempotent: idempotent,
            requestId: requestId,
            fromJsonT: fromJsonT,
          ),
        );
        if (retryResponse != null) {
          return retryResponse;
        }
      }
      
      return apiResponse;
    } on FormatException catch (e) {
      // JSON 解析错误
      return ApiResponse(
        code: -2,
        message: 'Response parse error: ${e.message}',
      );
    } catch (e) {
      // 网络错误或超时
      return ApiResponse(
        code: -1,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// GET 请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    bool requireAuth = true,
    T? Function(dynamic)? fromJsonT,
  }) async {
    var url = Uri.parse('${ApiConfig.apiPrefix}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    final headers = _buildHeaders(requireAuth: requireAuth);

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<T>.fromJson(jsonBody, fromJsonT);
      
      // 检测 401 未授权，尝试刷新 Token 并重试
      if (apiResponse.code == 401 && requireAuth) {
        final retryResponse = await _handleTokenRefreshAndRetry<T>(
          () => get<T>(
            path,
            queryParams: queryParams,
            requireAuth: requireAuth,
            fromJsonT: fromJsonT,
          ),
        );
        if (retryResponse != null) {
          return retryResponse;
        }
      }
      
      return apiResponse;
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// PUT 请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    bool idempotent = false,
    String? requestId,
    T? Function(dynamic)? fromJsonT,
  }) async {
    final url = Uri.parse('${ApiConfig.apiPrefix}$path');
    final headers = _buildHeaders(
      requireAuth: requireAuth,
      idempotent: idempotent,
      requestId: requestId,
    );

    try {
      final response = await http
          .put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<T>.fromJson(jsonBody, fromJsonT);
      
      // 检测 401 未授权，尝试刷新 Token 并重试
      if (apiResponse.code == 401 && requireAuth) {
        final retryResponse = await _handleTokenRefreshAndRetry<T>(
          () => put<T>(
            path,
            body: body,
            requireAuth: requireAuth,
            idempotent: idempotent,
            requestId: requestId,
            fromJsonT: fromJsonT,
          ),
        );
        if (retryResponse != null) {
          return retryResponse;
        }
      }
      
      return apiResponse;
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// DELETE 请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    bool idempotent = false,
    String? requestId,
    T? Function(dynamic)? fromJsonT,
  }) async {
    final url = Uri.parse('${ApiConfig.apiPrefix}$path');
    final headers = _buildHeaders(
      requireAuth: requireAuth,
      idempotent: idempotent,
      requestId: requestId,
    );

    try {
      final response = await http
          .delete(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<T>.fromJson(jsonBody, fromJsonT);
      
      // 检测 401 未授权，尝试刷新 Token 并重试
      if (apiResponse.code == 401 && requireAuth) {
        final retryResponse = await _handleTokenRefreshAndRetry<T>(
          () => delete<T>(
            path,
            body: body,
            requireAuth: requireAuth,
            idempotent: idempotent,
            requestId: requestId,
            fromJsonT: fromJsonT,
          ),
        );
        if (retryResponse != null) {
          return retryResponse;
        }
      }
      
      return apiResponse;
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
