import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';

/// Edit Task Sheet Component
class EditTaskSheet extends StatefulWidget {
  final Task task;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final void Function(String title, TaskPriority priority, DateTime date,
      RepeatType repeatType, List<int>? weekdays, int? dayOfMonth)? onSave;

  const EditTaskSheet({
    super.key,
    required this.task,
    this.onCancel,
    this.onDelete,
    this.onSave,
  });

  @override
  State<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<EditTaskSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TaskPriority _selectedPriority;
  late DateTime _selectedDate;
  late RepeatType _repeatType;
  List<int> _selectedWeekdays = [];
  int? _selectedDayOfMonth;

  // Shake animation for validation error
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _selectedPriority = widget.task.priority;
    _selectedDate = widget.task.date;
    _repeatType = widget.task.repeatType;
    _selectedWeekdays = widget.task.weekdays?.toList() ?? [];
    _selectedDayOfMonth = widget.task.dayOfMonth;

    // Initialize shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDay = DateTime(date.year, date.month, date.day);

    String dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (targetDay == today) {
      return '$dateStr (Today)';
    } else if (targetDay == tomorrow) {
      return '$dateStr (Tomorrow)';
    } else if (targetDay == yesterday) {
      return '$dateStr (Yesterday)';
    }
    return dateStr;
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

    if (title.length > 100) {
      _showInfoDialog(tr('task_name_too_long'));
      return;
    }

    widget.onSave?.call(
      title,
      _selectedPriority,
      _selectedDate,
      _repeatType,
      _repeatType == RepeatType.weekly ? _selectedWeekdays : null,
      _repeatType == RepeatType.monthly ? _selectedDayOfMonth : null,
    );
  }

  /// Trigger shake animation and show error message
  void _triggerValidationError() {
    _shakeController.reset();
    _shakeController.forward();

    setState(() {
      _showError = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showError = false;
        });
      }
    });
  }

  void _handleDelete() {
    AudioService.instance.playButton();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr('confirm_delete'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          widget.task.isRepeating
              ? tr('delete_repeating_confirm')
              : tr('delete_this_task'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playButton();
              Navigator.of(context).pop();
            },
            child: Text(
              tr('cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              AudioService.instance.playButton();
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final minDate = now.subtract(const Duration(days: 365));
    final maxDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),

            // Task input
            _buildTaskInputCard(),

            // Date Selection
            _buildDateSection(),

            // Quadrant
            _buildQuadrantSection(),

            // Repeat
            _buildRepeatSection(),

            // Buttons
            _buildButtons(),

            // Bottom safe area
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 48, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('edit_task'),
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

  Widget _buildTaskInputCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: tr('task_name'),
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  ),
                  maxLength: 100,
                  maxLines: 2,
                  minLines: 1,
                  onChanged: (_) {
                    if (_showError) {
                      setState(() {
                        _showError = false;
                      });
                    }
                  },
                  buildCounter: (context,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      null,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _showError
                          ? [
                              AppColors.error,
                              AppColors.error.withValues(alpha: 0.5)
                            ]
                          : [AppColors.priorityP0, AppColors.priorityP1],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                tr('date'),
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                _formatDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
            ],
          ),
        ),
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

  Widget _buildRepeatSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('repeat'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Switch(
                value: _repeatType != RepeatType.none,
                onChanged: (value) {
                  setState(() {
                    _repeatType = value ? RepeatType.daily : RepeatType.none;
                  });
                },
                activeTrackColor: AppColors.priorityP1,
                inactiveTrackColor: AppColors.priorityP1.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.white,
                trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.transparent;
                  }
                  return AppColors.priorityP1;
                }),
              ),
            ],
          ),
          if (_repeatType != RepeatType.none) ...[
            const SizedBox(height: 8),
            _buildRepeatTypeSelector(),
            if (_repeatType == RepeatType.weekly) ...[
              const SizedBox(height: 12),
              _buildWeekdaySelector(),
            ],
            if (_repeatType == RepeatType.monthly) ...[
              const SizedBox(height: 12),
              _buildDayOfMonthSelector(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _handleSave,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.priorityP0, AppColors.priorityP1],
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
                    tr('save_changes'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _handleDelete,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(tr('delete_task')),
              ),
            ),
        ],
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
                  'P${priority.value}',
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

  Widget _buildRepeatTypeSelector() {
    final repeatTypes = [
      RepeatType.daily,
      RepeatType.weekly,
      RepeatType.monthly
    ];

    return Row(
      children: repeatTypes.map((type) {
        final isSelected = _repeatType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _repeatType = type;
                if (type == RepeatType.weekly && _selectedWeekdays.isEmpty) {
                  _selectedWeekdays = [DateTime.now().weekday];
                }
                if (type == RepeatType.monthly && _selectedDayOfMonth == null) {
                  _selectedDayOfMonth = DateTime.now().day;
                }
              });
            },
            child: Container(
              margin:
                  EdgeInsets.only(right: type != RepeatType.monthly ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekdaySelector() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Wrap(
      spacing: 6,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isSelected = _selectedWeekdays.contains(dayNum);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedWeekdays.remove(dayNum);
              } else {
                _selectedWeekdays.add(dayNum);
              }
            });
          },
          child: Container(
            width: 42,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayOfMonthSelector() {
    return GestureDetector(
      onTap: _showDayOfMonthPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              'Every ${_getOrdinal(_selectedDayOfMonth ?? 1)} of month',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDayOfMonthPicker() {
    showDialog(
      context: context,
      builder: (context) => _DayOfMonthPickerDialog(
        selectedDay: _selectedDayOfMonth ?? 1,
        onDaySelected: (day) {
          setState(() {
            _selectedDayOfMonth = day;
          });
        },
      ),
    );
  }

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}

/// Show edit task sheet
Future<void> showEditTaskSheet(
  BuildContext context, {
  required Task task,
  VoidCallback? onDelete,
  void Function(String title, TaskPriority priority, DateTime date,
          RepeatType repeatType, List<int>? weekdays, int? dayOfMonth)?
      onSave,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: EditTaskSheet(
        task: task,
        onDelete: () {
          Navigator.of(context).pop();
          onDelete?.call();
        },
        onSave: (title, priority, date, repeatType, weekdays, dayOfMonth) {
          onSave?.call(title, priority, date, repeatType, weekdays, dayOfMonth);
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}

/// Day of month picker dialog - calendar grid style
class _DayOfMonthPickerDialog extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const _DayOfMonthPickerDialog({
    required this.selectedDay,
    required this.onDaySelected,
  });

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('select_day'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Calendar grid (7 columns x 5 rows = 35 cells, showing 1-31)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: 31,
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = day == selectedDay;
                return GestureDetector(
                  onTap: () {
                    onDaySelected(day);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.priorityP0
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Selected day hint
            Text(
              'Repeat on the ${_getOrdinal(selectedDay)} of every month',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
