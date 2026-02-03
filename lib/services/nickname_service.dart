import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Nickname service - manages user nickname
class NicknameService {
  NicknameService._();
  static final NicknameService instance = NicknameService._();

  static const String _nicknameKey = 'user_nickname';
  static const String defaultNickname = 'JohnGao';

  SharedPreferences? _prefs;
  String? _nickname;

  // Stream controller for nickname changes
  final _nicknameController = StreamController<String>.broadcast();
  Stream<String> get nicknameStream => _nicknameController.stream;

  /// Get the current nickname (returns default if not set)
  String get nickname => _nickname ?? defaultNickname;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _nickname = _prefs?.getString(_nicknameKey);
  }

  /// Set the nickname
  Future<void> setNickname(String nickname) async {
    _nickname = nickname;
    await _prefs?.setString(_nicknameKey, nickname);
    _nicknameController.add(nickname);
  }

  void dispose() {
    _nicknameController.close();
  }
}
