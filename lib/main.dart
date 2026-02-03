import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'pages/auth/login_page.dart';
import 'services/quote_service.dart';
import 'services/celebration_service.dart';
import 'services/auth_service.dart';
import 'services/audio_service.dart';
import 'services/avatar_service.dart';
import 'services/nickname_service.dart';
import 'services/locale_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // 初始化服务
  await LocaleService.instance.initialize(); // Initialize locale first
  await AuthService.instance.initialize();
  await CelebrationService.instance.initialize();
  await QuoteService.instance.initialize();
  await AudioService.instance.initialize();
  await AvatarService.instance.initialize();
  await NicknameService.instance.initialize();

  runApp(const MaidenPlanApp());
}

/// 做计划 APP 主应用
class MaidenPlanApp extends StatelessWidget {
  const MaidenPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 始终先进入登录页（仅前端交互，不涉及后端存储）
    return MaterialApp(
      title: 'Maiden Plan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
