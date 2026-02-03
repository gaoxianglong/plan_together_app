import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';
import 'priority_section.dart';

/// Eisenhower Matrix Component
class EisenhowerMatrix extends StatelessWidget {
  final List<Task> tasks;
  final bool showCompleted;
  final ValueChanged<Task>? onTaskTap;
  final ValueChanged<Task>? onToggleTaskComplete;
  final void Function(Task, SubTask)? onToggleSubTaskComplete;
  final ValueChanged<Task>? onDeleteTask;
  final ValueChanged<Task>? onShowSubtasks; // New: show subtask list
  final ValueChanged<TaskPriority>? onQuadrantTap;

  const EisenhowerMatrix({
    super.key,
    required this.tasks,
    this.showCompleted = true,
    this.onTaskTap,
    this.onToggleTaskComplete,
    this.onToggleSubTaskComplete,
    this.onDeleteTask,
    this.onShowSubtasks,
    this.onQuadrantTap,
  });

  @override
  Widget build(BuildContext context) {
    // 按优先级分组任务
    final p0Tasks = tasks.where((t) => t.priority == TaskPriority.p0).toList();
    final p1Tasks = tasks.where((t) => t.priority == TaskPriority.p1).toList();
    final p2Tasks = tasks.where((t) => t.priority == TaskPriority.p2).toList();
    final p3Tasks = tasks.where((t) => t.priority == TaskPriority.p3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tr('eisenhower_matrix'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        // 2x2 网格布局
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // 第一行：P0 和 P1
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PrioritySection(
                      priority: TaskPriority.p0,
                      tasks: p0Tasks,
                      showCompleted: showCompleted,
                      onTaskTap: onTaskTap,
                      onToggleTaskComplete: onToggleTaskComplete,
                      onToggleSubTaskComplete: onToggleSubTaskComplete,
                      onDeleteTask: onDeleteTask,
                      onShowSubtasks: onShowSubtasks,
                      onSectionTap: () => onQuadrantTap?.call(TaskPriority.p0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrioritySection(
                      priority: TaskPriority.p1,
                      tasks: p1Tasks,
                      showCompleted: showCompleted,
                      onTaskTap: onTaskTap,
                      onToggleTaskComplete: onToggleTaskComplete,
                      onToggleSubTaskComplete: onToggleSubTaskComplete,
                      onDeleteTask: onDeleteTask,
                      onShowSubtasks: onShowSubtasks,
                      onSectionTap: () => onQuadrantTap?.call(TaskPriority.p1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2: P2 and P3
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PrioritySection(
                      priority: TaskPriority.p2,
                      tasks: p2Tasks,
                      showCompleted: showCompleted,
                      onTaskTap: onTaskTap,
                      onToggleTaskComplete: onToggleTaskComplete,
                      onToggleSubTaskComplete: onToggleSubTaskComplete,
                      onDeleteTask: onDeleteTask,
                      onShowSubtasks: onShowSubtasks,
                      onSectionTap: () => onQuadrantTap?.call(TaskPriority.p2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrioritySection(
                      priority: TaskPriority.p3,
                      tasks: p3Tasks,
                      showCompleted: showCompleted,
                      onTaskTap: onTaskTap,
                      onToggleTaskComplete: onToggleTaskComplete,
                      onToggleSubTaskComplete: onToggleSubTaskComplete,
                      onDeleteTask: onDeleteTask,
                      onShowSubtasks: onShowSubtasks,
                      onSectionTap: () => onQuadrantTap?.call(TaskPriority.p3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
