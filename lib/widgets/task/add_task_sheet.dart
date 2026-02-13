import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';

/// Add Task Sheet Component
class AddTaskSheet extends StatefulWidget {
  final DateTime selectedDate;
  final TaskPriority? defaultPriority;
  final VoidCallback? onCancel;
  final void Function(String title, TaskPriority priority)? onSave;

  const AddTaskSheet({
    super.key,
    required this.selectedDate,
    this.defaultPriority,
    this.onCancel,
    this.onSave,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TaskPriority _selectedPriority;
  bool _isDateAdjusted = false;

  // Shake animation for validation error
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _selectedPriority = widget.defaultPriority ?? TaskPriority.p1;

    // Initialize shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Auto-adjust to today if selected date is in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );

    _isDateAdjusted = selectedDay.isBefore(today);
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _triggerValidationError();
      return;
    }

    if (title.length > 40) {
      _showInfoDialog(tr('task_name_too_long'));
      return;
    }

    widget.onSave?.call(title, _selectedPriority);
  }

  /// Trigger shake animation and show error message
  void _triggerValidationError() {
    // Trigger shake animation
    _shakeController.reset();
    _shakeController.forward();

    // Show error message
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

          // Date adjustment warning
          if (_isDateAdjusted) _buildDateAdjustmentWarning(),

          // Task input card
          _buildTaskInputCard(),

          // Quadrant selector
          _buildQuadrantSection(),

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
        // Drag handle and title
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
            // Title - P0 red color, global font
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 48, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('new_task'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.priorityP0,
                  ),
                ),
              ),
            ),
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

  Widget _buildDateAdjustmentWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tr('auto_adjusted_today'),
              style: const TextStyle(fontSize: 13, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInputCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap input in AnimatedBuilder for shake effect
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              // Calculate shake offset (oscillates left-right)
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
                // Input field - minimal style
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
                  maxLength: 40,
                  maxLines: 2,
                  minLines: 1,
                  onChanged: (_) {
                    // Clear error when user starts typing
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
                // Bottom accent underline (changes color on error)
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
                        tr('invalid_task_name'),
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

  Widget _buildQuadrantSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('quadrant'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildPrioritySelector(),
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
                tr('save_task'),
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

  Widget _buildPrioritySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TaskPriority.values.map((priority) {
        final isSelected = _selectedPriority == priority;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPriority = priority;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.getPriorityBackgroundColor(priority.value)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.getPriorityColor(priority.value)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.getPriorityColor(priority.value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'P${priority.value}', // P0, P1, P2, P3
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.getPriorityColor(priority.value)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

}

/// Show add task sheet
Future<void> showAddTaskSheet(
  BuildContext context, {
  required DateTime selectedDate,
  TaskPriority? defaultPriority,
  void Function(String title, TaskPriority priority)? onSave,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AddTaskSheet(
        selectedDate: selectedDate,
        defaultPriority: defaultPriority,
        onSave: (title, priority) {
          onSave?.call(title, priority);
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}

