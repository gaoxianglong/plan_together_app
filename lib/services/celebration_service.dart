import 'package:shared_preferences/shared_preferences.dart';

/// 庆祝服务
/// 管理当日全完成的触发状态
class CelebrationService {
  CelebrationService._();
  static final CelebrationService instance = CelebrationService._();

  static const String _keyPrefix = 'celebration_triggered_';
  SharedPreferences? _prefs;

  /// 初始化（在 main.dart 中调用）
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 获取今天的日期key
  String _getTodayKey() {
    final now = DateTime.now();
    return '$_keyPrefix${now.year}_${now.month}_${now.day}';
  }

  /// 检查今天是否已触发过庆祝
  /// TODO: 测试完成后恢复限制
  bool hasTriggeredToday() {
    // 临时禁用限制，方便测试
    return false;
    // if (_prefs == null) return false;
    // return _prefs!.getBool(_getTodayKey()) ?? false;
  }

  /// 标记今天已触发庆祝
  Future<void> markTriggeredToday() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_getTodayKey(), true);

    // 清理旧数据（保留最近7天）
    _cleanupOldData();
  }

  /// 清理7天前的数据
  Future<void> _cleanupOldData() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys();
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (final key in keys) {
      if (key.startsWith(_keyPrefix)) {
        // 解析日期
        final parts = key.replaceFirst(_keyPrefix, '').split('_');
        if (parts.length == 3) {
          try {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            final date = DateTime(year, month, day);

            if (date.isBefore(sevenDaysAgo)) {
              await _prefs!.remove(key);
            }
          } catch (_) {
            // 忽略解析错误
          }
        }
      }
    }
  }

  /// 判断是否是今天
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
