import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';

/// Add Subtask Sheet Component
/// Simplified version of AddTaskSheet - same visual style, only title + input + Save + X
class AddSubtaskSheet extends StatefulWidget {
  final Task parentTask;
  final VoidCallback? onCancel;
  final void Function(String title)? onSave;
  final void Function(String newParentTitle)? onParentTaskTitleChanged;

  const AddSubtaskSheet({
    super.key,
    required this.parentTask,
    this.onCancel,
    this.onSave,
    this.onParentTaskTitleChanged,
  });

  @override
  State<AddSubtaskSheet> createState() => _AddSubtaskSheetState();
}

class _AddSubtaskSheetState extends State<AddSubtaskSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _parentTitleController;
  bool _isEditingParentTitle = false;
  final FocusNode _parentTitleFocusNode = FocusNode();

  // Shake animation for validation error
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _parentTitleController = TextEditingController(
      text: widget.parentTask.title,
    );

    // Listen to focus changes for parent title
    _parentTitleFocusNode.addListener(_onParentTitleFocusChange);

    // Initialize shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _onParentTitleFocusChange() {
    if (!_parentTitleFocusNode.hasFocus && _isEditingParentTitle) {
      _finishEditingParentTitle();
    }
  }

  void _finishEditingParentTitle() {
    final newTitle = _parentTitleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.parentTask.title) {
      widget.onParentTaskTitleChanged?.call(newTitle);
    } else if (newTitle.isEmpty) {
      // Restore original title if empty
      _parentTitleController.text = widget.parentTask.title;
    }
    setState(() {
      _isEditingParentTitle = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _parentTitleController.dispose();
    _parentTitleFocusNode.removeListener(_onParentTitleFocusChange);
    _parentTitleFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _showInfoDialog(String message) {
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      AudioService.instance.playButton();
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(tr('got_it'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSave() {
    AudioService.instance.playButton();
    // Finish any pending parent title edit first
    if (_isEditingParentTitle) {
      _finishEditingParentTitle();
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _triggerValidationError();
      return;
    }

    if (title.length > 100) {
      _showInfoDialog(tr('subtask_name_too_long'));
      return;
    }

    widget.onSave?.call(title);
  }

  /// Trigger shake animation and show error message
  void _triggerValidationError() {
    _shakeController.reset();
    _shakeController.forward();

    setState(() {
      _showError = true;
    });

    // Auto-hide error after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showError = false;
        });
      }
    });
  }

  void _handleClose() {
    AudioService.instance.playButton();
    // Finish any pending parent title edit first
    if (_isEditingParentTitle) {
      _finishEditingParentTitle();
    }
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with drag handle, title and close button
          _buildHeader(),

          // Subtask input card
          _buildSubtaskInputCard(),

          // Save button
          _buildSaveButton(),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title - P0 red color, same as New Task
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 48, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('new_subtask'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.priorityP0,
                  ),
                ),
              ),
            ),
            // Parent task name - editable
            _buildParentTaskField(),
          ],
        ),
        // Close button (X) in top right
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: _handleClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
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
    );
  }

  Widget _buildParentTaskField() {
    final priorityColor = AppColors.getPriorityColor(
      widget.parentTask.priority.value,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isEditingParentTitle = true;
          });
          _parentTitleFocusNode.requestFocus();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: _isEditingParentTitle
                ? Border.all(
                    color: priorityColor.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Priority indicator dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              // Parent task title - editable
              Expanded(
                child: _isEditingParentTitle
                    ? TextField(
                        controller: _parentTitleController,
                        focusNode: _parentTitleFocusNode,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: priorityColor.withValues(alpha: 0.9),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        maxLines: 1,
                        onSubmitted: (_) => _finishEditingParentTitle(),
                      )
                    : Text(
                        _parentTitleController.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: priorityColor.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(width: 8),
              // Edit icon - tap to toggle editing
              GestureDetector(
                onTap: () {
                  if (_isEditingParentTitle) {
                    _finishEditingParentTitle();
                  } else {
                    setState(() {
                      _isEditingParentTitle = true;
                    });
                    _parentTitleFocusNode.requestFocus();
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  child: Icon(
                    _isEditingParentTitle ? Icons.check : Icons.edit_outlined,
                    size: 14,
                    color: priorityColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtaskInputCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap input in AnimatedBuilder for shake effect
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final shakeOffset =
                  _shakeAnimation.value *
                  8 *
                  (1 - _shakeAnimation.value) *
                  ((_shakeController.value * 8).floor() % 2 == 0 ? 1 : -1);
              return Transform.translate(
                offset: Offset(shakeOffset, 0),
                child: child,
              );
            },
            child: Column(
              children: [
                // Input field - minimal style, same as New Task
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: tr('what_needs_done'),
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  ),
                  maxLength: 100,
                  maxLines: 2,
                  minLines: 1,
                  onTap: () {
                    // Finish parent title editing when subtask input is tapped
                    if (_isEditingParentTitle) {
                      _finishEditingParentTitle();
                    }
                  },
                  onChanged: (_) {
                    if (_showError) {
                      setState(() {
                        _showError = false;
                      });
                    }
                  },
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                ),
                // Bottom accent underline - P0 to P1 gradient, same as New Task
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _showError
                          ? [
                              AppColors.error,
                              AppColors.error.withValues(alpha: 0.5),
                            ]
                          : [AppColors.priorityP0, AppColors.priorityP1],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          // Error message with fade animation
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showError ? 1.0 : 0.0,
              child: _showError
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        tr('invalid_subtask_name'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: GestureDetector(
        onTap: _handleSave,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            // P0 to P1 gradient, same as New Task
            gradient: const LinearGradient(
              colors: [
                AppColors.priorityP0, // P0 red
                AppColors.priorityP1, // P1 pink
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
                tr('save_subtask'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show add subtask sheet
Future<void> showAddSubtaskSheet(
  BuildContext context, {
  required Task parentTask,
  void Function(String title)? onSave,
  void Function(String newParentTitle)? onParentTaskTitleChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AddSubtaskSheet(
        parentTask: parentTask,
        onSave: (title) {
          onSave?.call(title);
          Navigator.of(context).pop();
        },
        onParentTaskTitleChanged: onParentTaskTitleChanged,
      ),
    ),
  );
}
