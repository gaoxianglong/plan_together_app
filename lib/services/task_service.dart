import '../models/task.dart';
import 'api_client.dart';
import 'locale_service.dart';

/// 任务列表查询结果
class TaskListResult {
  final bool isSuccess;
  final List<Task> tasks;
  final Map<String, bool>? hasUncheckedTasks;
  final String? errorMessage;

  TaskListResult._({
    required this.isSuccess,
    this.tasks = const [],
    this.hasUncheckedTasks,
    this.errorMessage,
  });

  factory TaskListResult.success({
    List<Task> tasks = const [],
    Map<String, bool>? hasUncheckedTasks,
  }) => TaskListResult._(
    isSuccess: true,
    tasks: tasks,
    hasUncheckedTasks: hasUncheckedTasks,
  );

  factory TaskListResult.failure(String message) =>
      TaskListResult._(isSuccess: false, errorMessage: message);
}

/// 任务操作结果
class TaskResult {
  final bool isSuccess;
  final Task? task;
  final String? errorMessage;
  final int? errorCode;

  TaskResult._({
    required this.isSuccess,
    this.task,
    this.errorMessage,
    this.errorCode,
  });

  factory TaskResult.success({Task? task}) =>
      TaskResult._(isSuccess: true, task: task);

  factory TaskResult.failure(String message, {int? errorCode}) => TaskResult._(
    isSuccess: false,
    errorMessage: message,
    errorCode: errorCode,
  );
}

/// 图表数据点
class ChartDataPoint {
  final String label;
  final int completed;
  final int incomplete;
  final int total;
  final double completionRate;

  const ChartDataPoint({
    required this.label,
    required this.completed,
    required this.incomplete,
    required this.total,
    required this.completionRate,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] as String,
      completed: json['completed'] as int,
      incomplete: json['incomplete'] as int,
      total: json['total'] as int,
      completionRate: (json['completionRate'] as num).toDouble(),
    );
  }
}

/// 任务统计数据
class TaskStatsData {
  final String dimension; // WEEK / MONTH
  final String startDate;
  final String endDate;
  final int totalCompleted;
  final int totalTasks;
  final double totalCompletionRate;
  final List<ChartDataPoint> chartData;
  final List<Task> completedTasks;
  final List<Task> incompleteTasks;

  const TaskStatsData({
    required this.dimension,
    required this.startDate,
    required this.endDate,
    required this.totalCompleted,
    required this.totalTasks,
    required this.totalCompletionRate,
    required this.chartData,
    required this.completedTasks,
    required this.incompleteTasks,
  });

