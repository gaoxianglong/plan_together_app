import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Avatar service - manages user avatar selection
class AvatarService {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  static const String _avatarKey = 'selected_avatar';
  
  /// Asset 目录前缀
  static const String _assetPrefix = 'assets/images/avatars/';

  // Available avatars in assets/images/avatars/ (20 avatars)
  static const List<String> availableAvatars = [
    'assets/images/avatars/avatar21.svg',
    'assets/images/avatars/avatar22.svg',
    'assets/images/avatars/avatar23.svg',
    'assets/images/avatars/avatar24.svg',
    'assets/images/avatars/avatar25.svg',
    'assets/images/avatars/avatar26.svg',
    'assets/images/avatars/avatar27.svg',
    'assets/images/avatars/avatar28.svg',
    'assets/images/avatars/avatar29.svg',
    'assets/images/avatars/avatar30.svg',
    'assets/images/avatars/avatar31.svg',
    'assets/images/avatars/avatar32.svg',
    'assets/images/avatars/avatar33.svg',
    'assets/images/avatars/avatar34.svg',
    'assets/images/avatars/avatar35.svg',
    'assets/images/avatars/avatar36.svg',
    'assets/images/avatars/avatar37.svg',
    'assets/images/avatars/avatar38.svg',
    'assets/images/avatars/avatar39.svg',
    'assets/images/avatars/avatar40.svg',
  ];

  SharedPreferences? _prefs;
  String? _selectedAvatar;

  // Default avatar
  static const String defaultAvatar = 'assets/images/avatars/avatar26.svg';
  
  /// 默认头像文件名（用于 API 传输）
  static const String defaultAvatarFilename = 'avatar26.svg';

  // Stream controller for avatar changes
  final _avatarController = StreamController<String?>.broadcast();
  Stream<String?> get avatarStream => _avatarController.stream;

  /// Get the currently selected avatar path (returns default if not set)
  String get selectedAvatar => _selectedAvatar ?? defaultAvatar;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedAvatar = _prefs?.getString(_avatarKey);
  }

  /// Set the selected avatar
  Future<void> setAvatar(String? avatarPath) async {
    _selectedAvatar = avatarPath;
    if (avatarPath != null) {
      await _prefs?.setString(_avatarKey, avatarPath);
    } else {
      await _prefs?.remove(_avatarKey);
    }
    _avatarController.add(_selectedAvatar);
  }

  /// Clear the selected avatar
  Future<void> clearAvatar() async {
    await setAvatar(null);
  }
  
  /// 从 asset 完整路径提取文件名（用于 API 传输）
  /// 例: 'assets/images/avatars/avatar40.svg' → 'avatar40.svg'
  static String assetPathToFilename(String assetPath) {
    return assetPath.replaceFirst(_assetPrefix, '');
  }
  
  /// 从文件名转换为 asset 完整路径（用于本地加载）
  /// 例: 'avatar40.svg' → 'assets/images/avatars/avatar40.svg'
  static String filenameToAssetPath(String filename) {
    // 如果已经是完整路径则直接返回
    if (filename.startsWith(_assetPrefix)) {
      return filename;
    }
    return '$_assetPrefix$filename';
  }
  
  /// 验证文件名是否为有效的预设头像
  static bool isValidAvatarFilename(String filename) {
    final assetPath = filenameToAssetPath(filename);
    return availableAvatars.contains(assetPath);
  }

  void dispose() {
    _avatarController.close();
  }
}
