import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';

/// 统计页面
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // 状态：当前选中的象限过滤 (null 表示全部)
  TaskPriority? _selectedQuadrant;

  // 状态：当前时间视图 (false: Week, true: Month)
  bool _isMonthView = false;

  // 语言变化监听
  StreamSubscription<AppLanguage>? _languageSubscription;

  @override
  void initState() {
    super.initState();
    _languageSubscription = LocaleService.instance.languageStream.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _languageSubscription?.cancel();
    super.dispose();
  }

  // 模拟数据 - 包含各象限的任务
  final List<Task> _allTasks = [
    // P0 - 紧急且重要
    Task(
      id: '1',
      userId: 'u1',
      title: 'Complete UI Redesign',
      priority: TaskPriority.p0,
      date: DateTime.now(),
      status: TaskStatus.incomplete,
      createdAt: DateTime.now(),
    ),
    Task(
      id: '7',
      userId: 'u1',
      title: 'Fix critical bug',
      priority: TaskPriority.p0,
      date: DateTime.now(),
      status: TaskStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    ),
    // P1 - 重要不紧急
    Task(
      id: '2',
      userId: 'u1',
      title: 'Client meeting prep',
      priority: TaskPriority.p1,
      date: DateTime.now(),
      status: TaskStatus.incomplete,
      createdAt: DateTime.now(),
    ),
    Task(
      id: '4',
      userId: 'u1',
      title: 'Gym workout session',
      priority: TaskPriority.p1,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: TaskStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    ),
    // P2 - 紧急不重要
    Task(
      id: '3',
      userId: 'u1',
      title: 'Grocery delivery',
      priority: TaskPriority.p2,
      date: DateTime.now(),
      status: TaskStatus.incomplete,
      createdAt: DateTime.now(),
    ),
    Task(
      id: '5',
      userId: 'u1',
      title: 'Respond to emails',
      priority: TaskPriority.p2,
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: TaskStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    ),
    // P3 - 不重要不紧急
    Task(
      id: '6',
      userId: 'u1',
      title: 'Read 20 pages',
      priority: TaskPriority.p3,
      date: DateTime.now(),
      status: TaskStatus.incomplete,
      createdAt: DateTime.now(),
    ),
    Task(
      id: '8',
      userId: 'u1',
      title: 'Organize desktop',
      priority: TaskPriority.p3,
      date: DateTime.now(),
      status: TaskStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    ),
  ];

  /// 获取过滤后的任务列表
  List<Task> get _filteredTasks {
    return _allTasks.where((task) {
      // 1. 象限过滤
      if (_selectedQuadrant != null && task.priority != _selectedQuadrant) {
        return false;
      }
      // 2. 时间范围过滤 (这里简化处理，Week取最近7天，Month取最近30天)
      final now = DateTime.now();
      final diff = now.difference(task.date).inDays.abs();
      if (_isMonthView) {
        return diff <= 30;
      } else {
        return diff <= 7;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 过滤器与切换器（直接从顶部开始，移除了标题）
            _buildFilterAndScope(),

            // 内容区域 (可滚动)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 曲线图
                    _buildChartCard(),

                    const SizedBox(height: 20),

                    // 任务列表
                    _buildTaskLists(),

                    // 底部留白
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterAndScope() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：象限选择器
          _buildQuadrantSelector(),

          // 右侧：周/月切换
          _buildScopeToggle(),
        ],
      ),
    );
  }

  Widget _buildQuadrantSelector() {
    return PopupMenuButton<int>(
      initialValue: _selectedQuadrant?.value ?? -1,
      onSelected: (value) {
        setState(() {
          _selectedQuadrant =
              value == -1 ? null : TaskPriority.fromValue(value);
        });
      },
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedQuadrant == null
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.getPriorityColor(
                    _selectedQuadrant!.value,
                  ).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 显示对应的颜色指示
            if (_selectedQuadrant == null)
              // All Tasks - 显示多彩渐变圆点
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.priorityP0,
                      AppColors.priorityP1,
                      AppColors.priorityP2,
                      AppColors.priorityP3,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
              )
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.getPriorityColor(_selectedQuadrant!.value),
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 5),
            Text(
              _selectedQuadrant == null
                  ? tr('all')
                  : 'P${_selectedQuadrant!.value}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _selectedQuadrant == null
                    ? AppColors.textPrimary
                    : AppColors.getPriorityColor(_selectedQuadrant!.value),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: _selectedQuadrant == null
                  ? AppColors.textSecondary
                  : AppColors.getPriorityColor(_selectedQuadrant!.value),
              size: 14,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        // All Tasks 选项 (value = -1)
        PopupMenuItem<int>(
          value: -1,
          height: 36,
          child: Row(
            children: [
              // 多彩渐变圆点表示全部
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.priorityP0,
                      AppColors.priorityP1,
                      AppColors.priorityP2,
                      AppColors.priorityP3,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tr('all_tasks'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              if (_selectedQuadrant == null) ...[
                const Spacer(),
                const Icon(Icons.check, size: 12, color: AppColors.primary),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        // 各象限选项
        ...TaskPriority.values.map(
          (p) => PopupMenuItem<int>(
            value: p.value,
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.getPriorityColor(p.value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'P${p.value} ${p.label}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                if (_selectedQuadrant == p) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 12, color: AppColors.primary),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScopeToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildScopeItem(tr('week'), !_isMonthView, 'Week'),
          _buildScopeItem(tr('month'), _isMonthView, 'Month'),
        ],
      ),
    );
  }

  Widget _buildScopeItem(String label, bool isSelected, String key) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.playButton();
        setState(() {
          _isMonthView = key == 'Month';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    // 计算完成率
    final tasks = _filteredTasks;
    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final rate = total == 0 ? 0.0 : (completed / total * 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('completion_rate'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${rate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // 图例
              Row(
                children: [
                  _buildLegendItem(tr('done'), AppColors.primary),
                  const SizedBox(width: 12),
                  _buildLegendItem(tr('todo'), AppColors.textHint),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 曲线图 - 使用 ClipRect 裁剪阴影超出边框
          ClipRect(
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: _ChartPainter(
                  isMonth: _isMonthView,
                  primaryColor: AppColors.primary,
                  secondaryColor: AppColors.textHint.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          // X轴标签
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _isMonthView
                ? [tr('week_1'), tr('week_2'), tr('week_3'), tr('week_4')].map(_buildAxisLabel).toList()
                : [
                    tr('mon'),
                    tr('tue'),
                    tr('wed'),
                    tr('thu'),
                    tr('fri'),
                    tr('sat'),
                    tr('sun'),
                  ].map(_buildAxisLabel).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAxisLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textHint.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildTaskLists() {
    final tasks = _filteredTasks;
    final ongoing = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();
    // 假设未完成是指过期的，这里简化为所有未完成
    // 实际业务中 Unfinished 可能指 Overdue。这里按照 Prompt 要求 "未完成"
    // 为了区分 Ongoing 和 Unfinished，我们假设：
    // Ongoing: 未完成且日期 >= 今天
    // Unfinished: 未完成且日期 < 今天

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final realOngoing = ongoing.where((t) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      return !tDate.isBefore(today);
    }).toList();

    final realUnfinished = ongoing.where((t) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      return tDate.isBefore(today);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (realOngoing.isNotEmpty) ...[
          _buildSectionHeader(tr('ongoing_tasks'), AppColors.primary),
          ...realOngoing.map((t) => _buildTaskItem(t)),
          const SizedBox(height: 20),
        ],

        if (completed.isNotEmpty) ...[
          _buildSectionHeader(tr('completed'), AppColors.success),
          ...completed.map((t) => _buildTaskItem(t)),
          const SizedBox(height: 20),
        ],

        if (realUnfinished.isNotEmpty) ...[
          _buildSectionHeader(tr('unfinished'), AppColors.textSecondary),
          ...realUnfinished.map((t) => _buildTaskItem(t, isOverdue: true)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task, {bool isOverdue = false}) {
    final priorityColor = AppColors.getPriorityColor(task.priority.value);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Priority Dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          // Title - 与 task_card.dart 保持一致的字体样式
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: task.isCompleted
                    ? AppColors.textHint
                    : AppColors.textPrimary,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: AppColors.textHint,
              ),
            ),
          ),

          // Status/Time
          if (task.isCompleted)
            const Icon(Icons.check_circle, color: AppColors.priorityP0, size: 16)
          else if (isOverdue)
            Text(
              tr('reschedule'),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              tr('today'),
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
        ],
      ),
    );
  }
}

/// 自定义曲线图绘制器
class _ChartPainter extends CustomPainter {
  final bool isMonth;
  final Color primaryColor;
  final Color secondaryColor;

  _ChartPainter({
    required this.isMonth,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 模拟两个数据序列
    // 1. 完成任务曲线 (Primary)
    final path1 = Path();
    // 2. 未完成任务曲线 (Secondary)
    final path2 = Path();

    final width = size.width;
    final height = size.height;

    // 生成一些平滑的随机点或固定模式
    final points = isMonth ? 4 : 7;
    final stepX = width / (points - 1);

    // 模拟数据点 (0.0 - 1.0)
    final data1 = isMonth
        ? [0.3, 0.5, 0.8, 0.6]
        : [0.2, 0.4, 0.35, 0.6, 0.8, 0.7, 0.5];

    final data2 = isMonth
        ? [0.6, 0.4, 0.2, 0.3]
        : [0.7, 0.5, 0.6, 0.3, 0.2, 0.25, 0.4];

    _drawSmoothPath(canvas, path1, data1, stepX, height, primaryColor, 3.0);
    _drawSmoothPath(
      canvas,
      path2,
      data2,
      stepX,
      height,
      secondaryColor,
      2.0,
      isDashed: true,
    );
  }

  void _drawSmoothPath(
    Canvas canvas,
    Path path,
    List<double> data,
    double stepX,
    double height,
    Color color,
    double strokeWidth, {
    bool isDashed = false,
  }) {
    if (data.isEmpty) return;

    path.moveTo(0, height * (1 - data[0]));

    for (int i = 0; i < data.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = height * (1 - data[i]);
      final x2 = (i + 1) * stepX;
      final y2 = height * (1 - data[i + 1]);

      final controlX1 = x1 + stepX / 2;
      final controlY1 = y1;
      final controlX2 = x1 + stepX / 2;
      final controlY2 = y2;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // 绘制渐变填充 (仅实线)
    if (!isDashed) {
      final fillPath = Path.from(path);
      fillPath.lineTo(
        data.length * stepX,
        height,
      ); // Extend to bottom right (approx)
      fillPath.lineTo((data.length - 1) * stepX, height);
      fillPath.lineTo(0, height);
      fillPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
      );

      final fillPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, stepX * data.length, height),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
