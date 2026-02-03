import 'package:shared_preferences/shared_preferences.dart';

/// 简单的认证服务（本地模拟）
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // 测试账户
  static const String _testEmail = 'gxl@gmail.com';
  static const String _testPassword = '123456';

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 检查是否已登录
  bool get isLoggedIn => _prefs?.getBool(_isLoggedInKey) ?? false;

  /// 获取当前登录的邮箱
  String? get currentUserEmail => _prefs?.getString(_userEmailKey);

  /// 登录
  Future<AuthResult> login(String email, String password) async {
    // 简单验证
    if (email.isEmpty) {
      return AuthResult.failure('Please enter your email');
    }
    if (password.isEmpty) {
      return AuthResult.failure('Please enter your password');
    }
    if (!_isValidEmail(email)) {
      return AuthResult.failure('Invalid email format');
    }

    // 检查测试账户
    if (email == _testEmail && password == _testPassword) {
      await _prefs?.setBool(_isLoggedInKey, true);
      await _prefs?.setString(_userEmailKey, email);
      return AuthResult.success();
    }

    // 检查注册的账户
    final registeredPassword = _prefs?.getString('registered_$email');
    if (registeredPassword != null && registeredPassword == password) {
      await _prefs?.setBool(_isLoggedInKey, true);
      await _prefs?.setString(_userEmailKey, email);
      return AuthResult.success();
    }

    return AuthResult.failure('Incorrect email or password');
  }

  /// 注册
  Future<AuthResult> register(
    String email,
    String password,
    String confirmPassword,
  ) async {
    // 验证
    if (email.isEmpty) {
      return AuthResult.failure('Please enter your email');
    }
    if (!_isValidEmail(email)) {
      return AuthResult.failure('Invalid email format');
    }
    if (password.isEmpty) {
      return AuthResult.failure('Please enter your password');
    }
    if (password.length < 6) {
      return AuthResult.failure('Password must be at least 6 characters');
    }
    if (confirmPassword.isEmpty) {
      return AuthResult.failure('Please confirm your password');
    }
    if (password != confirmPassword) {
      return AuthResult.failure('Passwords do not match');
    }

    // 检查是否已注册
    if (_prefs?.getString('registered_$email') != null || email == _testEmail) {
      return AuthResult.failure('Email already registered');
    }

    // 保存注册信息
    await _prefs?.setString('registered_$email', password);
    await _prefs?.setBool(_isLoggedInKey, true);
    await _prefs?.setString(_userEmailKey, email);

    return AuthResult.success();
  }

  /// 登出
  Future<void> logout() async {
    await _prefs?.setBool(_isLoggedInKey, false);
    await _prefs?.remove(_userEmailKey);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// 认证结果
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;

  AuthResult._(this.isSuccess, this.errorMessage);

  factory AuthResult.success() => AuthResult._(true, null);
  factory AuthResult.failure(String message) => AuthResult._(false, message);
}