  factory TaskStatsData.fromJson(Map<String, dynamic> json) {
    return TaskStatsData(
      dimension: json['dimension'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      totalCompleted: json['totalCompleted'] as int,
      totalTasks: json['totalTasks'] as int,
      totalCompletionRate: (json['totalCompletionRate'] as num).toDouble(),
      chartData: (json['chartData'] as List<dynamic>)
          .map((e) => ChartDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      completedTasks: (json['completedTasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      incompleteTasks: (json['incompleteTasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 任务统计查询结果
class TaskStatsResult {
  final bool isSuccess;
  final TaskStatsData? data;
  final String? errorMessage;

  TaskStatsResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory TaskStatsResult.success(TaskStatsData data) =>
      TaskStatsResult._(isSuccess: true, data: data);

  factory TaskStatsResult.failure(String message) =>
      TaskStatsResult._(isSuccess: false, errorMessage: message);
}

/// 打卡结果
class CheckInResult {
  final bool isSuccess;
  final int consecutiveDays;
  final String? errorMessage;

  CheckInResult._({
    required this.isSuccess,
    this.consecutiveDays = 0,
    this.errorMessage,
  });

  factory CheckInResult.success({required int consecutiveDays}) =>
      CheckInResult._(isSuccess: true, consecutiveDays: consecutiveDays);

  factory CheckInResult.failure(String message) =>
      CheckInResult._(isSuccess: false, errorMessage: message);
}

/// 打卡连续天数查询结果
class CheckInStreakResult {
  final bool isSuccess;
  final int consecutiveDays;
  final String? lastCheckInDate;
  final String? errorMessage;

  CheckInStreakResult._({
    required this.isSuccess,
    this.consecutiveDays = 0,
    this.lastCheckInDate,
    this.errorMessage,
  });

  factory CheckInStreakResult.success({
    required int consecutiveDays,
    required String? lastCheckInDate,
  }) =>
      CheckInStreakResult._(
        isSuccess: true,
        consecutiveDays: consecutiveDays,
        lastCheckInDate: lastCheckInDate,
      );

  factory CheckInStreakResult.failure(String message) =>
      CheckInStreakResult._(isSuccess: false, errorMessage: message);
}

/// 任务服务 — 封装任务相关 API 调用
class TaskService {
  TaskService._();
  static final TaskService instance = TaskService._();

  /// 日期格式化为 API 使用的 YYYY-MM-DD 格式
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 查询任务列表（按日期）
  /// GET /api/v1/tasks
  Future<TaskListResult> fetchTasksByDate(
    DateTime date, {
    bool showCompleted = true,
  }) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '/tasks',
      queryParams: {
        'date': _formatDate(date),
        'showCompleted': showCompleted.toString(),
      },
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final tasksMap = response.data!['tasks'] as Map<String, dynamic>;
        final tasks = <Task>[];
        for (final entry in tasksMap.entries) {
          final taskList = entry.value as List<dynamic>;
          for (final taskJson in taskList) {
            tasks.add(Task.fromJson(taskJson as Map<String, dynamic>));
          }
        }

        // 解析各象限是否有未完成任务
        Map<String, bool>? hasUnchecked;
        if (response.data!['hasUncheckedTasks'] != null) {
          final raw =
              response.data!['hasUncheckedTasks'] as Map<String, dynamic>;
          hasUnchecked = raw.map((k, v) => MapEntry(k, v as bool));
        }

        return TaskListResult.success(
          tasks: tasks,
          hasUncheckedTasks: hasUnchecked,
        );
      } catch (e) {
        return TaskListResult.failure(tr('error_parse'));
      }
    } else {
      return TaskListResult.failure(response.message);
    }
  }

  /// 创建任务
  /// POST /api/v1/tasks
  Future<TaskResult> createTask({
    required String title,
    required String priority,
    required DateTime date,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/tasks',
      body: {
        'title': title,
        'priority': priority,
        'date': _formatDate(date),
      },
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      try {
        return TaskResult.success(task: Task.fromJson(response.data!));
      } catch (e) {
        // 创建成功但解析响应失败
        return TaskResult.success();
      }
    } else {
      return TaskResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 更新任务
  /// PUT /api/v1/tasks/{taskId}
  Future<TaskResult> updateTask(
    String taskId, {
    String? title,
    String? priority,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (priority != null) body['priority'] = priority;
    if (date != null) body['date'] = _formatDate(date);

    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      '/tasks/$taskId',
      body: body,
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess) {
      return TaskResult.success();
    } else {
      return TaskResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 删除任务
  /// DELETE /api/v1/tasks/{taskId}
  Future<TaskResult> deleteTask(String taskId) async {
    final response = await ApiClient.instance.delete<Map<String, dynamic>>(
      '/tasks/$taskId',
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess) {
      return TaskResult.success();
    } else {
      return TaskResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 完成/反完成任务
  /// POST /api/v1/tasks/{taskId}/toggle-complete
  Future<TaskResult> toggleComplete(String taskId, bool completed) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/tasks/$taskId/toggle-complete',
      body: {'completed': completed},
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess) {
      return TaskResult.success();
    } else {
      return TaskResult.failure(
        _getErrorMessage(response.code, response.message),
        errorCode: response.code,
      );
    }
  }

  /// 查询任务统计数据
  /// GET /api/v1/tasks/stats
  Future<TaskStatsResult> fetchTaskStats({
    required String dimension,
    required DateTime date,
    List<String>? priorities,
  }) async {
    final queryParams = <String, String>{
      'dimension': dimension,
      'date': _formatDate(date),
    };
    if (priorities != null && priorities.isNotEmpty) {
      queryParams['priorities'] = priorities.join(',');
    }

    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '/tasks/stats',
      queryParams: queryParams,
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      try {
        return TaskStatsResult.success(
          TaskStatsData.fromJson(response.data!),
        );
      } catch (e) {
        return TaskStatsResult.failure(tr('error_parse'));
      }
    } else {
      return TaskStatsResult.failure(response.message);
    }
  }

  /// 打卡
  /// POST /api/v1/check-in
  Future<CheckInResult> checkIn(DateTime date) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/check-in',
      body: {'date': _formatDate(date)},
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final consecutiveDays = response.data!['consecutiveDays'] as int;
        return CheckInResult.success(consecutiveDays: consecutiveDays);
      } catch (_) {
        return CheckInResult.success(consecutiveDays: 0);
      }
    } else {
      return CheckInResult.failure(response.message);
    }
  }

  /// 查询打卡连续天数
  /// GET /api/v1/check-in/streak
  Future<CheckInStreakResult> getCheckInStreak() async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '/check-in/streak',
      requireAuth: true,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final consecutiveDays = response.data!['consecutiveDays'] as int;
        final lastCheckInDate = response.data!['lastCheckInDate'] as String?;
        return CheckInStreakResult.success(
          consecutiveDays: consecutiveDays,
          lastCheckInDate: lastCheckInDate,
        );
      } catch (_) {
        return CheckInStreakResult.success(
          consecutiveDays: 0,
          lastCheckInDate: null,
        );
      }
    } else {
      return CheckInStreakResult.failure(response.message);
    }
  }

  /// 根据错误码获取错误信息
  String _getErrorMessage(int code, String defaultMessage) {
    switch (code) {
      case 3001:
        return tr('error_task_title_invalid');
      case 3002:
        return tr('error_task_date_out_of_range');
      case 3003:
        return tr('error_task_daily_limit');
      case 3009:
        return defaultMessage; // 任务不存在，使用后端返回的消息
      default:
        return defaultMessage;
    }
  }
}
