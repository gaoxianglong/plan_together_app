import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';
import '../../services/focus_service.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with TickerProviderStateMixin {
  static const int _minDuration = 10 * 60; // 10 minutes minimum
  static const int _maxDuration = 60 * 60; // 60 minutes maximum
  static const int _defaultDuration = 25 * 60; // 25 minutes default

  int _totalDuration = _defaultDuration;
  int _remainingSeconds = _defaultDuration;
  bool _isRunning = false;
  bool _isStarting = false; // API 请求中，防止重复点击
  bool _autoStartNext = false;
  Timer? _timer;

  // 本地专注记录（当前会话中的记录）
  final List<FocusRecord> _focusRecords = [];

  // Animation controller for the progress indicator
  late AnimationController _progressController;
  // Animation controller for breathing effect
  late AnimationController _breathingController;

  // 语言变化监听
  StreamSubscription<AppLanguage>? _languageSubscription;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalDuration),
    );
    _progressController.value = 0.0;

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4秒一个呼吸周期
    );

    _languageSubscription = LocaleService.instance.languageStream.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _breathingController.dispose();
    _languageSubscription?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    AudioService.instance.playButton();
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() async {
    // 防止重复点击
    if (_isStarting) return;

    // 仅在首次启动（非暂停恢复）时调用 API
    final bool isFirstStart = _remainingSeconds == _totalDuration;

    if (isFirstStart) {
      setState(() => _isStarting = true);

      // 调用后端 API 开始专注
      final result = await FocusService.instance.startFocus(
        durationSeconds: _totalDuration,
      );

      if (!mounted) return;
      setState(() => _isStarting = false);

      if (!result.isSuccess) {
        // 开始失败，显示错误提示
        _showInfoDialog(
          icon: Icons.timer_off_rounded,
          title: tr('focus_start_failed'),
          subtitle: result.errorCode == 4001
              ? tr('error_focus_session_exists')
              : result.errorMessage ?? tr('network_error'),
        );
        return;
      }
    }

    // API 成功或暂停恢复，启动本地计时器
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _progressController.value =
              1.0 - (_remainingSeconds / _totalDuration);
        } else {
          _completeTimer();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _endTimer() async {
    AudioService.instance.playButton();
    _timer?.cancel();
    
    // 计算已专注秒数
    final elapsedSeconds = _totalDuration - _remainingSeconds;
    
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalDuration;
      _progressController.value = 0.0;
    });

    // 调用后端 API 手动结束专注
    if (FocusService.instance.currentSessionId != null) {
      final result = await FocusService.instance.endFocus(
        elapsedSeconds: elapsedSeconds,
        endType: FocusEndType.manual,
      );

      if (mounted && result.isSuccess && result.endData != null) {
        final endData = result.endData!;
        if (endData.counted) {
          // 计入专注时长，添加本地记录
          _addFocusRecordWithSeconds(endData.countedSeconds);
          _showInfoDialog(
            icon: Icons.check_circle_rounded,
            title: tr('focus_counted'),
            subtitle: '${endData.countedSeconds ~/ 60} ${tr('min')}',
          );
        } else {
          // 未达到 50%，不计入
          _showInfoDialog(
            icon: Icons.info_outline_rounded,
            title: tr('focus_not_counted_title'),
            subtitle: tr('focus_not_counted'),
          );
        }
      }
    }
  }

  void _completeTimer() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
      _progressController.value = 1.0;
    });

    // 播放番茄钟完成音效
    AudioService.instance.playTimerComplete();

    // 调用后端 API 自然结束专注
    if (FocusService.instance.currentSessionId != null) {
      final result = await FocusService.instance.endFocus(
        elapsedSeconds: _totalDuration,
        endType: FocusEndType.natural,
      );

      if (mounted && result.isSuccess && result.endData != null) {
        // 自然结束总是计入
        _addFocusRecordWithSeconds(result.endData!.countedSeconds);
      } else {
        // API 失败时仍添加本地记录
        _addFocusRecord();
      }
    } else {
      _addFocusRecord();
    }

    if (mounted) {
      if (_autoStartNext) {
        // 自动开始下一轮，不弹任何提示
        _startNextRound();
      } else {
        // 非自动模式，弹出完成提示
        _showInfoDialog(
          icon: Icons.check_circle_rounded,
          title: tr('pomodoro_completed'),
        );
      }
    }
  }

  /// 添加专注记录（按总设定时长）
  void _addFocusRecord() {
    final durationMinutes = _totalDuration ~/ 60;
    setState(() {
      _focusRecords.insert(
        0,
        FocusRecord(duration: durationMinutes, completedAt: DateTime.now()),
      );
    });
  }

  /// 添加专注记录（按实际计入的秒数）
  void _addFocusRecordWithSeconds(int countedSeconds) {
    final durationMinutes = (countedSeconds / 60).ceil();
    if (durationMinutes <= 0) return;
    setState(() {
      _focusRecords.insert(
        0,
        FocusRecord(duration: durationMinutes, completedAt: DateTime.now()),
      );
    });
  }

  /// 开始下一轮
  void _startNextRound() {
    setState(() {
      _remainingSeconds = _totalDuration;
      _progressController.value = 0.0;
    });
    _startTimer();
  }

  void _showFocusRecordSheet() {
    AudioService.instance.playButton();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _FocusHistorySheet(),
    );
  }

  /// 显示统一风格的提示浮层
  void _showInfoDialog({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 提示图标
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                // 标题
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 12),
                  // 副标题
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                // 确认按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      AudioService.instance.playButton();
                      Navigator.pop(dialogContext);
                      onDismiss?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      tr('got_it'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDurationPicker() {
    AudioService.instance.playButton();
    // 不能在运行时修改时间
    if (_isRunning) {
      _showInfoDialog(
        icon: Icons.pause_circle_outline_rounded,
        title: tr('pause_first'),
      );
      return;
    }

    int tempMinutes = _totalDuration ~/ 60;
    int tempSeconds = _totalDuration % 60;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖动条
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 标题
                  Text(
                    tr('set_focus_duration'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.priorityP0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('duration_hint'),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Time picker container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 选中区域高亮背景
                        Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        // 时间选择器
                        SizedBox(
                          height: 140,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 分钟标签
                              Text(
                                tr('min'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 分钟选择器
                              SizedBox(
                                width: 70,
                                child: ListWheelScrollView.useDelegate(
                                  controller: FixedExtentScrollController(
                                    initialItem: tempMinutes - 10,
                                  ),
                                  itemExtent: 40,
                                  perspective: 0.005,
                                  diameterRatio: 1.5,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      tempMinutes = index + 10;
                                      if (tempMinutes == 60) {
                                        tempSeconds = 0;
                                      }
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: 51,
                                    builder: (context, index) {
                                      final minute = index + 10;
                                      final isSelected = minute == tempMinutes;
                                      return Center(
                                        child: Text(
                                          minute.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: isSelected ? 22 : 16,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // 冒号
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              // 秒钟选择器
                              SizedBox(
                                width: 70,
                                child: ListWheelScrollView.useDelegate(
                                  controller: FixedExtentScrollController(
                                    initialItem: tempSeconds,
                                  ),
                                  itemExtent: 40,
                                  perspective: 0.005,
                                  diameterRatio: 1.5,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      if (tempMinutes < 60) {
                                        tempSeconds = index;
                                      }
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: 60,
                                    builder: (context, index) {
                                      final isDisabled =
                                          tempMinutes == 60 && index > 0;
                                      final isSelected = index == tempSeconds;
                                      return Center(
                                        child: Text(
                                          index.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: isSelected ? 22 : 16,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            color: isDisabled
                                                ? AppColors.textHint.withValues(
                                                    alpha: 0.5,
                                                  )
                                                : isSelected
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 秒钟标签
                              Text(
                                tr('sec'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              AudioService.instance.playButton();
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              tr('cancel'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              AudioService.instance.playButton();
                              // 验证时间范围
                              int newDuration = tempMinutes * 60 + tempSeconds;
                              if (newDuration < _minDuration) {
                                newDuration = _minDuration;
                              } else if (newDuration > _maxDuration) {
                                newDuration = _maxDuration;
                              }

                              setState(() {
                                _totalDuration = newDuration;
                                _remainingSeconds = newDuration;
                                _progressController.value = 0.0;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              tr('confirm'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String get _timerString {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildTimerCircle()),
            _buildBottomControls(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Focus Record 按钮
          GestureDetector(
            onTap: _showFocusRecordSheet,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.history, size: 24, color: AppColors.priorityP0),
            ),
          ),
          // 标题
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/Pomodoro.svg',
                  width: 25,
                  height: 25,
                ),
                const SizedBox(width: 8),
                Text(
                  tr('pomodoro'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // 占位，保持标题居中
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTimerCircle() {
    return Center(
      child: AnimatedBuilder(
        animation: _breathingController,
        builder: (context, child) {
          final double breatheValue = _isRunning
              ? _breathingController.value
              : 0.0;
          return Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: 0.15 + (breatheValue * 0.15), // 0.15 -> 0.30
                  ),
                  blurRadius: 30 + (breatheValue * 20), // 30 -> 50
                  spreadRadius: 5 + (breatheValue * 10), // 5 -> 15
                ),
              ],
            ),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 背景圆环
            SizedBox(
              width: 250,
              height: 250,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                color: AppColors.primaryLight.withValues(alpha: 0.3),
              ),
            ),
            // 进度圆环
            SizedBox(
              width: 250,
              height: 250,
              child: CircularProgressIndicator(
                value: _progressController.value,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            // 时间显示和设置按钮
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 使用等宽数字防止跳动
                Text(
                  _timerString,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRunning ? tr('focus_in_progress') : tr('ready_to_focus'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                // 设置时间按钮
                GestureDetector(
                  onTap: _showDurationPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _isRunning
                          ? AppColors.border.withValues(alpha: 0.5)
                          : AppColors.primaryLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: _isRunning
                              ? AppColors.textHint
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tr('set_time'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _isRunning
                                ? AppColors.textHint
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // End 按钮
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _endTimer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 20),
                  label: Text(
                    tr('end'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Continue/Pause 按钮
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _toggleTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isStarting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 22,
                        ),
                  label: Text(
                    _isStarting
                        ? tr('starting')
                        : _isRunning
                            ? tr('focus_pause')
                            : tr('start_focus'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Checkbox
          GestureDetector(
            onTap: () {
              setState(() {
                _autoStartNext = !_autoStartNext;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _autoStartNext
                    ? AppColors.primaryLight.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _autoStartNext,
                      onChanged: (val) {
                        setState(() {
                          _autoStartNext = val ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      side: BorderSide(
                        color: _autoStartNext
                            ? AppColors.primary
                            : AppColors.textHint,
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('auto_start_next'),
                    style: TextStyle(
                      color: _autoStartNext
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: _autoStartNext
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 专注记录数据模型
class FocusRecord {
  final int duration; // 专注时长（分钟）
  final DateTime completedAt; // 完成时间

  FocusRecord({required this.duration, required this.completedAt});
}

/// 专注历史统计浮层
class _FocusHistorySheet extends StatefulWidget {
  const _FocusHistorySheet();

  @override
  State<_FocusHistorySheet> createState() => _FocusHistorySheetState();
}

class _FocusHistorySheetState extends State<_FocusHistorySheet> {
  bool _isLoading = true;
  int _totalMinutes = 0;
  int _totalHours = 0;
  int _totalSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadTotalTime();
  }

  Future<void> _loadTotalTime() async {
    final totalTime = await FocusService.instance.getTotalTime();
    if (mounted) {
      setState(() {
        _totalSeconds = totalTime.totalSeconds;
        _totalMinutes = totalTime.totalMinutes;
        _totalHours = totalTime.totalHours;
        _isLoading = false;
      });
    }
  }

  /// 格式化大数字，防止溢出屏幕
  /// - < 10,000: 显示千位分隔符 (1,234)
  /// - 10,000 ~ 999,999: 显示 K 格式 (12.3K)
  /// - >= 1,000,000: 显示 M 格式 (1.2M)
  String _formatNumber(int number) {
    if (number < 10000) {
      // 小于1万，显示千位分隔符
      if (number < 1000) return number.toString();
      final str = number.toString();
      final buffer = StringBuffer();
      final length = str.length;
      for (int i = 0; i < length; i++) {
        if (i > 0 && (length - i) % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(str[i]);
      }
      return buffer.toString();
    } else if (number < 1000000) {
      // 1万~99万，显示 K 格式
      final k = number / 1000;
      if (k >= 100) {
        return '${k.toInt()}K'; // 100K, 999K
      } else if (k >= 10) {
        return '${k.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K'; // 10K, 12.3K
      } else {
        return '${k.toStringAsFixed(1)}K'; // 1.0K ~ 9.9K
      }
    } else {
      // >= 100万，显示 M 格式
      final m = number / 1000000;
      if (m >= 100) {
        return '${m.toInt()}M'; // 100M+
      } else if (m >= 10) {
        return '${m.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M'; // 10M, 12.3M
      } else {
        return '${m.toStringAsFixed(1)}M'; // 1.0M ~ 9.9M
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动条
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 标题
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, color: AppColors.priorityP0, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    tr('focus_history'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.priorityP0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 统计卡片
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // 总专注时长（分钟）
                          _buildStatRow(
                            icon: Icons.access_time_filled,
                            iconColor: AppColors.primary,
                            label: tr('total_focus_time'),
                            value: _formatNumber(_totalMinutes),
                            unit: tr('min'),
                          ),
                          const SizedBox(height: 12),
                          Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 12),
                          // 总专注时长（小时）
                          _buildStatRow(
                            icon: Icons.emoji_events,
                            iconColor: AppColors.warning,
                            label: tr('total_focus_hours'),
                            value: _formatNumber(_totalHours),
                            unit: tr('hours'),
                          ),
                          const SizedBox(height: 12),
                          Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 12),
                          // 总专注秒数
                          _buildStatRow(
                            icon: Icons.local_fire_department,
                            iconColor: AppColors.error,
                            label: tr('total_focus_seconds'),
                            value: _formatNumber(_totalSeconds),
                            unit: tr('sec'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              // 关闭按钮
              GestureDetector(
                onTap: () {
                  AudioService.instance.playButton();
                  Navigator.pop(context);
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.priorityP0,
                        AppColors.priorityP1,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.priorityP0.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr('close'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.priorityP0,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}






