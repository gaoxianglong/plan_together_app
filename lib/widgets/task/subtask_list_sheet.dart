import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';

/// Subtask List Sheet Component
/// Shows all subtasks of a parent task with toggle complete and swipe-to-delete
class SubtaskListSheet extends StatefulWidget {
  final Task parentTask;
  final VoidCallback? onClose;
  final ValueChanged<SubTask>? onToggleSubtaskComplete;
  final ValueChanged<SubTask>? onDeleteSubtask;
  final void Function(SubTask subtask, String newTitle)? onSubtaskTitleChanged;
  final VoidCallback? onAddSubtask;

  const SubtaskListSheet({
    super.key,
    required this.parentTask,
    this.onClose,
    this.onToggleSubtaskComplete,
    this.onDeleteSubtask,
    this.onSubtaskTitleChanged,
    this.onAddSubtask,
  });

  @override
  State<SubtaskListSheet> createState() => _SubtaskListSheetState();
}

class _SubtaskListSheetState extends State<SubtaskListSheet> {
  // Local copy of subtasks for immediate UI updates
  late List<SubTask> _localSubtasks;

  @override
  void initState() {
    super.initState();
    _localSubtasks = List<SubTask>.from(widget.parentTask.subTasks);
  }

  @override
  void didUpdateWidget(covariant SubtaskListSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local subtasks if parent task changes (e.g. subtask added externally)
    if (widget.parentTask.subTasks.length != oldWidget.parentTask.subTasks.length) {
      _localSubtasks = List<SubTask>.from(widget.parentTask.subTasks);
    }
  }

  void _handleClose() {
    AudioService.instance.playButton();
    widget.onClose?.call();
    Navigator.of(context).pop();
  }

  /// Toggle subtask completion - update local state immediately
  void _handleToggleSubtask(SubTask subtask) {
    setState(() {
      final index = _localSubtasks.indexWhere((s) => s.id == subtask.id);
      if (index != -1) {
        final newStatus = subtask.isCompleted
            ? TaskStatus.incomplete
            : TaskStatus.completed;
        _localSubtasks[index] = subtask.copyWith(
          status: newStatus,
          completedAt: newStatus == TaskStatus.completed
              ? DateTime.now()
              : null,
        );
      }
    });
    // Also notify parent to persist the change
    widget.onToggleSubtaskComplete?.call(subtask);
  }

  /// Delete subtask - update local state immediately
  void _handleDeleteSubtask(SubTask subtask) {
    setState(() {
      _localSubtasks.removeWhere((s) => s.id == subtask.id);
    });
    // Also notify parent to persist the change
    widget.onDeleteSubtask?.call(subtask);
  }

  /// Update subtask title - update local state immediately
  void _handleSubtaskTitleChanged(SubTask subtask, String newTitle) {
    if (newTitle.trim().isEmpty) return;
    setState(() {
      final index = _localSubtasks.indexWhere((s) => s.id == subtask.id);
      if (index != -1) {
        _localSubtasks[index] = subtask.copyWith(title: newTitle.trim());
      }
    });
    // Also notify parent to persist the change
    widget.onSubtaskTitleChanged?.call(subtask, newTitle.trim());
  }

  /// Get subtasks sorted by creation time (newest first)
  List<SubTask> get _sortedSubtasks {
    final subtasks = List<SubTask>.from(_localSubtasks);
    subtasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return subtasks;
  }

  /// Get completed count from local state
  int get _completedCount => _localSubtasks.where((s) => s.isCompleted).length;
  int get _totalCount => _localSubtasks.length;

