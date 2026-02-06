import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'avatar_service.dart';
import 'device_service.dart';
import 'locale_service.dart';
import 'nickname_service.dart';

/// 用户信息模型
class UserInfo {
  final String nickname;
  final String avatar;
  final String? ipLocation;

  UserInfo({
    required this.nickname,
    required this.avatar,
    this.ipLocation,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        nickname: json['nickname'] as String,
        avatar: json['avatar'] as String,
        ipLocation: json['ipLocation'] as String?,
      );
}

/// 权益信息模型
class Entitlement {
  final String status;
  final String? trialStartAt;
  final String? expireAt;

  Entitlement({
    required this.status,
    this.trialStartAt,
    this.expireAt,
  });

  factory Entitlement.fromJson(Map<String, dynamic> json) => Entitlement(
        status: json['status'] as String,
        trialStartAt: json['trialStartAt'] as String?,
        expireAt: json['expireAt'] as String?,
      );
}

/// 登录/注册响应数据模型
class AuthData {
  final String userId;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserInfo userInfo;
  final Entitlement entitlement;

  AuthData({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.userInfo,
    required this.entitlement,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) => AuthData(
        userId: json['userId'] as String,
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: json['expiresIn'] as int,
        userInfo: UserInfo.fromJson(json['userInfo'] as Map<String, dynamic>),
        entitlement:
            Entitlement.fromJson(json['entitlement'] as Map<String, dynamic>),
      );
}

/// 设备信息模型
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String? lastLoginIp;
  final String? lastLoginAt;
  final bool isCurrent;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.lastLoginIp,
    this.lastLoginAt,
    required this.isCurrent,
  });

  /// forceIsCurrent: 强制设置 isCurrent 值
  /// - true: 强制为当前设备（用于 currentDevice）
  /// - false: 强制为非当前设备（用于 otherDevices）
  /// - null: 使用 API 返回的值
  factory DeviceInfo.fromJson(Map<String, dynamic> json, {bool? forceIsCurrent}) => DeviceInfo(
        deviceId: json['deviceId'] as String,
        deviceName: json['deviceName'] as String,
        platform: json['platform'] as String,
        lastLoginIp: json['lastLoginIp'] as String?,
        lastLoginAt: json['lastLoginAt'] as String?,
        isCurrent: forceIsCurrent ?? (json['isCurrent'] as bool? ?? false),
      );
}

/// 设备列表查询结果
class DeviceListResult {
  final bool isSuccess;
  final DeviceInfo? currentDevice;
  final List<DeviceInfo> otherDevices;
  final String? errorMessage;

  DeviceListResult._({
    required this.isSuccess,
    this.currentDevice,
    this.otherDevices = const [],
    this.errorMessage,
  });

  factory DeviceListResult.success({
    DeviceInfo? currentDevice,
    List<DeviceInfo> otherDevices = const [],
  }) =>
      DeviceListResult._(
        isSuccess: true,
        currentDevice: currentDevice,
        otherDevices: otherDevices,
      );

  factory DeviceListResult.failure(String message) => DeviceListResult._(
        isSuccess: false,
        errorMessage: message,
      );
}

/// 用户信息查询结果
class UserProfileResult {
  final bool isSuccess;
  final String? nickname;
  final String? avatar;
  final String? ipLocation;
  final int? consecutiveDays;
  final String? lastCheckInDate;
  final int? nicknameModifyCount;
  final String? nicknameNextModifyAt;
  final String? errorMessage;

  UserProfileResult._({
    required this.isSuccess,
    this.nickname,
    this.avatar,
    this.ipLocation,
    this.consecutiveDays,
    this.lastCheckInDate,
    this.nicknameModifyCount,
    this.nicknameNextModifyAt,
    this.errorMessage,
  });

  factory UserProfileResult.success({
    String? nickname,
    String? avatar,
    String? ipLocation,
    int? consecutiveDays,
    String? lastCheckInDate,
    int? nicknameModifyCount,
    String? nicknameNextModifyAt,
  }) =>
      UserProfileResult._(
        isSuccess: true,
        nickname: nickname,
        avatar: avatar,
        ipLocation: ipLocation,
        consecutiveDays: consecutiveDays,
        lastCheckInDate: lastCheckInDate,
        nicknameModifyCount: nicknameModifyCount,
        nicknameNextModifyAt: nicknameNextModifyAt,
      );

  factory UserProfileResult.failure(String message) => UserProfileResult._(
        isSuccess: false,
        errorMessage: message,
      );
}

