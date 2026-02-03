import 'package:audioplayers/audioplayers.dart';

/// 音频服务 - 管理应用内音效播放
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  // 音效播放器（使用多个播放器避免音效冲突）
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _pagePlayer = AudioPlayer();
  final AudioPlayer _buttonPlayer = AudioPlayer();
  final AudioPlayer _timerCompletePlayer = AudioPlayer();
  final AudioPlayer _celebrationPlayer = AudioPlayer();
  final AudioPlayer _catMeowPlayer = AudioPlayer();

  // 音效文件路径
  static const String _clickSound = 'audio/computer-mouse-click-352734.mp3';
  static const String _pageSound = 'audio/turn-a-page-336933.mp3';
  static const String _buttonSound = 'audio/toy-button-105724.mp3';
  static const String _timerCompleteSound = 'audio/game-over-417465.mp3';
  static const String _celebrationSound = 'audio/woman-cute-silly-ya-3-185320.mp3';
  static const String _catMeowSound = 'audio/cat-meow-401729.mp3';

  // 是否启用音效
  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  /// 初始化音频服务
  Future<void> initialize() async {
    // 预加载音效
    await _clickPlayer.setSource(AssetSource(_clickSound));
    await _pagePlayer.setSource(AssetSource(_pageSound));
    await _buttonPlayer.setSource(AssetSource(_buttonSound));
    await _timerCompletePlayer.setSource(AssetSource(_timerCompleteSound));
    await _celebrationPlayer.setSource(AssetSource(_celebrationSound));
    await _catMeowPlayer.setSource(AssetSource(_catMeowSound));
    
    // 设置音量
    await _clickPlayer.setVolume(0.5);
    await _pagePlayer.setVolume(0.5);
    await _buttonPlayer.setVolume(0.5);
    await _timerCompletePlayer.setVolume(0.7);
    await _celebrationPlayer.setVolume(0.7);
    await _catMeowPlayer.setVolume(0.6);
  }

  /// 播放点击音效（用于导航按钮点击）
  Future<void> playClick() async {
    if (!_enabled) return;
    try {
      await _clickPlayer.stop();
      await _clickPlayer.play(AssetSource(_clickSound));
    } catch (e) {
      // 忽略播放错误
    }
  }

  /// 播放翻页音效（用于日历切换）
  Future<void> playPageTurn() async {
    if (!_enabled) return;
    try {
      await _pagePlayer.stop();
      await _pagePlayer.play(AssetSource(_pageSound));
    } catch (e) {
      // 忽略播放错误
    }
  }

  /// 播放按钮音效（用于所有按钮点击）
  Future<void> playButton() async {
    if (!_enabled) return;
    try {
      await _buttonPlayer.stop();
      await _buttonPlayer.play(AssetSource(_buttonSound));
    } catch (e) {
      // 忽略播放错误
    }
  }

  /// 播放番茄钟完成音效
  Future<void> playTimerComplete() async {
    if (!_enabled) return;
    try {
      await _timerCompletePlayer.stop();
      await _timerCompletePlayer.play(AssetSource(_timerCompleteSound));
    } catch (e) {
      // 忽略播放错误
    }
  }

  /// 播放庆祝音效（任务全部完成）
  Future<void> playCelebration() async {
    if (!_enabled) return;
    try {
      await _celebrationPlayer.stop();
      await _celebrationPlayer.play(AssetSource(_celebrationSound));
    } catch (e) {
      // 忽略播放错误
    }
  }

  /// 播放猫咪喵叫音效
  Future<void> playCatMeow() async {
    if (!_enabled) return;
    try {
      await _catMeowPlayer.stop();
      await _catMeowPlayer.play(AssetSource(_catMeowSound));
    } catch (e) {
      // 忽略播放错误
    }
  }

  /// 释放资源
  void dispose() {
    _clickPlayer.dispose();
    _pagePlayer.dispose();
    _buttonPlayer.dispose();
    _timerCompletePlayer.dispose();
    _celebrationPlayer.dispose();
    _catMeowPlayer.dispose();
  }
}
