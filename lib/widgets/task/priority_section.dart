import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';
import 'task_card.dart';

/// Priority Section Component
class PrioritySection extends StatelessWidget {
  final TaskPriority priority;
  final List<Task> tasks;
  final bool showCompleted;
  final ValueChanged<Task>? onTaskTap;
  final ValueChanged<Task>? onToggleTaskComplete;
  final void Function(Task, SubTask)? onToggleSubTaskComplete;
  final ValueChanged<Task>? onDeleteTask;
  final ValueChanged<Task>? onShowSubtasks; // New: show subtask list
  final VoidCallback? onSectionTap;
  final double height;

  const PrioritySection({
    super.key,
    required this.priority,
    required this.tasks,
    this.showCompleted = true,
    this.onTaskTap,
    this.onToggleTaskComplete,
    this.onToggleSubTaskComplete,
    this.onDeleteTask,
    this.onShowSubtasks,
    this.onSectionTap,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    // 过滤任务
    final displayTasks = showCompleted
        ? tasks
        : tasks.where((t) => !t.isCompleted).toList();

    return GestureDetector(
      onTap: () {
        AudioService.instance.playButton();
        onSectionTap?.call();
      }, // 点击整个区域触发快捷创建
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height, // 固定高度
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 区块标题
              _buildSectionHeader(),
              const SizedBox(height: 8),
              // 任务列表 - 可滚动（任务多时支持下滑）
              Expanded(
                child: displayTasks.isEmpty
                    ? _buildEmptyState()
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: displayTasks.length,
                          itemBuilder: (context, index) {
                            final task = displayTasks[index];
                            return TaskCard(
                              task: task,
                              onTap: () => onTaskTap?.call(task),
                              onToggleComplete: () =>
                                  onToggleTaskComplete?.call(task),
                              onToggleSubTaskComplete: (subTask) =>
                                  onToggleSubTaskComplete?.call(task, subTask),
                              onDelete: () => onDeleteTask?.call(task),
                              onShowSubtasks: () => onShowSubtasks?.call(task),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedTitle() {
    switch (priority) {
      case TaskPriority.p0:
        return tr('quadrant_p0_title');
      case TaskPriority.p1:
        return tr('quadrant_p1_title');
      case TaskPriority.p2:
        return tr('quadrant_p2_title');
      case TaskPriority.p3:
        return tr('quadrant_p3_title');
    }
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        // 优先级指示点
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.getPriorityColor(priority.value),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        // 标题 (localized)
        Text(
          _getLocalizedTitle(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.getPriorityColor(priority.value),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        tr('no_tasks'),
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textHint,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
