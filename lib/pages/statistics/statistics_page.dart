import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';
import '../../services/task_service.dart';

/// 统计页面
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // 当前选中的象限过滤 (null 表示全部)
  TaskPriority? _selectedQuadrant;

  // 当前时间视图 (false: Week, true: Month)
  bool _isMonthView = false;

  // 基准日期（默认今天）
  DateTime _baseDate = DateTime.now();

  // API 数据
  TaskStatsData? _statsData;
  bool _isLoading = false;

  // 语言变化监听
  StreamSubscription<AppLanguage>? _languageSubscription;

  @override
  void initState() {
    super.initState();
    _languageSubscription = LocaleService.instance.languageStream.listen((_) {
      setState(() {});
    });
    _fetchStats();
  }

  @override
  void dispose() {
    _languageSubscription?.cancel();
    super.dispose();
  }

  /// 获取统计数据
  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);

    // 构造 priorities 参数
    List<String>? priorities;
    if (_selectedQuadrant != null) {
      priorities = [_selectedQuadrant!.apiValue];
    }

    final result = await TaskService.instance.fetchTaskStats(
      dimension: _isMonthView ? 'MONTH' : 'WEEK',
      date: _baseDate,
      priorities: priorities,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess && result.data != null) {
          _statsData = result.data;
        }
      });
    }
  }

  /// 切换象限过滤后重新请求
  void _onQuadrantChanged(TaskPriority? quadrant) {
    setState(() => _selectedQuadrant = quadrant);
    _fetchStats();
  }

  /// 切换周/月视图后重新请求
  void _onScopeChanged(bool isMonth) {
    setState(() => _isMonthView = isMonth);
    _fetchStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 过滤器与切换器
            _buildFilterAndScope(),

            // 内容区域
            Expanded(
              child: _isLoading && _statsData == null
                  ? const Center(child: CircularProgressIndicator())
                  : _statsData == null
                      ? Center(
                          child: Text(
                            tr('no_stats_data'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchStats,
                          color: AppColors.primary,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildChartCard(),
                                const SizedBox(height: 20),
                                _buildTaskLists(),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== 过滤器 ==========

  Widget _buildFilterAndScope() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuadrantSelector(),
          _buildScopeToggle(),
        ],
      ),
    );
  }

  Widget _buildQuadrantSelector() {
    return PopupMenuButton<int>(
      initialValue: _selectedQuadrant?.value ?? -1,
      onSelected: (value) {
        _onQuadrantChanged(
          value == -1 ? null : TaskPriority.fromValue(value),
        );
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
            if (_selectedQuadrant == null)
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
        PopupMenuItem<int>(
          value: -1,
          height: 36,
          child: Row(
            children: [
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
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
              ),
              if (_selectedQuadrant == null) ...[
                const Spacer(),
                const Icon(Icons.check, size: 12, color: AppColors.primary),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
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
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
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
          _buildScopeItem(tr('week'), !_isMonthView, false),
          _buildScopeItem(tr('month'), _isMonthView, true),
        ],
      ),
    );
  }

  Widget _buildScopeItem(String label, bool isSelected, bool isMonth) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.playButton();
        _onScopeChanged(isMonth);
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

  // ========== 图表卡片 ==========

  Widget _buildChartCard() {
    final stats = _statsData!;

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
          // 完成率 + 图例
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stats.totalCompletionRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${stats.totalCompleted}/${stats.totalTasks}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

          // 曲线图
          ClipRect(
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : CustomPaint(
                      painter: _ChartPainter(
                        chartData: stats.chartData,
                        primaryColor: AppColors.primary,
                        secondaryColor:
                            AppColors.textHint.withValues(alpha: 0.3),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // X 轴标签
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildXAxisLabels(),
          ),
        ],
      ),
    );
  }

  /// 构建 X 轴标签（国际化）
  List<Widget> _buildXAxisLabels() {
    final chartData = _statsData!.chartData;
    if (chartData.isEmpty) return [];

    return chartData.map((point) {
      String label;
      if (_isMonthView) {
        // 月维度：label 为 "第N周" — 使用国际化
        label = _localizeWeekLabel(point.label);
      } else {
        // 周维度：label 为 YYYY-MM-DD — 转为星期缩写
        label = _dateLabelToWeekday(point.label);
      }
      return _buildAxisLabel(label);
    }).toList();
  }

  /// 将 "第N周" 转为国际化标签
  String _localizeWeekLabel(String label) {
    // 后端返回 "第1周", "第2周" 等
    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match != null) {
      final n = int.parse(match.group(1)!);
      return tr('week_$n');
    }
    return label;
  }

  /// 将 YYYY-MM-DD 转为国际化的星期缩写
  String _dateLabelToWeekday(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
      return tr(keys[date.weekday - 1]);
    } catch (_) {
      return dateStr;
    }
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

  // ========== 任务列表 ==========

  Widget _buildTaskLists() {
    final stats = _statsData!;
    final completedTasks = List<Task>.from(stats.completedTasks);
    final incompleteTasks = List<Task>.from(stats.incompleteTasks);

    if (completedTasks.isEmpty && incompleteTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            tr('no_stats_data'),
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // 按创建时间倒序排序（最新的在前）
    completedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    incompleteTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (completedTasks.isNotEmpty) ...[
          _buildSectionHeader(tr('completed'), AppColors.success),
          ...completedTasks.map((t) => _buildTaskItem(t)),
          const SizedBox(height: 20),
        ],
        if (incompleteTasks.isNotEmpty) ...[
          _buildSectionHeader(tr('unfinished'), AppColors.textSecondary),
          ...incompleteTasks.map((t) => _buildTaskItem(t)),
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

  Widget _buildTaskItem(Task task) {
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    task.isCompleted ? AppColors.textHint : AppColors.textPrimary,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 右侧显示创建时间
          Text(
            _formatCreatedAt(task.createdAt),
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          if (task.isCompleted) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle,
                color: AppColors.priorityP0, size: 16),
          ],
        ],
      ),
    );
  }

  /// 格式化创建时间为 MM-DD HH:mm
  String _formatCreatedAt(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 自定义曲线图绘制器 — 使用真实 chartData
class _ChartPainter extends CustomPainter {
  final List<ChartDataPoint> chartData;
  final Color primaryColor;
  final Color secondaryColor;

  _ChartPainter({
    required this.chartData,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (chartData.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final points = chartData.length;
    final stepX = points > 1 ? width / (points - 1) : width;

    // 找到最大值以进行归一化
    final maxTotal =
        chartData.map((d) => d.total).reduce((a, b) => math.max(a, b));
    if (maxTotal == 0) return;

    // 已完成数据 (0.0 ~ 1.0)
    final completedData =
        chartData.map((d) => d.completed / maxTotal).toList();
    // 未完成数据 (0.0 ~ 1.0)
    final incompleteData =
        chartData.map((d) => d.incomplete / maxTotal).toList();

    // 绘制已完成曲线（实线 + 渐变填充）
    _drawSmoothCurve(
      canvas,
      completedData,
      stepX,
      height,
      primaryColor,
      3.0,
      fill: true,
    );

    // 绘制未完成曲线（虚线风格，较细）
    _drawSmoothCurve(
      canvas,
      incompleteData,
      stepX,
      height,
      secondaryColor,
      2.0,
      fill: false,
    );

    // 绘制数据点
    _drawDataPoints(canvas, completedData, stepX, height, primaryColor);
  }

  void _drawSmoothCurve(
    Canvas canvas,
    List<double> data,
    double stepX,
    double height,
    Color color,
    double strokeWidth, {
    required bool fill,
  }) {
    if (data.isEmpty) return;

    final path = Path();
    path.moveTo(0, height * (1 - data[0]));

    for (int i = 0; i < data.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = height * (1 - data[i]);
      final x2 = (i + 1) * stepX;
      final y2 = height * (1 - data[i + 1]);

      final controlX1 = x1 + stepX / 2;
      final controlX2 = x1 + stepX / 2;

      path.cubicTo(controlX1, y1, controlX2, y2, x2, y2);
    }

    // 绘制曲线
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    // 绘制渐变填充
    if (fill) {
      final fillPath = Path.from(path);
      final lastX = (data.length - 1) * stepX;
      fillPath.lineTo(lastX, height);
      fillPath.lineTo(0, height);
      fillPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.0),
        ],
      );

      final fillPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, lastX, height),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }
  }

  void _drawDataPoints(
    Canvas canvas,
    List<double> data,
    double stepX,
    double height,
    Color color,
  ) {
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = height * (1 - data[i]);

      // 外圈白色
      canvas.drawCircle(Offset(x, y), 4, ringPaint);
      // 内圈色彩
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.chartData != chartData;
  }
}
