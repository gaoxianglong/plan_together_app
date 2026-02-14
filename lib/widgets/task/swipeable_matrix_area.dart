import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/audio_service.dart';
import 'eisenhower_matrix.dart';

/// 可滑动四象限区域：实时跟随手指、相邻日期预览、50% 阈值翻页/回弹
/// 使用 PageView 实现，自带页面吸附，避免卡在中间
class SwipeableMatrixArea extends StatefulWidget {
  final DateTime currentDate;
  final List<Task> currentTasks;
  final List<Task> prevDayTasks;
  final List<Task> nextDayTasks;
  final bool showCompleted;
  final bool isLoading;
  final ValueChanged<Task>? onTaskTap;
  final ValueChanged<Task>? onToggleTaskComplete;
  final ValueChanged<Task>? onDeleteTask;
  final ValueChanged<TaskPriority>? onQuadrantTap;
  final ValueChanged<DateTime>? onDateChanged;

  const SwipeableMatrixArea({
    super.key,
    required this.currentDate,
    required this.currentTasks,
    required this.prevDayTasks,
    required this.nextDayTasks,
    this.showCompleted = true,
    this.isLoading = false,
    this.onTaskTap,
    this.onToggleTaskComplete,
    this.onDeleteTask,
    this.onQuadrantTap,
    this.onDateChanged,
  });

  @override
  State<SwipeableMatrixArea> createState() => _SwipeableMatrixAreaState();
}

class _SwipeableMatrixAreaState extends State<SwipeableMatrixArea> {
  late PageController _pageController;
  bool _isHandlingPageChange = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void didUpdateWidget(SwipeableMatrixArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDate != widget.currentDate && !_isHandlingPageChange) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrentPage());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToCurrentPage() {
    if (_pageController.hasClients && _pageController.page != null) {
      final page = _pageController.page!.round();
      if (page != 1) {
        _pageController.jumpToPage(1);
      }
    }
  }

  void _onPageChanged(int page) {
    if (page == 1) return; // 中间页，无需处理
    if (_isHandlingPageChange) return;
    _isHandlingPageChange = true;
    AudioService.instance.playPageTurn();
    if (page == 0) {
      widget.onDateChanged?.call(widget.currentDate.subtract(const Duration(days: 1)));
    } else if (page == 2) {
      widget.onDateChanged?.call(widget.currentDate.add(const Duration(days: 1)));
    }
    // 父组件 rebuild 后，重置回中间页，保证可以继续滑动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && mounted) {
        _pageController.jumpToPage(1);
      }
      if (mounted) _isHandlingPageChange = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _estimateMatrixHeight(),
      child: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildPage(widget.prevDayTasks, true),
          _buildPage(widget.currentTasks, false),
          _buildPage(widget.nextDayTasks, true),
        ],
      ),
    );
  }

  double _estimateMatrixHeight() {
    // 四象限 2x2 布局估算高度：2 行 * 约 160 + padding
    return 360;
  }

  Widget _buildPage(List<Task> tasks, bool isPreview) {
    return Stack(
      children: [
        Opacity(
          opacity: isPreview ? 0.65 : 1.0,
          child: EisenhowerMatrix(
            tasks: tasks,
            showCompleted: widget.showCompleted,
            includeTitle: false,
            onTaskTap: isPreview ? null : widget.onTaskTap,
            onToggleTaskComplete: isPreview ? null : widget.onToggleTaskComplete,
            onDeleteTask: isPreview ? null : widget.onDeleteTask,
            onQuadrantTap: isPreview ? null : widget.onQuadrantTap,
          ),
        ),
        if (!isPreview && widget.isLoading && tasks.isEmpty)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
