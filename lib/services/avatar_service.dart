import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Avatar service - manages user avatar selection
class AvatarService {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  static const String _avatarKey = 'selected_avatar';

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

  void dispose() {
    _avatarController.close();
  }
}
