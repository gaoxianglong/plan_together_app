import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'locale_service.dart';

/// 专注会话数据模型
class FocusSession {
  final String sessionId;
  final int durationSeconds;
  final String type;
  final String startAt;
  final String expectedEndAt;

  FocusSession({
    required this.sessionId,
    required this.durationSeconds,
    required this.type,
    required this.startAt,
    required this.expectedEndAt,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        sessionId: json['sessionId'] as String,
        durationSeconds: json['durationSeconds'] as int,
        type: json['type'] as String,
        startAt: json['startAt'] as String,
        expectedEndAt: json['expectedEndAt'] as String,
      );
}

/// 专注结束类型（对应后端 EndType 枚举）
class FocusEndType {
  static const String natural = 'NATURAL'; // 自然结束（时间到了）
  static const String manual = 'MANUAL';   // 手动结束（用户点击 End）
}

/// 结束专注的响应数据
class FocusEndData {
  final String sessionId;
  final bool counted;
  final int countedSeconds;
  final int totalFocusTime;

  FocusEndData({
    required this.sessionId,
    required this.counted,
    required this.countedSeconds,
    required this.totalFocusTime,
  });

  factory FocusEndData.fromJson(Map<String, dynamic> json) => FocusEndData(
        sessionId: json['sessionId'] as String,
        counted: json['counted'] as bool,
        countedSeconds: json['countedSeconds'] as int,
        totalFocusTime: json['totalFocusTime'] as int,
      );
}

/// 专注操作结果
class FocusResult {
  final bool isSuccess;
  final String? errorMessage;
  final int? errorCode;
  final FocusSession? session;
  final FocusEndData? endData;

  FocusResult._({
    required this.isSuccess,
    this.errorMessage,
    this.errorCode,
    this.session,
    this.endData,
  });

  factory FocusResult.success({FocusSession? session, FocusEndData? endData}) =>
      FocusResult._(
        isSuccess: true,
        session: session,
        endData: endData,
      );

  factory FocusResult.failure(String message, {int? errorCode}) => FocusResult._(
        isSuccess: false,
        errorMessage: message,
        errorCode: errorCode,
      );
}

/// 专注统计数据
class FocusTotalTime {
  final int totalSeconds;
  final int totalHours;

  FocusTotalTime({
    required this.totalSeconds,
    required this.totalHours,
  });

  factory FocusTotalTime.fromJson(Map<String, dynamic> json) => FocusTotalTime(
        totalSeconds: json['totalSeconds'] as int,
        totalHours: json['totalHours'] as int,
      );

  /// 总分钟数
  int get totalMinutes => totalSeconds ~/ 60;
}

/// 专注服务 - 管理专注会话
class FocusService {
  FocusService._();
  static final FocusService instance = FocusService._();

  static const String _totalSecondsKey = 'focus_total_seconds';
  static const String _totalHoursKey = 'focus_total_hours';

  SharedPreferences? _prefs;

  /// 当前进行中的会话 ID
  String? _currentSessionId;

  /// 获取当前会话 ID
  String? get currentSessionId => _currentSessionId;

  /// 初始化服务
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 开始专注
  /// POST /api/v1/focus/start
  Future<FocusResult> startFocus({
    required int durationSeconds,
  }) async {
    // 前端校验时长范围：600 ~ 3600（10 ~ 60分钟）
    if (durationSeconds < 600) {
      return FocusResult.failure(tr('focus_duration_too_short'), errorCode: -1);
    }
    if (durationSeconds > 3600) {
      return FocusResult.failure(tr('focus_duration_too_long'), errorCode: -1);
    }

    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/focus/start',
      body: {
        'durationSeconds': durationSeconds,
        'type': 'OTHER',
      },
      requireAuth: true,
      idempotent: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final session = FocusSession.fromJson(response.data!);
      _currentSessionId = session.sessionId;
      return FocusResult.success(session: session);
    } else {
      return FocusResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 结束专注
  /// POST /api/v1/focus/{sessionId}/end
  Future<FocusResult> endFocus({
    required int elapsedSeconds,
    required String endType,
  }) async {
    if (_currentSessionId == null) {
      return FocusResult.failure(tr('network_error'), errorCode: -1);
    }

    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/focus/$_currentSessionId/end',
      body: {
        'elapsedSeconds': elapsedSeconds,
        'endType': endType,
      },
      requireAuth: true,
      idempotent: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final endData = FocusEndData.fromJson(response.data!);
      _currentSessionId = null;
      return FocusResult.success(endData: endData);
    } else {
      return FocusResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 查询总专注时间
  /// GET /api/v1/focus/total-time
  /// 优先从服务端获取，超时则读取本地缓存
  Future<FocusTotalTime> getTotalTime() async {
    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/focus/total-time',
        requireAuth: true,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final totalTime = FocusTotalTime.fromJson(response.data!);
        // 缓存到本地
        await _cacheTotalTime(totalTime);
        return totalTime;
      }
    } catch (_) {
      // 网络异常，降级读取本地缓存
    }

    // 服务端请求失败或超时，读取本地缓存
    return _getCachedTotalTime();
  }

  /// 缓存统计数据到本地
  Future<void> _cacheTotalTime(FocusTotalTime totalTime) async {
    await _prefs?.setInt(_totalSecondsKey, totalTime.totalSeconds);
    await _prefs?.setInt(_totalHoursKey, totalTime.totalHours);
  }

  /// 读取本地缓存的统计数据
  FocusTotalTime _getCachedTotalTime() {
    final totalSeconds = _prefs?.getInt(_totalSecondsKey) ?? 0;
    final totalHours = _prefs?.getInt(_totalHoursKey) ?? 0;
    return FocusTotalTime(
      totalSeconds: totalSeconds,
      totalHours: totalHours,
    );
  }

  /// 清除当前会话
  void clearCurrentSession() {
    _currentSessionId = null;
  }

  /// 根据错误码获取国际化错误信息
  String _getErrorMessage(int code, String defaultMessage) {
    switch (code) {
      case 4001:
        return tr('error_focus_session_exists');
      case 401:
        return tr('error_unauthorized');
      case -1:
        return tr('network_error');
      default:
        return defaultMessage;
    }
  }
}
