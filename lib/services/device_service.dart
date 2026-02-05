import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';

/// 设备信息模型（对应 API 契约中的 deviceInfo）
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String? osVersion;
  final String appVersion;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.osVersion,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        'osVersion': osVersion,
        'appVersion': appVersion,
      };
}

/// 设备信息服务
class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  static const String _deviceIdKey = 'device_id';

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  SharedPreferences? _prefs;
  DeviceInfo? _cachedDeviceInfo;

  /// 初始化服务
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 获取或生成设备 ID（持久化存储）
  Future<String> _getOrCreateDeviceId() async {
    String? deviceId = _prefs?.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _prefs?.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }

  /// 获取设备信息
  Future<DeviceInfo> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    final deviceId = await _getOrCreateDeviceId();
    String deviceName = 'Unknown Device';
    String platform = 'Unknown';
    String? osVersion;

    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceName = iosInfo.name;
        platform = 'iOS';
        osVersion = iosInfo.systemVersion;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        platform = 'Android';
        osVersion = androidInfo.version.release;
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfoPlugin.macOsInfo;
        deviceName = macOsInfo.computerName;
        platform = 'macOS';
        osVersion = macOsInfo.osRelease;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        deviceName = windowsInfo.computerName;
        platform = 'Windows';
        osVersion = windowsInfo.productName;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        deviceName = linuxInfo.prettyName;
        platform = 'Linux';
        osVersion = linuxInfo.version;
      }
    } catch (e) {
      // 获取设备信息失败时使用默认值
    }

    _cachedDeviceInfo = DeviceInfo(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      osVersion: osVersion,
      appVersion: ApiConfig.appVersion,
    );

    return _cachedDeviceInfo!;
  }
}
