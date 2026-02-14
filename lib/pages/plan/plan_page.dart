import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../widgets/calendar/week_calendar.dart';
import '../../widgets/common/plan_header.dart';
import '../../widgets/common/quote_card.dart';
import '../../widgets/common/celebration_overlay.dart';
import '../../widgets/task/add_task_sheet.dart';
import '../../widgets/task/update_task_sheet.dart';
import '../../widgets/task/eisenhower_matrix.dart';
import '../../widgets/task/swipeable_matrix_area.dart';
import '../../services/quote_service.dart';
import '../../services/celebration_service.dart';
import '../../services/audio_service.dart';
import '../../services/avatar_service.dart';
import '../../services/nickname_service.dart';
import '../../services/locale_service.dart';
import '../../services/task_service.dart';

/// Plan Page
class PlanPage extends StatefulWidget {
  final VoidCallback? onAddTask;
  final VoidCallback? onAddTaskLongPress;
  final VoidCallback? onSettingsTap;

  const PlanPage({
    super.key,
    this.onAddTask,
    this.onAddTaskLongPress,
    this.onSettingsTap,
  });

  @override
  State<PlanPage> createState() => PlanPageState();
}

/// Public state class, facilitates external calls to add task method
class PlanPageState extends State<PlanPage> {
  DateTime _selectedDate = DateTime.now();
  final bool _showCompleted = true;

  // Listen to quote service
  String _currentQuote = QuoteService.instance.currentQuote;
  StreamSubscription<String>? _quoteSubscription;

  // Avatar state
  String _selectedAvatar = AvatarService.defaultAvatar;
  StreamSubscription<String?>? _avatarSubscription;

  // Nickname state
  String _nickname = NicknameService.defaultNickname;
  StreamSubscription<String>? _nicknameSubscription;

  // Language subscription for rebuilding UI
  StreamSubscription<AppLanguage>? _languageSubscription;

  // 连续打卡天数
  int _consecutiveDays = 0;

  @override
  void initState() {
    super.initState();
    // Listen to quote updates
    _quoteSubscription = QuoteService.instance.quoteStream.listen((quote) {
      setState(() {
        _currentQuote = quote;
      });
    });

    // Get initial avatar and listen for changes
    _selectedAvatar = AvatarService.instance.selectedAvatar;
    _avatarSubscription = AvatarService.instance.avatarStream.listen((avatar) {
      setState(() {
        _selectedAvatar = avatar ?? AvatarService.defaultAvatar;
      });
    });

    // Get initial nickname and listen for changes
    _nickname = NicknameService.instance.nickname;
    _nicknameSubscription = NicknameService.instance.nicknameStream.listen((
      nickname,
    ) {
      setState(() {
        _nickname = nickname;
      });
    });

    // Listen for language changes to rebuild UI
    _languageSubscription = LocaleService.instance.languageStream.listen((_) {
      setState(() {});
    });

    // 首次加载任务列表
    _fetchTasks();

    // 查询连续打卡天数
    _fetchCheckInStreak();
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    _avatarSubscription?.cancel();
    _nicknameSubscription?.cancel();
    _languageSubscription?.cancel();
    super.dispose();
  }

