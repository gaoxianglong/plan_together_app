import 'package:flutter/material.dart';

/// 应用颜色配置 - Minimal Peach 主题
class AppColors {
  AppColors._();

  // 主色调
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryLight = Color(0xFFF8BBD9);
  static const Color primaryDark = Color(0xFFC2185B);

  // 背景色 - Minimal Peach 风格
  static const Color background = Color(0xFFFBECEC); // 柔和粉底色
  static const Color cardBackground = Color(0xFFFDF6F6); // 卡片浅粉白
  static const Color surfaceLight = Color(0xFFFCE4EC);

  // 文字颜色
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  // 四象限颜色 - P0~P3（符合 UI 设计稿）
  static const Color priorityP0 = Color(0xFFE91E63); // 紧急且重要 - 红色
  static const Color priorityP1 = Color(0xFFF48FB1); // 重要不紧急 - 淡粉红
  static const Color priorityP2 = Color(0xFFE8A87C); // 紧急不重要 - 低饱和橙色（柔和）
  static const Color priorityP3 = Color(0xFF90A4AE); // 不重要不紧急 - 低饱和灰绿/冷色

  // 四象限背景色（浅色版）
  static const Color priorityP0Light = Color(0xFFFCE4EC);
  static const Color priorityP1Light = Color(0xFFFCE4EC);
  static const Color priorityP2Light = Color(0xFFFFF3E0);
  static const Color priorityP3Light = Color(0xFFECEFF1);

  // 状态颜色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // 分割线和边框
  static const Color divider = Color(0xFFEEEEEE);
  static const Color border = Color(0xFFE0E0E0);

  // 阴影
  static const Color shadow = Color(0x1A000000);

  /// 根据优先级获取颜色
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 0:
        return priorityP0;
      case 1:
        return priorityP1;
      case 2:
        return priorityP2;
      case 3:
        return priorityP3;
      default:
        return priorityP1;
    }
  }

  /// 根据优先级获取背景色
  static Color getPriorityBackgroundColor(int priority) {
    switch (priority) {
      case 0:
        return priorityP0Light;
      case 1:
        return priorityP1Light;
      case 2:
        return priorityP2Light;
      case 3:
        return priorityP3Light;
      default:
        return priorityP1Light;
    }
  }
}