/// 认证服务
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SharedPreferences? _prefs;
  AuthData? _currentAuthData;
  
  /// 会话轮询定时器
  Timer? _sessionPollingTimer;
  
  /// 是否正在轮询
  bool get isPolling => _sessionPollingTimer != null && _sessionPollingTimer!.isActive;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    // 恢复保存的 token
    final accessToken = _prefs?.getString(ApiConfig.accessTokenKey);
    final refreshToken = _prefs?.getString(ApiConfig.refreshTokenKey);
    if (accessToken != null && refreshToken != null) {
      ApiClient.instance.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
    
    // 设置 Token 刷新成功回调，用于更新本地存储
    ApiClient.instance.setOnTokenRefreshed(_onTokenRefreshed);
  }
  
  /// Token 刷新成功回调
  /// 当 ApiClient 自动刷新 Token 后，更新本地存储
  Future<void> _onTokenRefreshed(String accessToken, String refreshToken) async {
    await _prefs?.setString(ApiConfig.accessTokenKey, accessToken);
    await _prefs?.setString(ApiConfig.refreshTokenKey, refreshToken);
  }

  /// 检查是否已登录
  bool get isLoggedIn =>
      _prefs?.getString(ApiConfig.accessTokenKey) != null;

  /// 获取当前用户 ID
  String? get currentUserId => _prefs?.getString(ApiConfig.userIdKey);

  /// 获取当前认证数据
  AuthData? get currentAuthData => _currentAuthData;

  /// 保存认证数据
  Future<void> _saveAuthData(AuthData authData) async {
    _currentAuthData = authData;
    await _prefs?.setString(ApiConfig.accessTokenKey, authData.accessToken);
    await _prefs?.setString(ApiConfig.refreshTokenKey, authData.refreshToken);
    await _prefs?.setString(ApiConfig.userIdKey, authData.userId);
    ApiClient.instance.setTokens(
      accessToken: authData.accessToken,
      refreshToken: authData.refreshToken,
    );
  }

  /// 清除认证数据
  Future<void> _clearAuthData() async {
    _currentAuthData = null;
    await _prefs?.remove(ApiConfig.accessTokenKey);
    await _prefs?.remove(ApiConfig.refreshTokenKey);
    await _prefs?.remove(ApiConfig.userIdKey);
    ApiClient.instance.clearTokens();
    // 停止会话轮询
    stopSessionPolling();
  }

  /// 清除本地认证数据（用于 401 自动登出）
  void clearLocalAuth() {
    _currentAuthData = null;
    _prefs?.remove(ApiConfig.accessTokenKey);
    _prefs?.remove(ApiConfig.refreshTokenKey);
    _prefs?.remove(ApiConfig.userIdKey);
    ApiClient.instance.clearTokens();
    // 停止会话轮询
    stopSessionPolling();
  }

  /// 开启会话状态轮询（登录成功后调用）
  void startSessionPolling() {
    // 先停止已有的轮询
    stopSessionPolling();
    
    // 每10秒轮询一次
    _sessionPollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkSession(),
    );
  }

  /// 停止会话状态轮询
  void stopSessionPolling() {
    _sessionPollingTimer?.cancel();
    _sessionPollingTimer = null;
  }

  /// 检查会话状态
  /// GET /api/v1/auth/session/check
  Future<void> _checkSession() async {
    // 如果没有 token，停止轮询
    if (!isLoggedIn) {
      stopSessionPolling();
      return;
    }

    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '/auth/session/check',
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    // 401 会在 ApiClient 中自动处理跳转登录页
    // 这里只需要在响应失败时停止轮询
    if (response.code == 401) {
      stopSessionPolling();
    }
  }

  /// 用户注册
  /// POST /api/v1/auth/register
  Future<AuthResult> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    // 前端校验
    if (email.isEmpty) {
      return AuthResult.failure(tr('email_required'), errorCode: -1);
    }
    if (!_isValidEmail(email)) {
      return AuthResult.failure(tr('email_invalid'), errorCode: -1);
    }
    if (password.isEmpty) {
      return AuthResult.failure(tr('password_required'), errorCode: -1);
    }
    if (password.length < 6) {
      return AuthResult.failure(
        tr('password_min_length'),
        errorCode: 1005,
      );
    }
    if (nickname.isEmpty) {
      return AuthResult.failure(tr('nickname_required'), errorCode: -1);
    }
    if (nickname.length > 20) {
      return AuthResult.failure(
        tr('nickname_too_long'),
        errorCode: -1,
      );
    }

    // 获取设备信息
    final deviceInfo = await DeviceService.instance.getDeviceInfo();

    // 调用注册 API
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'nickname': nickname,
        'deviceInfo': deviceInfo.toJson(),
      },
      idempotent: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final authData = AuthData.fromJson(response.data!);
        await _saveAuthData(authData);
        return AuthResult.success(authData: authData);
      } catch (e) {
        // 解析响应数据失败，但注册已成功，仍返回成功
        return AuthResult.success();
      }
    } else {
      // 根据错误码返回对应错误信息
      return AuthResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 用户登录
  /// POST /api/v1/auth/login
  Future<AuthResult> login(String email, String password) async {
    // 前端校验
    if (email.isEmpty) {
      return AuthResult.failure(tr('email_required'), errorCode: -1);
    }
    if (!_isValidEmail(email)) {
      return AuthResult.failure(tr('email_invalid'), errorCode: -1);
    }
    if (password.isEmpty) {
      return AuthResult.failure(tr('password_required'), errorCode: -1);
    }

    // 获取设备信息
    final deviceInfo = await DeviceService.instance.getDeviceInfo();

    // 调用登录 API
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        'deviceInfo': deviceInfo.toJson(),
      },
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final authData = AuthData.fromJson(response.data!);
      await _saveAuthData(authData);
      return AuthResult.success(authData: authData);
    } else {
      return AuthResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 退出登录
  /// POST /api/v1/auth/logout
  Future<void> logout() async {
    // 调用登出 API
    await ApiClient.instance.post(
      '/auth/logout',
      requireAuth: true,
    );
    // 清除本地数据
    await _clearAuthData();
  }

  /// 修改密码
  /// POST /api/v1/auth/password
  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    // 前端校验
    if (oldPassword.isEmpty) {
      return AuthResult.failure(tr('enter_current_password'), errorCode: -1);
    }
    if (newPassword.isEmpty) {
      return AuthResult.failure(tr('enter_new_password'), errorCode: -1);
    }
    if (newPassword.length < 6) {
      return AuthResult.failure(tr('password_min_length'), errorCode: 1005);
    }

    // 调用修改密码 API
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/auth/password',
      body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess) {
      return AuthResult.success();
    } else {
      // 修改密码场景下 1001 表示旧密码错误
      final errorMessage = response.code == 1001
          ? tr('error_old_password_wrong')
          : _getErrorMessage(response.code, response.message);
      return AuthResult.failure(
        errorMessage,
        errorCode: response.code,
      );
    }
  }

  /// 找回密码
  /// POST /api/v1/auth/forgot-password
  Future<AuthResult> forgotPassword(String email) async {
    // 前端校验
    if (email.isEmpty) {
      return AuthResult.failure(tr('email_required'), errorCode: -1);
    }
    if (!_isValidEmail(email)) {
      return AuthResult.failure(tr('email_invalid'), errorCode: -1);
    }

    // 调用找回密码 API
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      body: {'email': email},
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess) {
      return AuthResult.success();
    } else {
      return AuthResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 获取设备列表
  /// GET /api/v1/auth/devices
  Future<DeviceListResult> getDevices() async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '/auth/devices',
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final currentDeviceJson = response.data!['currentDevice'] as Map<String, dynamic>?;
        final otherDevicesJson = response.data!['otherDevices'] as List<dynamic>? ?? [];

        // 解析当前设备，强制 isCurrent = true
        final currentDevice = currentDeviceJson != null 
            ? DeviceInfo.fromJson(currentDeviceJson, forceIsCurrent: true) 
            : null;
        // 解析其他设备，强制 isCurrent = false
        final otherDevices = otherDevicesJson
            .map((e) => DeviceInfo.fromJson(e as Map<String, dynamic>, forceIsCurrent: false))
            .toList();

        return DeviceListResult.success(
          currentDevice: currentDevice,
          otherDevices: otherDevices,
        );
      } catch (e) {
        return DeviceListResult.failure(tr('error_parse'));
      }
    } else {
      return DeviceListResult.failure(
        _getErrorMessage(response.code, response.message),
      );
    }
  }

  /// 踢出指定设备
  /// POST /api/v1/auth/devices/{deviceId}/logout
  Future<AuthResult> logoutDevice(String deviceId) async {
    final response = await ApiClient.instance.post<void>(
      '/auth/devices/$deviceId/logout',
      requireAuth: true,
    );

    if (response.isSuccess) {
      return AuthResult.success();
    } else {
      return AuthResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 更新用户信息（昵称/头像）
  /// PUT /api/v1/user/profile
  Future<AuthResult> updateProfile({
    String? nickname,
    String? avatar,
  }) async {
    // 至少需要一个字段
    if (nickname == null && avatar == null) {
      return AuthResult.failure(tr('error_bad_request'), errorCode: 400);
    }

    // 昵称校验
    if (nickname != null) {
      if (nickname.isEmpty || nickname.length > 20) {
        return AuthResult.failure(tr('nickname_length_invalid'), errorCode: -1);
      }
    }

    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatar != null) body['avatar'] = avatar;

    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      '/user/profile',
      body: body,
      requireAuth: true,
      idempotent: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess) {
      return AuthResult.success();
    } else {
      return AuthResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 查询用户信息
  /// GET /api/v1/user/profile
  Future<UserProfileResult> getUserProfile() async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '/user/profile',
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      return UserProfileResult.success(
        nickname: data['nickname'] as String?,
        avatar: data['avatar'] as String?,
        ipLocation: data['ipLocation'] as String?,
        consecutiveDays: data['consecutiveDays'] as int?,
        lastCheckInDate: data['lastCheckInDate'] as String?,
        nicknameModifyCount: data['nicknameModifyCount'] as int?,
        nicknameNextModifyAt: data['nicknameNextModifyAt'] as String?,
      );
    } else {
      return UserProfileResult.failure(
        _getErrorMessage(response.code, response.message),
      );
    }
  }

  /// 拉取用户信息并同步到本地
  /// 登录成功后调用，更新本地的昵称和头像
  Future<void> fetchAndSyncUserProfile() async {
    final result = await getUserProfile();
    if (result.isSuccess) {
      // 同步昵称
      if (result.nickname != null && result.nickname!.isNotEmpty) {
        await NicknameService.instance.setNickname(result.nickname!);
      }
      // 同步头像（后端存储的是文件名，需要转换为本地 asset 路径）
      if (result.avatar != null && result.avatar!.isNotEmpty) {
        final assetPath = AvatarService.filenameToAssetPath(result.avatar!);
        if (AvatarService.isValidAvatarFilename(result.avatar!)) {
          await AvatarService.instance.setAvatar(assetPath);
        }
      }
    }
  }

  /// 刷新 Token
  /// POST /api/v1/auth/refresh
  Future<bool> refreshToken() async {
    final refreshToken = _prefs?.getString(ApiConfig.refreshTokenKey);
    if (refreshToken == null) {
      return false;
    }

    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final newAccessToken = response.data!['accessToken'] as String;
      final newRefreshToken = response.data!['refreshToken'] as String;
      await _prefs?.setString(ApiConfig.accessTokenKey, newAccessToken);
      await _prefs?.setString(ApiConfig.refreshTokenKey, newRefreshToken);
      ApiClient.instance.setTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return true;
    }

    return false;
  }

  /// 根据错误码获取国际化错误信息
  String _getErrorMessage(int code, String defaultMessage) {
    switch (code) {
      // 全局错误码
      case 0:
        return tr('success');
      case 400:
        return tr('error_bad_request');
      case 401:
        return tr('error_unauthorized');
      case 403:
        return tr('error_forbidden');
      case 404:
        return tr('error_not_found');
      case 429:
        return tr('error_too_many_requests');
      case 500:
        return tr('error_server');
      // 认证模块 1001-1099
      case 1001:
        return tr('error_login_failed');
      case 1003:
        return tr('error_device_limit');
      case 1004:
        return tr('email_already_registered');
      case 1005:
        return tr('password_min_length');
      case 1006:
        return tr('nickname_contains_prohibited');
      case 1007:
        return tr('error_email_not_found');
      // 设备管理 2001-2099
      case 2001:
        return tr('error_cannot_logout_current');
      case 2002:
        return tr('error_device_not_found');
      // 任务管理 3001-3099
      case 3001:
        return tr('error_task_title_invalid');
      case 3002:
        return tr('error_task_date_out_of_range');
      case 3003:
        return tr('error_task_daily_limit');
      case 3004:
        return tr('error_task_repeat_invalid');
      case 3005:
        return tr('error_task_has_incomplete_subtasks');
      case 3006:
        return tr('error_task_parent_not_found');
      case 3007:
        return tr('error_task_subtask_limit');
      // 专注模块 4001-4099
      case 4001:
        return tr('error_focus_session_exists');
      // 用户中心 5001-5099
      case 5001:
        return tr('nickname_contains_prohibited');
      case 5002:
        return tr('error_nickname_too_frequent');
      // 网络错误
      case -1:
        return tr('network_error');
      case -2:
        return tr('error_parse');
      default:
        return defaultMessage;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// 认证结果
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final int? errorCode;
  final AuthData? authData;

  AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.errorCode,
    this.authData,
  });

  factory AuthResult.success({AuthData? authData}) => AuthResult._(
        isSuccess: true,
        authData: authData,
      );

  factory AuthResult.failure(String message, {int? errorCode}) => AuthResult._(
        isSuccess: false,
        errorMessage: message,
        errorCode: errorCode,
      );
}
