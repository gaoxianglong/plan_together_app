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
import 'services/device_service.dart';
import 'services/api_client.dart';

/// 全局导航 Key，用于在非 Widget 上下文中进行导航（如 401 自动跳转登录页）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  await DeviceService.instance.initialize(); // Initialize device info
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
    // 设置 ApiClient 的全局导航回调（用于 401 自动跳转登录页）
    ApiClient.instance.setOnUnauthorized(() {
      // 清除 token 并跳转到登录页
      AuthService.instance.clearLocalAuth();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    });

    // 始终先进入登录页（仅前端交互，不涉及后端存储）
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Maiden Plan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
