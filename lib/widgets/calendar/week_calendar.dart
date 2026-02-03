import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';

/// 周日历组件
class WeekCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<DateTime, List<int>>? taskIndicators; // 日期对应的任务优先级指示器

  const WeekCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.taskIndicators,
  });

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  late DateTime _currentWeekStart;
  late PageController _pageController;
  late DateTime _initialWeekStart; // 记录初始周的开始日期

  List<String> get _weekDays => [
    tr('mon'),
    tr('tue'),
    tr('wed'),
    tr('thu'),
    tr('fri'),
    tr('sat'),
    tr('sun'),
  ];

  @override
  void initState() {
    super.initState();
    _initialWeekStart = _getWeekStart(widget.selectedDate);
    _currentWeekStart = _initialWeekStart;
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void didUpdateWidget(WeekCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中日期变化时，更新日历显示的周
    if (!_isSameDay(widget.selectedDate, oldWidget.selectedDate)) {
      final newWeekStart = _getWeekStart(widget.selectedDate);
      if (!_isSameDay(newWeekStart, _currentWeekStart)) {
        // 计算新周相对于初始周的偏移量
        final weeksDiff =
            newWeekStart.difference(_initialWeekStart).inDays ~/ 7;

        setState(() {
          _currentWeekStart = newWeekStart;
        });

        // 跳转到对应的页面
        _pageController.jumpToPage(1000 + weeksDiff);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  DateTime _getDateForPage(int page) {
    final offset = page - 1000;
    return _initialWeekStart.add(Duration(days: offset * 7));
  }

  /// 判断某日期是否在当前显示的周内
  bool _isInCurrentWeek(DateTime date) {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      _currentWeekStart.year,
      _currentWeekStart.month,
      _currentWeekStart.day,
    );
    final normalizedEnd = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
    return !normalizedDate.isBefore(normalizedStart) &&
        !normalizedDate.isAfter(normalizedEnd);
  }

  /// 获取月份文本
  /// 如果选中日期在当前周内，显示选中日期的月份
  /// 否则显示当前周的周四月份
  String _getDisplayMonthYearText() {
    DateTime dateForMonth;
    if (_isInCurrentWeek(widget.selectedDate)) {
      // 选中日期在当前周内，使用选中日期的月份
      dateForMonth = widget.selectedDate;
    } else {
      // 选中日期不在当前周内，使用周四的月份
      dateForMonth = _currentWeekStart.add(const Duration(days: 3));
    }

    final monthKey = 'month_${dateForMonth.month}';
    return '${tr(monthKey)} ${dateForMonth.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  void _goToPreviousWeek() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextWeek() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 月份标题和导航
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getDisplayMonthYearText(), // 显示当前周的月份
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _goToPreviousWeek,
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 20,
                      color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                    IconButton(
                      onPressed: _goToNextWeek,
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 20,
                      color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 日历主体
          SizedBox(
            height: 72,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                // 滑动日历时播放翻页音效
                AudioService.instance.playPageTurn();
                setState(() {
                  _currentWeekStart = _getDateForPage(page);
                });
              },
              itemBuilder: (context, page) {
                final weekStart = _getDateForPage(page);
                return _buildWeekRow(weekStart);
              },
            ),
          ),

          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildWeekRow(DateTime weekStart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          return _buildDayCell(date, index);
        }),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, int weekdayIndex) {
    final isSelected = _isSameDay(date, widget.selectedDate);
    final isToday = _isToday(date);

    return GestureDetector(
      onTap: () => widget.onDateSelected(date),
      child: SizedBox(
        width: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 星期几标签
            Text(
              _weekDays[weekdayIndex],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isToday ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            // 日期数字
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : (isToday ? AppColors.primary : AppColors.textPrimary),
                  ),
                ),
              ),
            ),
            // 任务指示器点（放在日期下方）
            const SizedBox(height: 2),
            _buildTaskIndicators(date),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskIndicators(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final indicators = widget.taskIndicators?[normalizedDate] ?? [];

    if (indicators.isEmpty) {
      return const SizedBox(height: 5);
    }

    // 最多显示4个点
    final displayIndicators = indicators.take(4).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: displayIndicators.map((priority) {
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          decoration: BoxDecoration(
            color: AppColors.getPriorityColor(priority),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
