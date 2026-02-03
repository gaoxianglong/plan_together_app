import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 登录页面的猫咪 Logo（猫咪趴在+按钮上）
class AuthCatLogo extends StatefulWidget {
  final double size;

  const AuthCatLogo({super.key, this.size = 120});

  @override
  State<AuthCatLogo> createState() => _AuthCatLogoState();
}

class _AuthCatLogoState extends State<AuthCatLogo>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  late AnimationController _tailController;
  late Animation<double> _tailAnimation;

  bool _isTailWagging = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startRandomTailWag();
  }

  void _initAnimations() {
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _breathAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _breathController.repeat(reverse: true);

    _tailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _tailAnimation = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _tailController, curve: Curves.easeInOut),
    );
  }

  void _startRandomTailWag() {
    Future.delayed(Duration(seconds: 4 + Random().nextInt(5)), () {
      if (mounted && !_isTailWagging) {
        _wagTail();
        _startRandomTailWag();
      }
    });
  }

  void _wagTail() {
    if (!mounted) return;
    _isTailWagging = true;
    _tailController.forward().then((_) {
      if (mounted) {
        _tailController.reverse().then((_) {
          if (mounted) {
            _tailController.forward().then((_) {
              if (mounted) {
                _tailController.reverse().then((_) {
                  _isTailWagging = false;
                });
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _tailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathAnimation, _tailAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_breathAnimation.value * 3),
          child: SizedBox(
            width: widget.size,
            height: widget.size * 0.7,
            child: CustomPaint(
              painter: _LogoCatPainter(
                tailAngle: _tailAnimation.value,
                breathOffset: _breathAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Logo 版猫咪绘制器
class _LogoCatPainter extends CustomPainter {
  final double tailAngle;
  final double breathOffset;

  _LogoCatPainter({
    required this.tailAngle,
    required this.breathOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyColor = AppColors.primaryLight;
    final accentColor = AppColors.primary;
    final innerEarColor = AppColors.primary.withValues(alpha: 0.3);
    const outlineColor = Color(0xFF333333);

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final innerEarPaint = Paint()
      ..color = innerEarColor
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final bodyY = size.height * 0.65;

    // 尾巴
    canvas.save();
    canvas.translate(centerX + size.width * 0.32, bodyY - size.height * 0.05);
    canvas.rotate(tailAngle);

    final tailPath = Path();
    tailPath.moveTo(0, 0);
    tailPath.quadraticBezierTo(
      size.width * 0.2,
      -size.height * 0.3,
      size.width * 0.15,
      -size.height * 0.5,
    );

    final tailFillPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tailPath, tailFillPaint);

    final tailOutlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tailPath, tailOutlinePaint);
    canvas.restore();

    // 身体
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, bodyY),
      width: size.width * 0.78,
      height: size.height * 0.42,
    );
    canvas.drawOval(bodyRect, bodyPaint);
    canvas.drawOval(bodyRect, outlinePaint);

    // 头部
    final headRadius = size.width * 0.3;
    final headX = centerX - size.width * 0.06;
    final headY = bodyY - size.height * 0.18 - breathOffset * 2;
    canvas.drawCircle(Offset(headX, headY), headRadius, bodyPaint);
    canvas.drawCircle(Offset(headX, headY), headRadius, outlinePaint);

    // 左耳
    final leftEarPath = Path();
    leftEarPath.moveTo(headX - headRadius * 0.55, headY - headRadius * 0.2);
    leftEarPath.lineTo(headX - headRadius * 0.85, headY - headRadius * 1.15);
    leftEarPath.lineTo(headX - headRadius * 0.1, headY - headRadius * 0.65);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, bodyPaint);
    canvas.drawPath(leftEarPath, outlinePaint);

    final leftInnerEarPath = Path();
    leftInnerEarPath.moveTo(headX - headRadius * 0.5, headY - headRadius * 0.35);
    leftInnerEarPath.lineTo(headX - headRadius * 0.7, headY - headRadius * 0.9);
    leftInnerEarPath.lineTo(headX - headRadius * 0.2, headY - headRadius * 0.55);
    leftInnerEarPath.close();
    canvas.drawPath(leftInnerEarPath, innerEarPaint);

    // 右耳
    final rightEarPath = Path();
    rightEarPath.moveTo(headX + headRadius * 0.55, headY - headRadius * 0.2);
    rightEarPath.lineTo(headX + headRadius * 0.85, headY - headRadius * 1.15);
    rightEarPath.lineTo(headX + headRadius * 0.1, headY - headRadius * 0.65);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, bodyPaint);
    canvas.drawPath(rightEarPath, outlinePaint);

    final rightInnerEarPath = Path();
    rightInnerEarPath.moveTo(headX + headRadius * 0.5, headY - headRadius * 0.35);
    rightInnerEarPath.lineTo(headX + headRadius * 0.7, headY - headRadius * 0.9);
    rightInnerEarPath.lineTo(headX + headRadius * 0.2, headY - headRadius * 0.55);
    rightInnerEarPath.close();
    canvas.drawPath(rightInnerEarPath, innerEarPaint);

    // 眼睛
    final eyePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final leftEyePath = Path();
    leftEyePath.moveTo(headX - headRadius * 0.38, headY + headRadius * 0.05);
    leftEyePath.quadraticBezierTo(
      headX - headRadius * 0.22,
      headY + headRadius * 0.2,
      headX - headRadius * 0.06,
      headY + headRadius * 0.05,
    );
    canvas.drawPath(leftEyePath, eyePaint);

    final rightEyePath = Path();
    rightEyePath.moveTo(headX + headRadius * 0.06, headY + headRadius * 0.05);
    rightEyePath.quadraticBezierTo(
      headX + headRadius * 0.22,
      headY + headRadius * 0.2,
      headX + headRadius * 0.38,
      headY + headRadius * 0.05,
    );
    canvas.drawPath(rightEyePath, eyePaint);

    // 鼻子
    final nosePath = Path();
    nosePath.moveTo(headX, headY + headRadius * 0.28);
    nosePath.lineTo(headX - headRadius * 0.1, headY + headRadius * 0.4);
    nosePath.lineTo(headX + headRadius * 0.1, headY + headRadius * 0.4);
    nosePath.close();
    canvas.drawPath(nosePath, accentPaint);

    // 胡须
    final whiskerPaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final whiskerY = headY + headRadius * 0.35;

    canvas.drawLine(
      Offset(headX - headRadius * 0.2, whiskerY - headRadius * 0.08),
      Offset(headX - headRadius * 1.1, whiskerY - headRadius * 0.22),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headX - headRadius * 0.22, whiskerY),
      Offset(headX - headRadius * 1.15, whiskerY),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headX - headRadius * 0.2, whiskerY + headRadius * 0.08),
      Offset(headX - headRadius * 1.1, whiskerY + headRadius * 0.22),
      whiskerPaint,
    );

    canvas.drawLine(
      Offset(headX + headRadius * 0.2, whiskerY - headRadius * 0.08),
      Offset(headX + headRadius * 1.1, whiskerY - headRadius * 0.22),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headX + headRadius * 0.22, whiskerY),
      Offset(headX + headRadius * 1.15, whiskerY),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headX + headRadius * 0.2, whiskerY + headRadius * 0.08),
      Offset(headX + headRadius * 1.1, whiskerY + headRadius * 0.22),
      whiskerPaint,
    );

    // 腮红
    final blushPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headX - headRadius * 0.5, headY + headRadius * 0.25),
        width: headRadius * 0.35,
        height: headRadius * 0.2,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headX + headRadius * 0.5, headY + headRadius * 0.25),
        width: headRadius * 0.35,
        height: headRadius * 0.2,
      ),
      blushPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoCatPainter oldDelegate) {
    return oldDelegate.tailAngle != tailAngle ||
        oldDelegate.breathOffset != breathOffset;
  }
}
