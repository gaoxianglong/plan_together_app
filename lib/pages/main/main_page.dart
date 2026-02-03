import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/draggable_cat.dart';
import '../../services/audio_service.dart';
import '../../services/locale_service.dart';
import '../plan/plan_page.dart';
import '../focus/focus_page.dart';
import '../statistics/statistics_page.dart';
import '../me/me_page.dart';

/// Main Page (includes bottom navigation and draggable cat)
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  
  // Cat Size
  static const double _catSize = 64;

  // PlanPage GlobalKey, used to call its public methods
  final GlobalKey<PlanPageState> _planPageKey = GlobalKey<PlanPageState>();

  // Language subscription for rebuilding UI on language change
  StreamSubscription<AppLanguage>? _languageSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for language changes to rebuild UI
    _languageSubscription = LocaleService.instance.languageStream.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _languageSubscription?.cancel();
    super.dispose();
  }

  void _handleNavTap(int index) {
    // Play click sound
    AudioService.instance.playClick();
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleAddTap() {
    // Play click sound
    AudioService.instance.playClick();
    // Switch to Plan Page and open add task when add button is clicked
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      // Delay call to ensure page has switched
      Future.delayed(const Duration(milliseconds: 100), () {
        _planPageKey.currentState?.handleAddTask();
      });
    } else {
      _planPageKey.currentState?.handleAddTask();
    }
  }

  void _handleAddLongPress() {
    // Play click sound
    AudioService.instance.playClick();
    // Show quick add menu when add button is long pressed
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _planPageKey.currentState?.showQuickAddMenu();
      });
    } else {
      _planPageKey.currentState?.showQuickAddMenu();
    }
  }

  /// Calculate cat's home position (lying on top of + button)
  Offset _getCatHomePosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Navigation bar layout analysis (from app_bottom_nav.dart):
    // - Row height inside SafeArea is 56
    // - +Button area SizedBox(72, 80) centered vertically in Row, overflowing Row by 12px each side
    // - Button inside SizedBox at bottom: 4, size 48x48
    // - Original cat position at SizedBox top: -18
    //
    // Calculate global Y of SizedBox top:
    // - Row bottom distance to screen bottom = bottomPadding
    // - Row height 56, Row top distance to screen bottom = bottomPadding + 56
    // - SizedBox overflows Row top by 12px, SizedBox top distance to screen bottom = bottomPadding + 56 + 12 = bottomPadding + 68
    //
    // Cat top is 18px above SizedBox top, distance to screen bottom = bottomPadding + 68 + 18 = bottomPadding + 86
    // Cat height approx 45, cat center distance to screen bottom = bottomPadding + 86 - 22.5 approx bottomPadding + 64
    
    return Offset(
      screenWidth / 2,
      screenHeight - bottomPadding - 52, // Cat center position, right above the button
    );
  }

  @override
  Widget build(BuildContext context) {
    final catHomePosition = _getCatHomePosition(context);
    
    // Wrap Scaffold with fullscreen Stack to allow cat to overlay navigation bar
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              PlanPage(
                key: _planPageKey,
                onSettingsTap: () {
                  // Navigate to Me page (index 3)
                  setState(() {
                    _currentIndex = 3;
                  });
                },
              ),
              const StatisticsPage(),
              const FocusPage(),
              const MePage(),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: _currentIndex,
            onTap: _handleNavTap,
            onAddTap: _handleAddTap,
            onAddLongPress: _handleAddLongPress,
          ),
        ),
        // Draggable cat (top layer, covers entire screen)
        DraggableCat(
          size: _catSize,
          homePosition: catHomePosition,
        ),
      ],
    );
  }
}
