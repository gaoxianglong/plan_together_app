/// API 配置文件
/// 用于配置后端服务地址，便于切换开发/生产环境
class ApiConfig {
  ApiConfig._();

  /// API Base URL
  /// 开发环境：http://localhost:8080
  /// 生产环境：https://api.maidenplan.com (待配置)
  static const String baseUrl = 'http://localhost:8080';

  /// API 版本前缀
  static const String apiVersion = '/api/v1';

  /// 完整的 API 前缀
  static String get apiPrefix => '$baseUrl$apiVersion';

  /// 请求超时时间（秒）
  static const int timeoutSeconds = 10;

  /// Token 相关
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  /// APP 版本
  static const String appVersion = '1.0.0';
}
