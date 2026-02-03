import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../widgets/calendar/week_calendar.dart';
import '../../widgets/common/plan_header.dart';
import '../../widgets/common/quote_card.dart';
import '../../widgets/common/celebration_overlay.dart';
import '../../widgets/task/add_task_sheet.dart';
import '../../widgets/task/add_subtask_sheet.dart';
import '../../widgets/task/subtask_list_sheet.dart';
import '../../widgets/task/eisenhower_matrix.dart';
import '../../services/quote_service.dart';
import '../../services/celebration_service.dart';
import '../../services/audio_service.dart';
import '../../services/avatar_service.dart';
import '../../services/nickname_service.dart';
import '../../services/locale_service.dart';

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
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    _avatarSubscription?.cancel();
    _nicknameSubscription?.cancel();
    _languageSubscription?.cancel();
    super.dispose();
  }

  // Mock data (changed to mutable list to support status updates)
  List<Task> _mockTasks = [
    Task(
      id: '1',
      userId: 'user1',
      title: 'Complete UI Redesign',
      priority: TaskPriority.p0,
      date: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Task(
      id: '2',
      userId: 'user1',
      title: 'Client meeting 2PM',
      priority: TaskPriority.p0,
      date: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Task(
      id: '3',
      userId: 'user1',
      title: 'Gym workout session',
      priority: TaskPriority.p1,
      date: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Task(
      id: '4',
      userId: 'user1',
      title: 'Read 20 pages',
      priority: TaskPriority.p1,
      date: DateTime.now(),
      status: TaskStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      completedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Task(
      id: '5',
      userId: 'user1',
      title: 'Respond to emails',
      priority: TaskPriority.p2,
      date: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Task(
      id: '6',
      userId: 'user1',
      title: 'Grocery delivery',
      priority: TaskPriority.p2,
      date: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Task(
      id: '7',
      userId: 'user1',
      title: 'Social media scrolling',
      priority: TaskPriority.p3,
      date: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
    ),
    Task(
      id: '8',
      userId: 'user1',
      title: 'Check junk mail',
      priority: TaskPriority.p3,
      date: DateTime.now(),
      status: TaskStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      completedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }

  List<Task> get _tasksForSelectedDate {
    return _mockTasks
        .where((task) => _isSameDay(task.date, _selectedDate))
        .toList();
  }

  Map<DateTime, List<int>> get _taskIndicators {
    final indicators = <DateTime, List<int>>{};
    for (final task in _mockTasks) {
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
    // Sort by priority
    for (final entry in indicators.entries) {
      entry.value.sort();
    }
    return indicators;
  }

  void _handleDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _handleReturnToToday() {
    // Play page turn sound
    AudioService.instance.playPageTurn();
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  /// Generate unique task ID
  String _generateTaskId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}_${_mockTasks.length}';
  }

  /// Public method: Add task
  void handleAddTask({TaskPriority? priority}) {
    showAddTaskSheet(
      context,
      selectedDate: _selectedDate,
      defaultPriority: priority,
      onSave: (title, taskPriority, repeatType, weekdays, dayOfMonth) {
        // Create new task and add to list
        _createTask(title, taskPriority, repeatType, weekdays, dayOfMonth);
      },
    );
  }

  /// Create task
  void _createTask(
    String title,
    TaskPriority priority,
    RepeatType repeatType,
    List<int>? weekdays,
    int? dayOfMonth,
  ) {
    // Determine task date (past dates automatically adjusted to today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final taskDate = selectedDay.isBefore(today) ? today : selectedDay;

    // Create new task
    final newTask = Task(
      id: _generateTaskId(),
      userId: 'user1',
      title: title,
      priority: priority,
      date: taskDate,
      repeatType: repeatType,
      weekdays: weekdays,
      dayOfMonth: dayOfMonth,
      createdAt: DateTime.now(),
    );

    // Add to task list and update UI
    setState(() {
      _mockTasks = [newTask, ..._mockTasks]; // New task placed at the beginning
    });

    debugPrint(
      'Created task: ${newTask.title}, priority: P${priority.value}, date: $taskDate',
    );
  }

  /// Public method: Show quick add menu
  void showQuickAddMenu() {
    _showQuickAddMenu();
  }

  /// Toggle task completion status (also toggles all subtasks)
  void _handleToggleTaskComplete(Task task) {
    final wasAllCompleted = _areAllTodayTasksCompleted();

    setState(() {
      final index = _mockTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final currentTask = _mockTasks[index];
        final newStatus = currentTask.isCompleted
            ? TaskStatus.incomplete
            : TaskStatus.completed;
        final now = DateTime.now();

        // Also update all subtasks to match parent status
        final updatedSubtasks = currentTask.subTasks.map((subTask) {
          return subTask.copyWith(
            status: newStatus,
            completedAt: newStatus == TaskStatus.completed ? now : null,
          );
        }).toList();

        _mockTasks[index] = currentTask.copyWith(
          status: newStatus,
          completedAt: newStatus == TaskStatus.completed ? now : null,
          subTasks: updatedSubtasks,
        );
      }
    });

    // Check if celebration animation is triggered
    _checkAndTriggerCelebration(wasAllCompleted);
  }

  /// Check if all today's tasks are completed
  bool _areAllTodayTasksCompleted() {
    final todayTasks = _getTodayTasks();
    if (todayTasks.isEmpty) return false;
    return todayTasks.every((task) => task.isCompleted);
  }

  /// Get today's tasks
  List<Task> _getTodayTasks() {
    final now = DateTime.now();
    return _mockTasks.where((task) {
      return task.date.year == now.year &&
          task.date.month == now.month &&
          task.date.day == now.day;
    }).toList();
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

  /// Toggle subtask completion status (also updates parent task status)
  void _handleToggleSubTaskComplete(Task task, SubTask subTask) {
    final wasAllCompleted = _areAllTodayTasksCompleted();

    setState(() {
      final taskIndex = _mockTasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        final currentTask = _mockTasks[taskIndex];
        final subTaskIndex = currentTask.subTasks.indexWhere(
          (s) => s.id == subTask.id,
        );
        if (subTaskIndex != -1) {
          final newSubtaskStatus = subTask.isCompleted
              ? TaskStatus.incomplete
              : TaskStatus.completed;
          final updatedSubTasks = List<SubTask>.from(currentTask.subTasks);
          updatedSubTasks[subTaskIndex] = subTask.copyWith(
            status: newSubtaskStatus,
            completedAt: newSubtaskStatus == TaskStatus.completed
                ? DateTime.now()
                : null,
          );

          // Check if all subtasks are now completed
          final allSubtasksCompleted =
              updatedSubTasks.isNotEmpty &&
              updatedSubTasks.every((s) => s.isCompleted);

          // Update parent task status based on subtasks
          TaskStatus newParentStatus;
          DateTime? completedAt;
          if (allSubtasksCompleted) {
            newParentStatus = TaskStatus.completed;
            completedAt = DateTime.now();
          } else {
            newParentStatus = TaskStatus.incomplete;
            completedAt = null;
          }

          _mockTasks[taskIndex] = currentTask.copyWith(
            subTasks: updatedSubTasks,
            status: newParentStatus,
            completedAt: completedAt,
          );
        }
      }
    });

    // Check celebration trigger
    _checkAndTriggerCelebration(wasAllCompleted);
  }

  /// Toggle subtask completion status from sheet
  void _handleToggleSubtaskFromSheet(Task task, SubTask subTask) {
    _handleToggleSubTaskComplete(task, subTask);
  }

  /// Delete subtask
  void _handleDeleteSubtask(Task task, SubTask subTask) {
    setState(() {
      final taskIndex = _mockTasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        final currentTask = _mockTasks[taskIndex];
        final updatedSubtasks = currentTask.subTasks
            .where((s) => s.id != subTask.id)
            .toList();

        // Update parent task status based on remaining subtasks
        TaskStatus newParentStatus = currentTask.status;
        DateTime? completedAt = currentTask.completedAt;

        if (updatedSubtasks.isNotEmpty) {
          final allSubtasksCompleted = updatedSubtasks.every(
            (s) => s.isCompleted,
          );
          if (allSubtasksCompleted) {
            newParentStatus = TaskStatus.completed;
            completedAt = DateTime.now();
          } else {
            newParentStatus = TaskStatus.incomplete;
            completedAt = null;
          }
        }

        _mockTasks[taskIndex] = currentTask.copyWith(
          subTasks: updatedSubtasks,
          status: newParentStatus,
          completedAt: completedAt,
        );
      }
    });

    debugPrint('Deleted subtask: ${subTask.title}');
  }

  void _handleTaskTap(Task task) {
    // Show add subtask sheet
    showAddSubtaskSheet(
      context,
      parentTask: task,
      onSave: (title) {
        _handleAddSubtask(task, title);
      },
      onParentTaskTitleChanged: (newTitle) {
        _handleUpdateTaskTitle(task, newTitle);
      },
    );
  }

  /// Update parent task title (frontend only)
  void _handleUpdateTaskTitle(Task task, String newTitle) {
    setState(() {
      final taskIndex = _mockTasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        _mockTasks[taskIndex] = _mockTasks[taskIndex].copyWith(title: newTitle);
      }
    });
    debugPrint('Updated task title to: $newTitle');
  }

  /// Generate unique subtask ID
  String _generateSubtaskId() {
    return 'subtask_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Add subtask to a parent task
  SubTask _handleAddSubtask(Task parentTask, String title) {
    final newSubtask = SubTask(
      id: _generateSubtaskId(),
      parentId: parentTask.id,
      title: title,
      createdAt: DateTime.now(),
    );

    setState(() {
      final taskIndex = _mockTasks.indexWhere((t) => t.id == parentTask.id);
      if (taskIndex != -1) {
        final updatedSubtasks = [...parentTask.subTasks, newSubtask];
        _mockTasks[taskIndex] = parentTask.copyWith(subTasks: updatedSubtasks);
      }
    });

    debugPrint('Added subtask: $title to task: ${parentTask.title}');
    return newSubtask;
  }

  /// Delete task from list
  void _handleDeleteTask(Task task) {
    setState(() {
      _mockTasks = _mockTasks.where((t) => t.id != task.id).toList();
    });
    debugPrint('Deleted task: ${task.title}');
  }

  /// Show subtask list sheet
  void _handleShowSubtasks(Task task) {
    // Get the latest task data
    final currentTask = _mockTasks.firstWhere(
      (t) => t.id == task.id,
      orElse: () => task,
    );

    showSubtaskListSheet(
      context,
      parentTask: currentTask,
      onToggleSubtaskComplete: (subTask) {
        // Toggle without closing/reopening sheet
        _handleToggleSubtaskFromSheet(currentTask, subTask);
      },
      onDeleteSubtask: (subTask) {
        _handleDeleteSubtask(currentTask, subTask);
      },
      onSubtaskTitleChanged: (subTask, newTitle) {
        _handleUpdateSubtaskTitle(currentTask, subTask, newTitle);
      },
      onAddSubtask: () {
        showAddSubtaskSheet(
          context,
          parentTask: currentTask,
          onSave: (title) {
            _handleAddSubtask(currentTask, title);
          },
          onParentTaskTitleChanged: (newTitle) {
            _handleUpdateTaskTitle(currentTask, newTitle);
          },
        );
      },
    );
  }

  /// Update subtask title (frontend only)
  void _handleUpdateSubtaskTitle(Task task, SubTask subTask, String newTitle) {
    setState(() {
      final taskIndex = _mockTasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        final currentTask = _mockTasks[taskIndex];
        final subTaskIndex = currentTask.subTasks.indexWhere(
          (s) => s.id == subTask.id,
        );
        if (subTaskIndex != -1) {
          final updatedSubTasks = List<SubTask>.from(currentTask.subTasks);
          updatedSubTasks[subTaskIndex] = subTask.copyWith(title: newTitle);
          _mockTasks[taskIndex] = currentTask.copyWith(
            subTasks: updatedSubTasks,
          );
        }
      }
    });
    debugPrint('Updated subtask title to: $newTitle');
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
              consecutiveDays: 7,
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

                    // Eisenhower Matrix
                    EisenhowerMatrix(
                      tasks: _tasksForSelectedDate,
                      showCompleted: _showCompleted,
                      onTaskTap: _handleTaskTap,
                      onToggleTaskComplete: _handleToggleTaskComplete,
                      onToggleSubTaskComplete: _handleToggleSubTaskComplete,
                      onDeleteTask: _handleDeleteTask,
                      onShowSubtasks: _handleShowSubtasks,
                      onQuadrantTap: (priority) =>
                          handleAddTask(priority: priority),
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