  // 当前日期的任务列表（从 API 获取）
  List<Task> _tasks = [];
  List<Task> _prevDayTasks = [];
  List<Task> _nextDayTasks = [];
  bool _isLoading = false;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }

  /// 当前日期的任务（已按日期从 API 获取，直接返回）
  List<Task> get _tasksForSelectedDate => _tasks;

  Map<DateTime, List<int>> get _taskIndicators {
    final indicators = <DateTime, List<int>>{};
    final allTasks = [..._tasks, ..._prevDayTasks, ..._nextDayTasks];
    for (final task in allTasks) {
      if (!task.isCompleted) {
        final normalizedDate = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
        );
        if (!indicators.containsKey(normalizedDate)) {
          indicators[normalizedDate] = [];
        }
        if (!indicators[normalizedDate]!.contains(task.priority.value)) {
          indicators[normalizedDate]!.add(task.priority.value);
        }
      }
    }
    for (final entry in indicators.entries) {
      entry.value.sort();
    }
    return indicators;
  }

  void _handleDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchTasks();
  }

  /// 滑动切换日期后回调（由 SwipeableMatrixArea 触发）
  void _handleMatrixDateChanged(DateTime newDate) {
    if (_isSameDay(newDate, _selectedDate)) return; // 避免重复触发导致多次请求
    setState(() {
      _selectedDate = newDate;
    });
    _fetchTasks();
  }

  void _handleReturnToToday() {
    AudioService.instance.playPageTurn();
    setState(() {
      _selectedDate = DateTime.now();
    });
    _fetchTasks();
  }

  /// 从 API 获取当前日及相邻日期的任务列表（用于滑动预览）
  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    final prevDate = _selectedDate.subtract(const Duration(days: 1));
    final nextDate = _selectedDate.add(const Duration(days: 1));

    final results = await Future.wait([
      TaskService.instance.fetchTasksByDate(_selectedDate, showCompleted: _showCompleted),
      TaskService.instance.fetchTasksByDate(prevDate, showCompleted: _showCompleted),
      TaskService.instance.fetchTasksByDate(nextDate, showCompleted: _showCompleted),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (results[0].isSuccess) _tasks = results[0].tasks;
        if (results[1].isSuccess) _prevDayTasks = results[1].tasks;
        if (results[2].isSuccess) _nextDayTasks = results[2].tasks;
      });

      if (!results[0].isSuccess) {
        _showError(results[0].errorMessage ?? tr('error_server'));
      }
    }
  }

  /// 查询连续打卡天数
  Future<void> _fetchCheckInStreak() async {
    final result = await TaskService.instance.getCheckInStreak();
    if (mounted && result.isSuccess) {
      setState(() {
        _consecutiveDays = result.consecutiveDays;
      });
    }
  }

  /// 显示错误提示
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[400],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Public method: Add task
  void handleAddTask({TaskPriority? priority}) {
    showAddTaskSheet(
      context,
      selectedDate: _selectedDate,
      defaultPriority: priority,
      onSave: (title, taskPriority) {
        _createTask(title, taskPriority);
      },
    );
  }

  /// 创建任务（调用后端 API）
  Future<void> _createTask(String title, TaskPriority priority) async {
    // 过去的日期自动调整为今天
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final taskDate = selectedDay.isBefore(today) ? today : selectedDay;

    final result = await TaskService.instance.createTask(
      title: title,
      priority: priority.apiValue,
      date: taskDate,
    );

    if (result.isSuccess) {
      if (result.task != null && _isSameDay(taskDate, _selectedDate)) {
        // 任务归属当前日期，直接加入本地列表
        setState(() {
          _tasks = [result.task!, ..._tasks];
        });
      } else {
        // 任务归属其他日期或无法解析响应，刷新当前列表
        await _fetchTasks();
      }
    } else {
      _showError(result.errorMessage ?? tr('error_server'));
    }
  }

  /// Public method: Show quick add menu
  void showQuickAddMenu() {
    _showQuickAddMenu();
  }

  /// 切换任务完成状态（乐观更新 + API 调用）
  Future<void> _handleToggleTaskComplete(Task task) async {
    final wasAllCompleted = _areAllTodayTasksCompleted();
    final newCompleted = !task.isCompleted;
    final newStatus =
        newCompleted ? TaskStatus.completed : TaskStatus.incomplete;
    final now = DateTime.now();

    // 乐观更新：立即更新 UI
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final currentTask = _tasks[index];
        final updatedSubtasks = currentTask.subTasks
            .map((s) => s.copyWith(
                  status: newStatus,
                  completedAt: newCompleted ? now : null,
                ))
            .toList();
        _tasks[index] = currentTask.copyWith(
          status: newStatus,
          completedAt: newCompleted ? now : null,
          subTasks: updatedSubtasks,
        );
      }
    });

    // 调用后端 API
    final result = await TaskService.instance.toggleComplete(
      task.id,
      newCompleted,
    );

    if (result.isSuccess) {
      // 完成任务时调用打卡接口
      if (newCompleted) {
        final today = DateTime.now();
        final checkInResult = await TaskService.instance.checkIn(
          DateTime(today.year, today.month, today.day),
        );
        if (mounted && checkInResult.isSuccess) {
          setState(() {
            _consecutiveDays = checkInResult.consecutiveDays;
          });
        }
      }
      _checkAndTriggerCelebration(wasAllCompleted);
    } else {
      // API 失败，回滚到原始状态
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
        }
      });
      _showError(result.errorMessage ?? tr('error_server'));
    }
  }

  /// 判断当前显示的任务是否全部完成（仅在查看今天时有效）
  bool _areAllTodayTasksCompleted() {
    if (!_isToday(_selectedDate)) return false;
    if (_tasks.isEmpty) return false;
    return _tasks.every((task) => task.isCompleted);
  }

  /// Check and trigger celebration animation
  void _checkAndTriggerCelebration(bool wasAllCompletedBefore) {
    // Conditions: 1. Not all completed before 2. All completed now 3. Not triggered today 4. Is today's task
    if (!wasAllCompletedBefore &&
        _areAllTodayTasksCompleted() &&
        !CelebrationService.instance.hasTriggeredToday()) {
      // Mark as triggered
      CelebrationService.instance.markTriggeredToday();

      // Play celebration sound
      AudioService.instance.playCelebration();

      // Delay briefly to allow status update animation to complete first
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showCelebrationOverlay(context);
        }
      });
    }
  }

  void _handleTaskTap(Task task) {
    // 显示更新任务浮层
    showUpdateTaskSheet(
      context,
      task: task,
      onSave: (title, priority, date) {
        _handleUpdateTask(task, title, priority, date);
      },
    );
  }

  /// 更新任务（标题/优先级/日期），调用后端 API
  Future<void> _handleUpdateTask(
    Task task,
    String newTitle,
    TaskPriority newPriority,
    DateTime newDate,
  ) async {
    // 判断哪些字段有变化
    final titleChanged = newTitle != task.title;
    final priorityChanged = newPriority != task.priority;
    final dateChanged = !_isSameDay(newDate, task.date);

    // 没有任何修改，直接返回
    if (!titleChanged && !priorityChanged && !dateChanged) return;

    // 乐观更新
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          title: newTitle,
          priority: newPriority,
          date: newDate,
        );
      }
    });

    final result = await TaskService.instance.updateTask(
      task.id,
      title: titleChanged ? newTitle : null,
      priority: priorityChanged ? newPriority.apiValue : null,
      date: dateChanged ? newDate : null,
    );

    if (result.isSuccess) {
      // 如果日期变了，任务不再属于当前日期，需要刷新列表
      if (dateChanged) {
        await _fetchTasks();
      }
    } else {
      // API 失败，回滚
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
        }
      });
      _showError(result.errorMessage ?? tr('error_server'));
    }
  }

  /// 删除任务（乐观更新 + API 调用）
  Future<void> _handleDeleteTask(Task task) async {
    // 乐观更新：立即从列表移除
    final previousTasks = List<Task>.from(_tasks);
    setState(() {
      _tasks = _tasks.where((t) => t.id != task.id).toList();
    });

    final result = await TaskService.instance.deleteTask(task.id);

    if (!result.isSuccess) {
      // API 失败，回滚
      setState(() {
        _tasks = previousTasks;
      });
      _showError(result.errorMessage ?? tr('error_server'));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header - compressed padding
            PlanHeader(
              avatarPath: _selectedAvatar,
              nickname: _nickname,
              consecutiveDays: _consecutiveDays,
              onSettingsTap: () {
                AudioService.instance.playButton();
                widget.onSettingsTap?.call();
              },
            ),

            // Content area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Week Calendar
                    WeekCalendar(
                      selectedDate: _selectedDate,
                      onDateSelected: _handleDateSelected,
                      taskIndicators: _taskIndicators,
                    ),

                    // Return to Today button
                    if (!_isToday(_selectedDate))
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _buildReturnTodayButton(),
                      ),

                    SizedBox(height: _isToday(_selectedDate) ? 10 : 2),

                    // Eisenhower Matrix（实时跟随手指滑动、相邻日期预览、50% 阈值翻页/回弹）
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题固定，不参与滑动
                        buildEisenhowerMatrixTitle(),
                        // 可滑动四象限区域
                        SwipeableMatrixArea(
                          currentDate: _selectedDate,
                          currentTasks: _tasksForSelectedDate,
                          prevDayTasks: _prevDayTasks,
                          nextDayTasks: _nextDayTasks,
                          showCompleted: _showCompleted,
                          isLoading: _isLoading,
                          onTaskTap: _handleTaskTap,
                          onToggleTaskComplete: _handleToggleTaskComplete,
                          onDeleteTask: _handleDeleteTask,
                          onQuadrantTap: (priority) =>
                              handleAddTask(priority: priority),
                          onDateChanged: _handleMatrixDateChanged,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Motivational Quote (Dynamic)
                    QuoteCard(quote: _currentQuote),

                    const SizedBox(height: 16), // Space for bottom navigation
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnTodayButton() {
    return AnimatedOpacity(
      opacity: !_isToday(_selectedDate) ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: TextButton.icon(
        icon: const Icon(Icons.today, size: 16),
        label: Text(tr('back_to_today'), style: const TextStyle(fontSize: 13)),
        onPressed: _handleReturnToToday,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }

  void _showQuickAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Drag Handle and Close Button
              Stack(
                alignment: Alignment.center,
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Close Button (Right aligned)
                  Positioned(
                    right: 12,
                    top: 8,
                    child: GestureDetector(
                      onTap: () {
                        AudioService.instance.playButton();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('quick_add'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick Add Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: TaskPriority.values
                      .map((priority) => _buildQuickAddOption(priority))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddOption(TaskPriority priority) {
    final priorityColor = AppColors.getPriorityColor(priority.value);

    return GestureDetector(
      onTap: () {
        AudioService.instance.playButton();
        Navigator.of(context).pop();
        handleAddTask(priority: priority);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: priorityColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Priority Indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [priorityColor, priorityColor.withValues(alpha: 0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: priorityColor.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'P${priority.value}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('priority_p${priority.value}_label'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                  Text(
                    tr('priority_p${priority.value}_desc'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: priorityColor.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
