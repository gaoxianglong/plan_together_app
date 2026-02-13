import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';

/// 更新任务浮层 — 支持修改标题、优先级、日期
class UpdateTaskSheet extends StatefulWidget {
  final Task task;
  final VoidCallback? onCancel;
  final void Function(String title, TaskPriority priority, DateTime date)?
      onSave;
  final void Function(Task task)? onDelete;

  const UpdateTaskSheet({
    super.key,
    required this.task,
    this.onCancel,
    this.onSave,
    this.onDelete,
  });

  @override
  State<UpdateTaskSheet> createState() => _UpdateTaskSheetState();
}

class _UpdateTaskSheetState extends State<UpdateTaskSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TaskPriority _selectedPriority;
  late DateTime _selectedDate;

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
    widget.onSave?.call(title, _selectedPriority, _selectedDate);
  }

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

  void _handleClose() {
    AudioService.instance.playButton();
    widget.onCancel?.call();
    Navigator.of(context).pop();
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
                  child: const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(tr('got_it'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 日期显示文本
  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return tr('today');
    if (diff == 1) return tr('tomorrow');
    if (diff == -1) return tr('yesterday');
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _CompactDatePickerDialog(
        selectedDate: _selectedDate,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
          _buildHeader(),
          _buildTitleInput(),
          _buildQuadrantSection(),
          _buildDateSection(),
          _buildSaveButton(),
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

  Widget _buildTitleInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final shakeOffset = _shakeAnimation.value *
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
                  autofocus: false,
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
          Wrap(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('date'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDateLabel(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
    );
  }
}

/// 紧凑日期选择器 — 符合 Minimal Peach 风格，支持国际化
class _CompactDatePickerDialog extends StatefulWidget {
  final DateTime selectedDate;

  const _CompactDatePickerDialog({required this.selectedDate});

  @override
  State<_CompactDatePickerDialog> createState() =>
      _CompactDatePickerDialogState();
}

class _CompactDatePickerDialogState extends State<_CompactDatePickerDialog> {
  late DateTime _displayMonth; // 当前显示的月份
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedDate;
    _displayMonth = DateTime(_selected.year, _selected.month);
  }

  /// 获取国际化星期标签（周一起始）
  List<String> get _weekLabels => [
        tr('mon'),
        tr('tue'),
        tr('wed'),
        tr('thu'),
        tr('fri'),
        tr('sat'),
        tr('sun'),
      ];

  /// 获取国际化月份名
  String _monthLabel(int month) => tr('month_$month');

  /// 上一个月
  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  /// 下一个月
  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final year = _displayMonth.year;
    final month = _displayMonth.month;

    // 该月第一天是星期几（1=周一 ... 7=周日）
    final firstWeekday = DateTime(year, month, 1).weekday;
    // 该月总天数
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // 前面需要空几格（周一起始）
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 月份导航
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _prevMonth,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.chevron_left,
                        size: 22, color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  '${_monthLabel(month)} $year',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.chevron_right,
                        size: 22, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 星期标题行
            Row(
              children: _weekLabels
                  .map((label) => Expanded(
                        child: Center(
                          child: Text(
                            label.length > 2 ? label.substring(0, 2) : label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),

            // 日期网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1.15,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) {
                  return const SizedBox.shrink();
                }
                final day = index - leadingBlanks + 1;
                final date = DateTime(year, month, day);
                final isSelected = _isSameDay(date, _selected);
                final isToday = _isSameDay(date, today);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selected = date;
                    });
                    Navigator.of(context).pop(date);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.priorityP0
                          : isToday
                              ? AppColors.priorityP0.withValues(alpha: 0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.priorityP0
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // 快捷按钮：今天
            GestureDetector(
              onTap: () {
                final now = DateTime.now();
                Navigator.of(context)
                    .pop(DateTime(now.year, now.month, now.day));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tr('today'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.priorityP0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示更新任务浮层
Future<void> showUpdateTaskSheet(
  BuildContext context, {
  required Task task,
  void Function(String title, TaskPriority priority, DateTime date)? onSave,
  void Function(Task task)? onDelete,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: UpdateTaskSheet(
        task: task,
        onSave: (title, priority, date) {
          onSave?.call(title, priority, date);
          Navigator.of(context).pop();
        },
        onDelete: onDelete,
      ),
    ),
  );
}
