/// Task Priority Enum
enum TaskPriority {
  p0(0, 'DO FIRST', 'Urgent & Important'),
  p1(1, 'SCHEDULE', 'Important, Not Urgent'),
  p2(2, 'DELEGATE', 'Urgent, Not Important'),
  p3(3, 'ELIMINATE', 'Not Urgent or Important');

  final int value;
  final String label;
  final String description;

  const TaskPriority(this.value, this.label, this.description);

  static TaskPriority fromValue(int value) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.p1,
    );
  }
}

/// Task Status Enum
enum TaskStatus {
  incomplete('Incomplete'),
  completed('Completed');

  final String label;

  const TaskStatus(this.label);
}

/// 重复类型枚举
enum RepeatType {
  none('None'),
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly');

  final String label;

  const RepeatType(this.label);
}

/// 子任务模型
class SubTask {
  final String id;
  final String parentId;
  final String title;
  final TaskStatus status;
  final RepeatType repeatType;
  final List<int>? weekdays; // 每周重复时的星期几
  final int? dayOfMonth; // 每月重复时的日期
  final DateTime createdAt;
  final DateTime? completedAt;

  const SubTask({
    required this.id,
    required this.parentId,
    required this.title,
    this.status = TaskStatus.incomplete,
    this.repeatType = RepeatType.none,
    this.weekdays,
    this.dayOfMonth,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;

  SubTask copyWith({
    String? id,
    String? parentId,
    String? title,
    TaskStatus? status,
    RepeatType? repeatType,
    List<int>? weekdays,
    int? dayOfMonth,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return SubTask(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      status: status ?? this.status,
      repeatType: repeatType ?? this.repeatType,
      weekdays: weekdays ?? this.weekdays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// 任务模型
class Task {
  final String id;
  final String userId;
  final String title;
  final TaskPriority priority;
  final DateTime date; // 归属日期
  final TaskStatus status;
  final List<SubTask> subTasks;
  final RepeatType repeatType;
  final List<int>? weekdays; // 每周重复时的星期几
  final int? dayOfMonth; // 每月重复时的日期
  final bool isRepeatInstance;
  final String? repeatParentId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.priority,
    required this.date,
    this.status = TaskStatus.incomplete,
    this.subTasks = const [],
    this.repeatType = RepeatType.none,
    this.weekdays,
    this.dayOfMonth,
    this.isRepeatInstance = false,
    this.repeatParentId,
    required this.createdAt,
    this.completedAt,
    this.deletedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;
  bool get hasSubTasks => subTasks.isNotEmpty;
  bool get isRepeating => repeatType != RepeatType.none;

  /// 计算逾期天数
  int get overdueDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    if (taskDate.isBefore(today)) {
      return today.difference(taskDate).inDays;
    }
    return 0;
  }

  bool get isOverdue => overdueDays > 0 && !isCompleted;

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    TaskPriority? priority,
    DateTime? date,
    TaskStatus? status,
    List<SubTask>? subTasks,
    RepeatType? repeatType,
    List<int>? weekdays,
    int? dayOfMonth,
    bool? isRepeatInstance,
    String? repeatParentId,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? deletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      status: status ?? this.status,
      subTasks: subTasks ?? this.subTasks,
      repeatType: repeatType ?? this.repeatType,
      weekdays: weekdays ?? this.weekdays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isRepeatInstance: isRepeatInstance ?? this.isRepeatInstance,
      repeatParentId: repeatParentId ?? this.repeatParentId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
