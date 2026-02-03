import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/locale_service.dart';

/// 底部导航栏项目
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey; // Localization key

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
  });

  String get label => tr(labelKey);
}

/// 应用底部导航栏组件（含中间添加按钮和小猫动画）
class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onAddLongPress;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.onAddTap,
    this.onAddLongPress,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  // 按钮按压状态
  bool _isAddButtonPressed = false;

  static const List<NavItem> _items = [
    NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, labelKey: 'nav_plan'),
    NavItem(
      icon: Icons.auto_graph_outlined,
      activeIcon: Icons.auto_graph,
      labelKey: 'nav_view',
    ),
    NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      labelKey: 'nav_focus',
    ),
    NavItem(icon: Icons.person_outline, activeIcon: Icons.person, labelKey: 'nav_me'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 左边两个导航项
              _buildNavItem(0),
              _buildNavItem(1),
              // 中间添加按钮（带小猫）
              _buildCenterAddButton(),
              // 右边两个导航项
              _buildNavItem(2),
              _buildNavItem(3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton() {
    return SizedBox(
      width: 72,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 添加按钮
          Positioned(
            bottom: 4,
            child: GestureDetector(
              onTapDown: (_) {
                setState(() {
                  _isAddButtonPressed = true;
                });
              },
              onTapUp: (_) {
                setState(() {
                  _isAddButtonPressed = false;
                });
                widget.onAddTap?.call();
              },
              onTapCancel: () {
                setState(() {
                  _isAddButtonPressed = false;
                });
              },
              onLongPress: () {
                setState(() {
                  _isAddButtonPressed = false;
                });
                widget.onAddLongPress?.call();
              },
              child: AnimatedScale(
                scale: _isAddButtonPressed ? 0.92 : 1.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          // 猫咪已移动到 MainPage 作为可拖动组件
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _items[index];
    final isActive = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap?.call(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.primary : AppColors.textHint,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