  @override
  Widget build(BuildContext context) {
    // Use P0 color for global consistency across all quadrants
    const themeColor = AppColors.priorityP0;

    // Priority color only for the badge display
    final badgeColor = AppColors.getPriorityColor(
      widget.parentTask.priority.value,
    );

    // Use P0 color for sheet background (very light tint)
    final sheetBackgroundColor = AppColors.cardBackground;

    return Container(
      decoration: BoxDecoration(
        color: sheetBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(themeColor, badgeColor),

          // Parent task info
          _buildParentTaskInfo(themeColor, badgeColor),

          // Subtask list
          _buildSubtaskList(themeColor),

          // Add Subtask Button
          _buildAddSubtaskButton(themeColor),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildAddSubtaskButton(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: _handleAddSubtask,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.priorityP0,
                AppColors.priorityP1,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(26),
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
                tr('add_subtask'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.add, size: 22, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAddSubtask() {
    Navigator.of(context).pop();
    widget.onAddSubtask?.call();
  }

  Widget _buildHeader(Color themeColor, Color badgeColor) {
    return Stack(
      children: [
        Column(
          children: [
            // Drag handle
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
            // Title with priority label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 48, 0),
              child: Row(
                children: [
                  Text(
                    tr('subtasks_title'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: themeColor, // Use P0 color for title
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Priority badge - uses actual priority color
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'P${widget.parentTask.priority.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Close button (X) in top right - uses P0 color
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: _handleClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 18, color: themeColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParentTaskInfo(Color themeColor, Color badgeColor) {
    final completedCount = _completedCount;
    final totalCount = _totalCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight, // Use surfaceLight for consistency
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Priority indicator dot - uses actual priority color
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.parentTask.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: themeColor.withValues(alpha: 0.9), // Use P0 color
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$completedCount/$totalCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: themeColor, // Use P0 color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskList(Color themeColor) {
    final subtasks = _sortedSubtasks;

    // Fixed height container for consistent layout
    const fixedHeight = 220.0;

    // Subtask list background uses P0 color with light tint
    final listBackgroundColor = AppColors.surfaceLight;

    if (subtasks.isEmpty) {
      return Container(
        height: fixedHeight,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: listBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            tr('no_subtasks_yet'),
            style: TextStyle(
              fontSize: 14,
              color: themeColor.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      height: fixedHeight, // Fixed height, scrollable when content exceeds
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: listBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: subtasks.length,
          itemBuilder: (context, index) {
            final subtask = subtasks[index];
            return _SubtaskItem(
              subtask: subtask,
              priorityColor: themeColor, // Use P0 color for all items
              onToggleComplete: () => _handleToggleSubtask(subtask),
              onDelete: () => _handleDeleteSubtask(subtask),
              onTitleChanged: (newTitle) =>
                  _handleSubtaskTitleChanged(subtask, newTitle),
            );
          },
        ),
      ),
    );
  }
}

/// Individual subtask item with swipe-to-delete (swipe LEFT like parent tasks)
class _SubtaskItem extends StatefulWidget {
  final SubTask subtask;
  final Color priorityColor;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;
  final void Function(String newTitle)? onTitleChanged;

  const _SubtaskItem({
    required this.subtask,
    required this.priorityColor,
    this.onToggleComplete,
    this.onDelete,
    this.onTitleChanged,
  });

  @override
  State<_SubtaskItem> createState() => _SubtaskItemState();
}

class _SubtaskItemState extends State<_SubtaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  bool _isSwipedOpen = false;
  double _dragOffset = 0;

  // Editing state
  bool _isEditing = false;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();

  // Swipe LEFT to reveal delete button on RIGHT side (same as parent tasks)
  static const double _deleteButtonSize = 24.0;
  static const double _maxSlideDistance = 36.0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _titleController = TextEditingController(text: widget.subtask.title);
    _titleFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _SubtaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller if subtask title changed externally
    if (widget.subtask.title != oldWidget.subtask.title && !_isEditing) {
      _titleController.text = widget.subtask.title;
    }
  }

  void _onFocusChange() {
    if (!_titleFocusNode.hasFocus && _isEditing) {
      _finishEditing();
    }
  }

  void _startEditing() {
    if (_isSwipedOpen) {
      _closeSwipe();
      return;
    }
    setState(() {
      _isEditing = true;
    });
    _titleFocusNode.requestFocus();
  }

  void _finishEditing() {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.subtask.title) {
      widget.onTitleChanged?.call(newTitle);
    } else if (newTitle.isEmpty) {
      // Restore original title if empty
      _titleController.text = widget.subtask.title;
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _titleController.dispose();
    _titleFocusNode.removeListener(_onFocusChange);
    _titleFocusNode.dispose();
    super.dispose();
  }

  // Reveal progress based on negative offset (left swipe)
  double get _revealProgress =>
      (-_dragOffset / _maxSlideDistance).clamp(0.0, 1.0);

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;
      // Clamp: only allow left swipe (negative), max distance limited
      _dragOffset = _dragOffset.clamp(-_maxSlideDistance, 0);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
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
    // Finish editing first if in editing mode
    if (_isEditing) {
      _finishEditing();
    }
    _closeSwipe();
    widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ClipRect(
        child: Stack(
          children: [
            // Delete button (revealed on RIGHT side when swiping LEFT)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _handleDelete,
                  child: Opacity(
                    opacity: _revealProgress,
                    child: Transform.translate(
                      offset: Offset(8 * (1 - _revealProgress), 0),
                      child: Transform.scale(
                        scale: 0.7 + (0.3 * _revealProgress),
                        child: Container(
                          width: _deleteButtonSize,
                          height: _deleteButtonSize,
                          decoration: BoxDecoration(
                            color: widget.priorityColor.withValues(alpha: 0.85),
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
            // Main content (slides left)
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Container(
                // Use priority color with light tint for item background
                color: AppColors.surfaceLight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Checkbox with expanded touch area
                    GestureDetector(
                      onTap: () {
                        // Finish editing first if in editing mode
                        if (_isEditing) {
                          _finishEditing();
                        }
                        widget.onToggleComplete?.call();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 36,
                        alignment: Alignment.center,
                        child: _buildCheckbox(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Subtask title area - editable on tap
                    Expanded(
                      child: GestureDetector(
                        onTap: _startEditing,
                        onHorizontalDragUpdate: _isEditing
                            ? null
                            : _handleHorizontalDragUpdate,
                        onHorizontalDragEnd: _isEditing
                            ? null
                            : _handleHorizontalDragEnd,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 36,
                          alignment: Alignment.centerLeft,
                          child: _isEditing
                              ? TextField(
                                  controller: _titleController,
                                  focusNode: _titleFocusNode,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                  maxLines: 1,
                                  onSubmitted: (_) => _finishEditing(),
                                )
                              : AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: widget.subtask.isCompleted
                                        ? AppColors.textHint
                                        : AppColors.textPrimary,
                                    decoration: widget.subtask.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    decorationColor: AppColors.textHint,
                                  ),
                                  child: Text(
                                    widget.subtask.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Edit icon - shows pen when not editing, check when editing
                    GestureDetector(
                      onTap: _isEditing ? _finishEditing : _startEditing,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 28,
                        height: 36,
                        alignment: Alignment.center,
                        child: Icon(
                          _isEditing ? Icons.check : Icons.edit_outlined,
                          size: 14,
                          color: widget.priorityColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    const size = 18.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.subtask.isCompleted
            ? widget.priorityColor
            : Colors.transparent,
        border: Border.all(
          color: widget.subtask.isCompleted
              ? widget.priorityColor
              : AppColors.border,
          width: 1.5,
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: widget.subtask.isCompleted ? 1.0 : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: widget.subtask.isCompleted ? 1.0 : 0.5,
          child: Icon(
            Icons.check,
            size: size - 6,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }
}

/// Show subtask list sheet
Future<void> showSubtaskListSheet(
  BuildContext context, {
  required Task parentTask,
  ValueChanged<SubTask>? onToggleSubtaskComplete,
  ValueChanged<SubTask>? onDeleteSubtask,
  void Function(SubTask subtask, String newTitle)? onSubtaskTitleChanged,
  VoidCallback? onAddSubtask,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SubtaskListSheet(
      parentTask: parentTask,
      onToggleSubtaskComplete: onToggleSubtaskComplete,
      onDeleteSubtask: onDeleteSubtask,
      onSubtaskTitleChanged: onSubtaskTitleChanged,
      onAddSubtask: onAddSubtask,
    ),
  );
}
