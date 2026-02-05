import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/audio_service.dart';
import '../../services/avatar_service.dart';
import '../../services/nickname_service.dart';
import '../../services/locale_service.dart';
import '../auth/login_page.dart';

/// Me Page
class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  // Mock data: consecutive days
  final int _consecutiveDays = 7;

  // Sound effect status (read from AudioService)
  bool _soundEnabled = true;

  // Selected avatar
  String _selectedAvatar = AvatarService.defaultAvatar;
  StreamSubscription<String?>? _avatarSubscription;

  // Nickname
  String _nickname = NicknameService.defaultNickname;
  StreamSubscription<String>? _nicknameSubscription;

  // Inline nickname editing
  bool _isEditingNickname = false;
  late TextEditingController _nicknameController;
  final FocusNode _nicknameFocusNode = FocusNode();

  // Language
  AppLanguage _currentLanguage = AppLanguage.en;
  StreamSubscription<AppLanguage>? _languageSubscription;

  @override
  void initState() {
    super.initState();
    _soundEnabled = AudioService.instance.enabled;
    _selectedAvatar = AvatarService.instance.selectedAvatar;
    _nickname = NicknameService.instance.nickname;
    _nicknameController = TextEditingController(text: _nickname);
    _currentLanguage = LocaleService.instance.currentLanguage;

    // Listen for avatar changes
    _avatarSubscription = AvatarService.instance.avatarStream.listen((avatar) {
      setState(() {
        _selectedAvatar = avatar ?? AvatarService.defaultAvatar;
      });
    });

    // Listen for nickname changes
    _nicknameSubscription = NicknameService.instance.nicknameStream.listen((
      nickname,
    ) {
      setState(() {
        _nickname = nickname;
        if (!_isEditingNickname) {
          _nicknameController.text = nickname;
        }
      });
    });

    // Listen for language changes
    _languageSubscription = LocaleService.instance.languageStream.listen((
      language,
    ) {
      setState(() {
        _currentLanguage = language;
      });
    });

    // Handle focus loss to save nickname
    _nicknameFocusNode.addListener(_onNicknameFocusChange);
  }

  @override
  void dispose() {
    _avatarSubscription?.cancel();
    _nicknameSubscription?.cancel();
    _languageSubscription?.cancel();
    _nicknameController.dispose();
    _nicknameFocusNode.removeListener(_onNicknameFocusChange);
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  void _onNicknameFocusChange() {
    if (!_nicknameFocusNode.hasFocus && _isEditingNickname) {
      _saveNickname();
    }
  }

  void _startEditingNickname() {
    AudioService.instance.playButton();
    setState(() {
      _isEditingNickname = true;
      _nicknameController.text = _nickname;
    });
    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nicknameFocusNode.requestFocus();
      // Select all text
      _nicknameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _nicknameController.text.length,
      );
    });
  }

  void _saveNickname() {
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isNotEmpty && newNickname.length <= 20) {
      NicknameService.instance.setNickname(newNickname);
    } else {
      // Reset to current nickname if invalid
      _nicknameController.text = _nickname;
    }
    setState(() {
      _isEditingNickname = false;
    });
  }

  void _handleLogout(BuildContext context) {
    AudioService.instance.playButton();
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isLoggingOut = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('leaving_so_soon'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('logout_message'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isLoggingOut ? null : () {
                              AudioService.instance.playButton();
                              Navigator.of(dialogContext).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            child: Text(
                              tr('stay'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isLoggingOut 
                                    ? AppColors.textHint 
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoggingOut ? null : () async {
                              AudioService.instance.playButton();
                              setDialogState(() => isLoggingOut = true);
                              
                              try {
                                await AuthService.instance.logout();
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              } catch (e) {
                                if (dialogContext.mounted) {
                                  setDialogState(() => isLoggingOut = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(tr('network_error')),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLoggingOut 
                                  ? AppColors.textHint 
                                  : AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoggingOut
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    tr('logout'),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleSoundToggle(bool value) {
    setState(() {
      _soundEnabled = value;
      AudioService.instance.enabled = value;
    });
    // Play confirmation sound if enabled
    if (value) {
      AudioService.instance.playButton();
    }
  }

  void _handleDeviceManagement() {
    AudioService.instance.playButton();
    _showDeviceManagementSheet();
  }

  void _showDeviceManagementSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DeviceManagementSheet(),
    );
  }

  void _handleChangePassword() {
    AudioService.instance.playButton();
    _showChangePasswordSheet();
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _ChangePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Header
            _buildHeader(),
            const SizedBox(height: 32),
            // Menu List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Section
                    _buildSectionTitle(tr('account')),
                    const SizedBox(height: 8),
                    _buildGroupedSection([
                      _buildGroupedMenuItem(
                        icon: Icons.lock_outline,
                        title: tr('change_password'),
                        onTap: _handleChangePassword,
                        showDivider: true,
                      ),
                      _buildGroupedMenuItem(
                        icon: Icons.logout,
                        title: tr('logout'),
                        onTap: () => _handleLogout(context),
                        isDestructive: true,
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    // System Settings Section
                    _buildSectionTitle(tr('settings')),
                    const SizedBox(height: 8),
                    _buildGroupedSection([
                      _buildSoundToggleGrouped(showDivider: true),
                      _buildLanguageSettingGrouped(showDivider: true),
                      _buildGroupedMenuItem(
                        icon: Icons.devices_outlined,
                        title: tr('device_management'),
                        onTap: _handleDeviceManagement,
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildGroupedSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildGroupedMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showDivider = true,
  }) {
    final color = isDestructive ? AppColors.primary : AppColors.textPrimary;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, indent: 50, color: AppColors.border),
      ],
    );
  }

  Widget _buildSoundToggleGrouped({bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                _soundEnabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                color: AppColors.textPrimary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('sound_effects'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                height: 28,
                width: 48,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch(
                    value: _soundEnabled,
                    onChanged: _handleSoundToggle,
                    activeColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppColors.border,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, indent: 50, color: AppColors.border),
      ],
    );
  }

  Widget _buildLanguageSettingGrouped({bool showDivider = true}) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showLanguageSelection,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.language_outlined,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('language'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  _currentLanguage.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, indent: 50, color: AppColors.border),
      ],
    );
  }

  void _showLanguageSelection() {
    AudioService.instance.playButton();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageSelectionSheet(
        currentLanguage: _currentLanguage,
        onLanguageSelected: (language) async {
          await LocaleService.instance.setLanguage(language);
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  void _showAvatarSelection() {
    AudioService.instance.playButton();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AvatarSelectionSheet(
        selectedAvatar: _selectedAvatar,
        onAvatarSelected: (avatar) async {
          await AvatarService.instance.setAvatar(avatar);
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// Made in China badge widget
  Widget _buildMadeInChinaBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/zh_cn.svg',
          width: 24,
          height: 16,
        ),
        const SizedBox(width: 8),
        Text(
          tr('made_in_china'),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Made in China badge
        _buildMadeInChinaBadge(),
        const SizedBox(height: 20),
        // Avatar (clickable)
        GestureDetector(
          onTap: _showAvatarSelection,
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    _selectedAvatar,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Edit badge
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Nickname (inline editable)
        _isEditingNickname
            ? SizedBox(
                width: 160,
                child: TextField(
                  controller: _nicknameController,
                  focusNode: _nicknameFocusNode,
                  textAlign: TextAlign.center,
                  maxLength: 20,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _saveNickname(),
                ),
              )
            : GestureDetector(
                onTap: _startEditingNickname,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _nickname,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 8),
        // Streak Days
        _buildStreakDays(),
      ],
    );
  }

  /// Streak N days - N marked with P0 color
  Widget _buildStreakDays() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        children: [
          TextSpan(text: '${tr('planning_streak')} '),
          TextSpan(
            text: '$_consecutiveDays',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.priorityP0, // P0 Rose Red
            ),
          ),
          TextSpan(text: ' ${tr('days')}'),
        ],
      ),
    );
  }
}

/// Device management sheet
class _DeviceManagementSheet extends StatefulWidget {
  const _DeviceManagementSheet();

  @override
  State<_DeviceManagementSheet> createState() => _DeviceManagementSheetState();
}

class _DeviceManagementSheetState extends State<_DeviceManagementSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  DeviceInfo? _currentDevice;
  List<DeviceInfo> _otherDevices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.instance.getDevices();

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _isLoading = false;
        _currentDevice = result.currentDevice;
        _otherDevices = result.otherDevices;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
    }
  }

  int get _totalDeviceCount => (_currentDevice != null ? 1 : 0) + _otherDevices.length;

  void _handleLogoutDevice(BuildContext context, DeviceInfo device) {
    AudioService.instance.playButton();
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isLoggingOut = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getDeviceIcon(device.deviceName),
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('logout_device'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('logout_device_confirm').replaceAll('%s', device.deviceName),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isLoggingOut ? null : () {
                              AudioService.instance.playButton();
                              Navigator.of(dialogContext).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            child: Text(
                              tr('cancel'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isLoggingOut 
                                    ? AppColors.textHint 
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoggingOut ? null : () async {
                              AudioService.instance.playButton();
                              setDialogState(() => isLoggingOut = true);
                              
                              final result = await AuthService.instance.logoutDevice(device.deviceId);
                              
                              if (!dialogContext.mounted) return;
                              Navigator.of(dialogContext).pop();
                              
                              if (result.isSuccess) {
                                // 踢出成功，直接从列表中删除该设备，不显示提示
                                if (mounted) {
                                  setState(() {
                                    _otherDevices.removeWhere((d) => d.deviceId == device.deviceId);
                                  });
                                }
                              } else {
                                // 踢出失败，显示错误信息
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result.errorMessage ?? tr('network_error')),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLoggingOut 
                                  ? AppColors.textHint 
                                  : AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            ),
                            child: isLoggingOut
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    tr('logout'),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.devices, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        tr('my_devices'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Refresh button
                      if (!_isLoading)
                        GestureDetector(
                          onTap: () {
                            AudioService.instance.playButton();
                            _loadDevices();
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.refresh,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      // Close button
                      GestureDetector(
                        onTap: () {
                          AudioService.instance.playButton();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Device count hint
            if (!_isLoading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$_totalDeviceCount/10',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        TextSpan(
                          text: ' ${tr('devices_logged_in')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Content
            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else
              _buildDeviceList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            tr('loading_devices'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: AppColors.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              AudioService.instance.playButton();
              _loadDevices();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tr('refresh'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    final allDevices = <DeviceInfo>[];
    if (_currentDevice != null) {
      allDevices.add(_currentDevice!);
    }
    allDevices.addAll(_otherDevices);

    if (allDevices.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          tr('no_other_devices'),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allDevices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final device = allDevices[index];
          return _buildDeviceItem(context, device);
        },
      ),
    );
  }

  Widget _buildDeviceItem(BuildContext context, DeviceInfo device) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: device.isCurrent
            ? AppColors.primaryLight.withValues(alpha: 0.3)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: device.isCurrent ? AppColors.primaryLight : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Device Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: device.isCurrent
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getDeviceIcon(device.deviceName),
              color: device.isCurrent
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          // Device Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.deviceName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (device.isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tr('current_device'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (device.lastLoginIp != null)
                  Text(
                    'IP: ${device.lastLoginIp}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (device.lastLoginAt != null)
                  Text(
                    '${tr('last_login')}: ${_formatTime(device.lastLoginAt!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          // Logout button (only show for non-current devices)
          if (!device.isCurrent)
            GestureDetector(
              onTap: () => _handleLogoutDevice(context, device),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tr('logout'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('iphone') || lowerName.contains('phone')) {
      return Icons.phone_iphone;
    } else if (lowerName.contains('ipad') || lowerName.contains('tablet')) {
      return Icons.tablet_mac;
    } else if (lowerName.contains('mac') || lowerName.contains('laptop')) {
      return Icons.laptop_mac;
    } else {
      return Icons.devices;
    }
  }

  String _formatTime(String isoTime) {
    try {
      final time = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inMinutes < 1) {
        return tr('just_now');
      } else if (diff.inHours < 1) {
        return tr('minutes_ago').replaceAll('%d', '${diff.inMinutes}');
      } else if (diff.inDays < 1) {
        return tr('hours_ago').replaceAll('%d', '${diff.inHours}');
      } else if (diff.inDays < 7) {
        return tr('days_ago').replaceAll('%d', '${diff.inDays}');
      } else {
        return '${time.month}/${time.day}/${time.year}';
      }
    } catch (e) {
      return isoTime;
    }
  }
}

/// Avatar selection sheet
class _AvatarSelectionSheet extends StatelessWidget {
  final String? selectedAvatar;
  final Function(String) onAvatarSelected;

  const _AvatarSelectionSheet({
    required this.selectedAvatar,
    required this.onAvatarSelected,
  });

  @override
  Widget build(BuildContext context) {
    final avatars = AvatarService.availableAvatars;

    return Container(
      height:
          MediaQuery.of(context).size.height *
          0.5, // Fixed height for scrolling
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.face_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr('choose_avatar'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      AudioService.instance.playButton();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Avatar grid - scrollable
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: avatars.length,
                  itemBuilder: (context, index) {
                    final avatar = avatars[index];
                    final isSelected = avatar == selectedAvatar;

                    return GestureDetector(
                      onTap: () {
                        AudioService.instance.playButton();
                        onAvatarSelected(avatar);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipOval(
                          child: SvgPicture.asset(avatar, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Change password sheet
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    AudioService.instance.playButton();

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (currentPassword.isEmpty) {
      setState(() => _error = tr('enter_current_password'));
      return;
    }
    if (newPassword.isEmpty) {
      setState(() => _error = tr('enter_new_password'));
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _error = tr('password_min_length'));
      return;
    }
    if (confirmPassword.isEmpty) {
      setState(() => _error = tr('confirm_password_empty'));
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _error = tr('passwords_not_match'));
      return;
    }
    if (newPassword == currentPassword) {
      // 新密码与原密码相同，弹出浮层提示
      _showSamePasswordWarningDialog(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // 调用后端 API 修改密码
    final result = await AuthService.instance.changePassword(
      oldPassword: currentPassword,
      newPassword: newPassword,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      // 密码修改成功，关闭底部弹窗并显示成功浮层
      Navigator.pop(context);
      _showPasswordChangedDialog(context);
    } else {
      // 显示错误信息
      setState(() => _error = result.errorMessage);
    }
  }

  /// 显示密码修改成功的浮层
  void _showPasswordChangedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 成功图标
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                // 标题
                Text(
                  tr('password_changed'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // 副标题
                Text(
                  tr('other_devices_logged_out'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 确认按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      AudioService.instance.playButton();
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      tr('got_it'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 显示新密码与原密码相同的警告浮层
  void _showSamePasswordWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 提示图标
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                // 标题
                Text(
                  tr('new_password_same_as_old'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // 副标题
                Text(
                  tr('please_use_different_password'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 确认按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      AudioService.instance.playButton();
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      tr('got_it'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('change_password'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        AudioService.instance.playButton();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      label: tr('current_password'),
                      showPassword: _showCurrentPassword,
                      onToggleVisibility: () {
                        setState(
                          () => _showCurrentPassword = !_showCurrentPassword,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: tr('new_password'),
                      showPassword: _showNewPassword,
                      onToggleVisibility: () {
                        setState(() => _showNewPassword = !_showNewPassword);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: tr('confirm_new_password'),
                      showPassword: _showConfirmPassword,
                      onToggleVisibility: () {
                        setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        );
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Submit button - New Task style
                    GestureDetector(
                      onTap: _isLoading ? null : _handleChangePassword,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.priorityP0,
                              AppColors.priorityP1,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.priorityP0.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tr('update_password'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: !showPassword,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textHint,
              size: 20,
            ),
            onPressed: onToggleVisibility,
          ),
        ),
        onChanged: (_) {
          if (_error != null) {
            setState(() => _error = null);
          }
        },
      ),
    );
  }
}

/// Language selection sheet
class _LanguageSelectionSheet extends StatelessWidget {
  final AppLanguage currentLanguage;
  final Function(AppLanguage) onLanguageSelected;

  const _LanguageSelectionSheet({
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        tr('language'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      AudioService.instance.playButton();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Language list
            ...AppLanguage.values.map(
              (language) => _buildLanguageItem(
                context,
                language,
                language == currentLanguage,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context,
    AppLanguage language,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.playButton();
        onLanguageSelected(language);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const SizedBox(width: 32), // Align with title
            Expanded(
              child: Text(
                language.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
