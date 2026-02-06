import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';

/// Task Card Component with swipe-to-delete
class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onAddSubTask;
  final VoidCallback? onDelete;
  final VoidCallback?
  onShowSubtasks; // New: tap subtask icon to show subtask list
  final ValueChanged<SubTask>? onToggleSubTaskComplete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onAddSubTask,
    this.onDelete,
    this.onShowSubtasks,
    this.onToggleSubTaskComplete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  bool _isSwipedOpen = false;
  double _dragOffset = 0;

  // Delete button size - small and subtle
  static const double _deleteButtonSize = 24.0;
  static const double _maxSlideDistance = 32.0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // Calculate reveal progress (0.0 to 1.0)
  double get _revealProgress =>
      (-_dragOffset / _maxSlideDistance).clamp(0.0, 1.0);

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;
      // Clamp: only allow left swipe, max distance limited
      _dragOffset = _dragOffset.clamp(-_maxSlideDistance, 0);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    // If dragged more than half, snap open; otherwise snap closed
    if (_dragOffset < -_maxSlideDistance / 2) {
      _animateTo(-_maxSlideDistance);
      _isSwipedOpen = true;
    } else {
      _animateTo(0);
      _isSwipedOpen = false;
    }
  }

  void _animateTo(double target) {
    final startOffset = _dragOffset;
    final animation = Tween<double>(
      begin: startOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    void listener() {
      setState(() {
        _dragOffset = animation.value;
      });
    }

    animation.addListener(listener);
    _slideController.forward(from: 0).then((_) {
      animation.removeListener(listener);
    });
  }

  void _closeSwipe() {
    _animateTo(0);
    _isSwipedOpen = false;
  }

  void _handleDelete() {
    AudioService.instance.playButton();
    _closeSwipe();
    widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Get priority color for delete button
    final priorityColor = AppColors.getPriorityColor(
      widget.task.priority.value,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      // ClipRect ensures content stays within bounds
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Delete button (gradually revealed based on drag progress)
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _handleDelete,
                      child: Opacity(
                        // Gradually appear based on drag progress
                        opacity: _revealProgress,
                        child: Transform.translate(
                          // Slide in from right as user drags
                          offset: Offset(8 * (1 - _revealProgress), 0),
                          child: Transform.scale(
                            // Slightly grow as it reveals
                            scale: 0.7 + (0.3 * _revealProgress),
                            child: Container(
                              width: _deleteButtonSize,
                              height: _deleteButtonSize,
                              decoration: BoxDecoration(
                                // Use priority color with subtle transparency
                                color: priorityColor.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Main card content (slides left within bounds)
                Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: GestureDetector(
                    onTap: () {
                      if (_isSwipedOpen) {
                        _closeSwipe();
                      } else {
                        widget.onTap?.call();
                      }
                    },
                    onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                    onHorizontalDragEnd: _handleHorizontalDragEnd,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: constraints.maxWidth,
                      color: AppColors.cardBackground,
                      child: _buildMainTaskRow(priorityColor),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainTaskRow(Color priorityColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 改为顶部对齐，支持多行文本
      children: [
        // Checkbox - 加点上边距让它与第一行文字对齐
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _buildCheckbox(
            isChecked: widget.task.isCompleted,
            onTap: widget.onToggleComplete,
          ),
        ),
        const SizedBox(width: 8),
        // Task content with animation - 允许多行显示
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.task.isCompleted
                  ? AppColors.textHint
                  : AppColors.textPrimary,
              decoration: widget.task.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: AppColors.textHint,
            ),
            child: Text(
              widget.task.title,
              // 移除 maxLines 和 overflow，允许文字换行显示
            ),
          ),
        ),
        // Subtask icon (only shown when task has subtasks)
        if (widget.task.hasSubTasks) ...[
          const SizedBox(width: 4),
          // 加点上边距让图标与第一行文字对齐
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: GestureDetector(
              onTap: () {
                // Close swipe first if open
                if (_isSwipedOpen) {
                  _closeSwipe();
                }
                widget.onShowSubtasks?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.format_list_bulleted,
                      size: 12,
                      color: priorityColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.task.subTasks.where((s) => s.isCompleted).length}/${widget.task.subTasks.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: priorityColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckbox({
    required bool isChecked,
    VoidCallback? onTap,
    double size = 16,
  }) {
    final priorityColor = AppColors.getPriorityColor(
      widget.task.priority.value,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isChecked ? priorityColor : Colors.transparent,
          border: Border.all(
            color: isChecked ? priorityColor : AppColors.border,
            width: 1.5,
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isChecked ? 1.0 : 0.0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isChecked ? 1.0 : 0.5,
            child: Icon(
              Icons.check,
              size: size - 6,
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
