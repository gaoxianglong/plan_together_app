import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_colors.dart';
import '../../services/locale_service.dart';

/// Plan page header component
class PlanHeader extends StatelessWidget {
  final String avatarPath;
  final String nickname;
  final int consecutiveDays;
  final bool showCompleted;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSettingsTap;
  final ValueChanged<bool>? onShowCompletedChanged;

  const PlanHeader({
    super.key,
    required this.avatarPath,
    required this.nickname,
    required this.consecutiveDays,
    this.showCompleted = true,
    this.onAvatarTap,
    this.onSettingsTap,
    this.onShowCompletedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Avatar + Nickname
          Row(
            children: [
              // Avatar (larger size: 48x48)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryLight,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    avatarPath,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nickname and subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                        letterSpacing: 0.5,
                      ),
                      children: [
                        TextSpan(text: tr('planning_streak_prefix')),
                        TextSpan(
                          text: ' $consecutiveDays ',
                          style: const TextStyle(
                            color: AppColors.priorityP0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: tr('planning_streak_suffix')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Settings button
          GestureDetector(
            onTap: onSettingsTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight, width: 2),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
