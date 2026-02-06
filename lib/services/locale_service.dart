import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages
enum AppLanguage {
  en('en', 'English'),
  zh('zh', '中文'),
  ja('ja', '日本語');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.en,
    );
  }
}

/// Locale service - manages app language and provides localized strings
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const String _languageKey = 'app_language';

  SharedPreferences? _prefs;
  AppLanguage _currentLanguage = AppLanguage.en;

  // Stream controller for language changes
  final _languageController = StreamController<AppLanguage>.broadcast();
  Stream<AppLanguage> get languageStream => _languageController.stream;

  /// Get current language
  AppLanguage get currentLanguage => _currentLanguage;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedCode = _prefs?.getString(_languageKey);
    if (savedCode != null) {
      _currentLanguage = AppLanguage.fromCode(savedCode);
    }
  }

  /// Set the app language
  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    await _prefs?.setString(_languageKey, language.code);
    _languageController.add(language);
  }

  /// Get localized string by key
  String tr(String key) {
    final strings = _localizedStrings[_currentLanguage.code];
    return strings?[key] ?? _localizedStrings['en']?[key] ?? key;
  }

  void dispose() {
    _languageController.close();
  }

  /// All localized strings
  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': _enStrings,
    'zh': _zhStrings,
    'ja': _jaStrings,
  };

  // English strings (default)
  static const Map<String, String> _enStrings = {
    // Common
    'app_name': 'Maiden Plan',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'got_it': 'Got it',
    'nickname_update_failed': 'Nickname update failed',
    'avatar_update_failed': 'Avatar update failed',
    'logout_failed': 'Logout failed',
    'device_kick_failed': 'Failed to remove device',
    'focus_not_counted_title': 'Not counted',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'done': 'Done',
    'ok': 'OK',
    'error': 'Error',
    'success': 'Success',
    'loading': 'Loading...',
    'retry': 'Retry',

    // Navigation
    'nav_plan': 'Plan',
    'nav_view': 'View',
    'nav_focus': 'Focus',
    'nav_me': 'Me',

    // Login/Register
    'login': 'Login',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'forgot_password': 'Forgot Password?',
    'dont_have_account': "Don't have an account?",
    'already_have_account': 'Already have an account?',
    'login_failed': 'Login failed. Please check your credentials.',
    'register_success': 'Registration successful!',
    'password_mismatch': 'Passwords do not match',
    'email_already_registered': 'Email already registered',
    'nickname_contains_prohibited': 'Nickname contains prohibited content',
    'nickname_length_invalid': 'Nickname must be 1-20 characters',
    'nickname_too_long_title': 'Nickname too long',
    'nickname_too_long_desc': 'Nickname cannot exceed 20 characters, please shorten it',
    'nickname': 'Nickname',
    'email_required': 'Email is required',
    'email_invalid': 'Invalid email format',
    'nickname_required': 'Please enter your nickname',
    'nickname_too_long': 'Nickname must be 20 characters or less',

    // Error codes
    'error_bad_request': 'Invalid request parameters',
    'error_unauthorized': 'Unauthorized',
    'error_forbidden': 'Access forbidden',
    'error_not_found': 'Resource not found',
    'error_too_many_requests': 'Too many requests, please try again later',
    'error_server': 'Server error, please try again later',
    'error_login_failed': 'Incorrect email or password',
    'error_device_limit': 'Device limit exceeded (max 10 devices)',
    'error_email_not_found': 'Email not registered',
    'error_cannot_logout_current': 'Cannot logout current device',
    'error_device_not_found': 'Device not found',
    'error_task_title_invalid': 'Task title is empty or too long',
    'error_task_date_out_of_range': 'Date out of range',
    'error_task_daily_limit': 'Daily task limit exceeded (max 50)',
    'error_task_repeat_invalid': 'Invalid repeat configuration',
    'error_task_has_incomplete_subtasks': 'Cannot complete task with incomplete subtasks',
    'error_task_parent_not_found': 'Parent task not found',
    'error_task_subtask_limit': 'Subtask limit exceeded (max 20)',
    'error_focus_session_exists': 'A focus session is already in progress',
    'error_nickname_too_frequent': 'Nickname can only be changed up to 2 times within 7 days',
    'nickname_change_limit_title': 'Change limit reached',
    'password_required': 'Password is required',
    'password_min_length': 'Password must be at least 6 characters',
    'welcome_back': 'Welcome Back',
    'create_account': 'Create Account',
    'sign_in_continue': 'Sign in to continue your planning journey',
    'join_us': 'Join us to start your planning journey',

    // Plan Page
    'planning_streak_prefix': 'Day',
    'planning_streak_suffix': 'of planning',
    'back_to_today': 'Back to Today',
    'add_task': 'Add Task',
    'new_task': 'New Task',
    'quick_add': 'Quick Add',
    'task_title': 'Task Title',
    'task_description': 'Description',
    'priority': 'Priority',
    'date': 'Date',
    'repeat': 'Repeat',
    'subtasks': 'Subtasks',
    'add_subtask': 'Add Subtask',
    'no_tasks': 'No tasks for this day',
    'all_done': 'All Done!',
    'celebration_default': 'Amazing work today!',
    'tasks_remaining': 'tasks remaining',

    // Priority
    'priority_p0': 'P0 - Urgent & Important',
    'priority_p1': 'P1 - Important',
    'priority_p2': 'P2 - Urgent',
    'priority_p3': 'P3 - Later',

    // Repeat
    'repeat_none': 'None',
    'repeat_daily': 'Daily',
    'repeat_weekly': 'Weekly',
    'repeat_monthly': 'Monthly',
    'repeat_yearly': 'Yearly',

    // View Page
    'view_week': 'Week',
    'view_month': 'Month',
    'pending': 'Pending',
    'overdue': 'Overdue',
    'completed': 'Completed',
    'no_tasks_pending': 'No pending tasks',
    'no_tasks_overdue': 'No overdue tasks',
    'no_tasks_completed': 'No completed tasks',

    // Focus Page
    'focus_title': 'Focus',
    'focus_start': 'Start Focus',
    'focus_pause': 'Pause',
    'focus_resume': 'Resume',
    'focus_stop': 'Stop',
    'focus_reset': 'Reset',
    'focus_complete': 'Focus Complete!',
    'focus_sessions': 'Focus Sessions',
    'focus_total_time': 'Total Time',
    'focus_today': 'Today',
    'focus_this_week': 'This Week',
    'focus_history': 'History',
    'minutes': 'min',
    'hours': 'hr',
    'pomodoro': 'Pomodoro',
    'short_break': 'Short Break',
    'long_break': 'Long Break',

    // Me Page
    'me_title': 'Me',
    'planning_streak': 'Planning Streak',
    'days': 'Days',
    'edit_nickname': 'Edit Nickname',
    'nickname_empty': 'Nickname cannot be empty',
    'nickname_max_length': 'Nickname must be 20 characters or less',

    // Account Section
    'account': 'Account',
    'change_password': 'Change Password',
    'logout': 'Logout',
    'logout_confirm_title': 'Logout',
    'logout_confirm_message': 'Are you sure you want to logout?',
    'current_password': 'Current Password',
    'new_password': 'New Password',
    'confirm_new_password': 'Confirm New Password',
    'update_password': 'Update Password',
    'password_updated': 'Password updated successfully',
    'all_fields_required': 'All fields are required',
    'new_passwords_mismatch': 'New passwords do not match',

    // Settings Section
    'settings': 'Settings',
    'sound_effects': 'Sound Effects',
    'device_management': 'Device Management',
    'language': 'Language',
    'devices_logged_in': 'devices logged in',
    'current_device': 'Current',
    'last_login': 'Last login',
    'loading_devices': 'Loading devices...',
    'refresh': 'Refresh',
    'no_other_devices': 'No other devices logged in',
    'logout_device_success': 'Device logged out successfully',

    // Avatar
    'choose_avatar': 'Choose Avatar',

    // Celebration
    'celebration_title': 'Congratulations!',
    'celebration_message': 'You completed all tasks for today!',

    // Calendar
    'today': 'Today',
    'yesterday': 'Yesterday',
    'tomorrow': 'Tomorrow',
    'mon': 'MON',
    'tue': 'TUE',
    'wed': 'WED',
    'thu': 'THU',
    'fri': 'FRI',
    'sat': 'SAT',
    'sun': 'SUN',

    // Months
    'month_1': 'January',
    'month_2': 'February',
    'month_3': 'March',
    'month_4': 'April',
    'month_5': 'May',
    'month_6': 'June',
    'month_7': 'July',
    'month_8': 'August',
    'month_9': 'September',
    'month_10': 'October',
    'month_11': 'November',
    'month_12': 'December',

    // Eisenhower Matrix
    'eisenhower_matrix': 'EISENHOWER MATRIX',

    // Quadrant titles
    'quadrant_p0_title': 'EXECUTE NOW',
    'quadrant_p0_desc': 'Urgent & Important',
    'quadrant_p1_title': 'PLAN & SCHEDULE',
    'quadrant_p1_desc': 'Important, Not Urgent',
    'quadrant_p2_title': 'HANDLE ASAP',
    'quadrant_p2_desc': 'Urgent, Not Important',
    'quadrant_p3_title': 'DEFER OR DROP',
    'quadrant_p3_desc': 'Not Urgent or Important',

    // Task Actions
    'delete_task': 'Delete Task',
    'delete_task_confirm': 'Are you sure you want to delete this task?',
    'mark_complete': 'Mark Complete',
    'mark_incomplete': 'Mark Incomplete',

    // Sheets - Add Task
    'what_needs_done': 'What needs to be done?',
    'save_task': 'Save Task',
    'quadrant': 'Quadrant',
    'auto_adjusted_today': 'Auto-adjusted to today',
    'invalid_task_name': 'Please enter a valid task name',
    'task_name_too_long': 'Task name cannot exceed 100 characters',
    'select_day': 'Select Day',
    'every_nth_of_month': 'Every %s of month',
    'repeat_on_nth': 'Repeat on the %s of every month',

    // Sheets - Subtask
    'new_subtask': 'New Subtask',
    'save_subtask': 'Save Subtask',
    'invalid_subtask_name': 'Please enter a valid subtask name',
    'subtask_name_too_long': 'Subtask name cannot exceed 100 characters',
    'subtasks_title': 'Subtasks',
    'no_subtasks_yet': 'No subtasks yet',

    // Sheets - Edit Task
    'edit_task': 'Edit Task',
    'task_name': 'Task Name',
    'save_changes': 'Save Changes',
    'confirm_delete': 'Confirm Delete',
    'delete_repeating_confirm':
        'Delete all repeating tasks (including future)?',
    'delete_this_task': 'Delete this task?',

    // Sheets - Me Page (additional keys)
    'logout_device': 'Logout Device',
    'logout_device_confirm':
        'Are you sure you want to logout from this device?',
    'device_logged_out': '%s has been logged out',
    'my_devices': 'My Devices',
    'days_ago': '%d days ago',

    // Additional keys for sheets and auth pages
    'enter_current_password': 'Please enter current password',
    'enter_new_password': 'Please enter new password',
    'confirm_password_empty': 'Please confirm new password',
    'passwords_not_match': 'Passwords do not match',
    'password_changed': 'Password changed successfully',
    'error_old_password_wrong': 'Current password is incorrect',
    'other_devices_logged_out': 'Other devices have been logged out',
    'new_password_same_as_old': 'New password cannot be the same',
    'please_use_different_password': 'Please use a different password from your current one',
    'just_now': 'Just now',
    'minutes_ago': '%d minutes ago',
    'hours_ago': '%d hours ago',
    'select_language': 'Select Language',

    // Statistics Page (additional keys)
    'all': 'All',
    'all_tasks': 'All Tasks',
    'week': 'Week',
    'month': 'Month',
    'completion_rate': 'COMPLETION RATE',
    'todo': 'Todo',
    'ongoing_tasks': 'ONGOING TASKS',
    'unfinished': 'UNFINISHED',
    'reschedule': 'Reschedule',
    'week_1': 'W1',
    'week_2': 'W2',
    'week_3': 'W3',
    'week_4': 'W4',

    'app_slogan': 'Organize your life with ease',
    'no_account': "Don't have an account?",
    'sign_up': 'Sign Up',
    'retrieve_password': 'Retrieve Password',
    'enter_email_reset': 'Enter your email to recover your password.',
    'send': 'Send',
    'sending': 'Sending...',
    'reset_link_sent': 'Reset link sent to your email',
    'password_reset_email_sent': 'Email Sent',
    'check_email_for_reset_link': 'Password reset email has been sent. Please check your inbox.',
    'email_send_limit': 'Please wait 1 minute before sending again',
    'have_account': 'Already have an account?',
    'sign_up_to_start': 'Sign up to get started',
    'registration_successful': 'Registration successful',
    'redirect_to_login': 'Redirecting to login...',
    'registration_failed': 'Registration failed',
    'network_error': 'Network error, please try again',
    'error_parse': 'Response parse error',

    // Me Page - Additional
    'leaving_so_soon': 'Leaving so soon?',
    'logout_message': 'We\'ll miss you! Come back soon to achieve more goals.',
    'stay': 'Stay',
    'ip_address': 'IP:',

    // Plan Page
    'priority_p0_label': 'EXECUTE NOW',
    'priority_p0_desc': 'Urgent & Important',
    'priority_p1_label': 'PLAN & SCHEDULE',
    'priority_p1_desc': 'Important, Not Urgent',
    'priority_p2_label': 'HANDLE ASAP',
    'priority_p2_desc': 'Urgent, Not Important',
    'priority_p3_label': 'DEFER OR DROP',
    'priority_p3_desc': 'Not Urgent or Important',

    // Focus Page
    'pomodoro_completed': 'Pomodoro completed!',
    'pomodoro_completed_next': 'Pomodoro completed! Starting next round...',
    'total_focus_time': 'Total Focus Time',
    'total_focus_hours': 'Total Hours',
    'total_focus_seconds': 'Total Seconds',
    'longest_session': 'Longest Session',
    'times': 'times',
    'close': 'Close',
    'pause_first': 'Please pause or end the timer first',
    'set_focus_duration': 'Set Focus Duration',
    'duration_hint': '10 - 60 minutes',
    'min': 'min',
    'sec': 'sec',
    'focus_in_progress': 'Focus in progress...',
    'ready_to_focus': 'Ready to focus',
    'set_time': 'Set Time',
    'end': 'End',
    'auto_start_next': 'Auto-start next round',
    'start_focus': 'Start Focus',
    'starting': 'Starting...',
    'focus_start_failed': 'Unable to start focus',
    'focus_duration_too_short': 'Focus duration must be at least 10 minutes',
    'focus_duration_too_long': 'Focus duration cannot exceed 60 minutes',
    'focus_counted': 'Focus time counted:',
    'focus_not_counted': 'Less than 50% completed, this session was not counted',

    // Made in China
    'made_in_china': 'DESIGNED WITH LOVE IN CHINA',
  };

  // Chinese strings
  static const Map<String, String> _zhStrings = {
    // Common
    'app_name': '少女计划',
    'cancel': '取消',
    'confirm': '确认',
    'got_it': '知道了',
    'nickname_update_failed': '昵称修改失败',
    'avatar_update_failed': '头像更新失败',
    'logout_failed': '退出登录失败',
    'device_kick_failed': '移除设备失败',
    'focus_not_counted_title': '未计入',
    'save': '保存',
    'delete': '删除',
    'edit': '编辑',
    'done': '完成',
    'ok': '好的',
    'error': '错误',
    'success': '成功',
    'loading': '加载中...',
    'retry': '重试',

    // Navigation
    'nav_plan': '计划',
    'nav_view': '视图',
    'nav_focus': '专注',
    'nav_me': '我的',

    // Login/Register
    'login': '登录',
    'register': '注册',
    'email': '邮箱',
    'password': '密码',
    'confirm_password': '确认密码',
    'forgot_password': '忘记密码？',
    'dont_have_account': '没有账号？',
    'already_have_account': '已有账号？',
    'login_failed': '登录失败，请检查您的账号信息。',
    'register_success': '注册成功！',
    'password_mismatch': '两次密码不一致',
    'email_already_registered': '邮箱已被注册',
    'nickname_contains_prohibited': '昵称包含违规内容',
    'nickname_length_invalid': '昵称长度需为1-20个字符',
    'nickname_too_long_title': '昵称超出限制',
    'nickname_too_long_desc': '昵称不能超过20个字符，请缩短后重试',
    'nickname': '昵称',
    'email_required': '请输入邮箱',
    'email_invalid': '邮箱格式不正确',
    'nickname_required': '请输入昵称',
    'nickname_too_long': '昵称不能超过20个字符',

    // Error codes
    'error_bad_request': '请求参数错误',
    'error_unauthorized': '未授权',
    'error_forbidden': '禁止访问',
    'error_not_found': '资源不存在',
    'error_too_many_requests': '请求过于频繁，请稍后再试',
    'error_server': '服务器错误，请稍后再试',
    'error_login_failed': '邮箱或密码错误',
    'error_device_limit': '设备数量超出上限（最多10台）',
    'error_email_not_found': '邮箱未注册',
    'error_cannot_logout_current': '不能踢出当前设备',
    'error_device_not_found': '设备不存在',
    'error_task_title_invalid': '任务标题为空或超长',
    'error_task_date_out_of_range': '日期超出范围',
    'error_task_daily_limit': '单日任务数超出上限（最多50条）',
    'error_task_repeat_invalid': '重复配置格式错误',
    'error_task_has_incomplete_subtasks': '父任务存在未完成子任务，无法直接完成',
    'error_task_parent_not_found': '父任务不存在',
    'error_task_subtask_limit': '子任务数量超出上限（最多20条）',
    'error_focus_session_exists': '存在进行中的专注会话',
    'error_nickname_too_frequent': '昵称7天内最多修改2次',
    'nickname_change_limit_title': '修改次数已达上限',
    'password_required': '请输入密码',
    'password_min_length': '密码至少需要6个字符',
    'welcome_back': '欢迎回来',
    'create_account': '创建账号',
    'sign_in_continue': '登录以继续您的计划之旅',
    'join_us': '加入我们，开始您的计划之旅',

    // Plan Page
    'planning_streak_prefix': '已坚持做计划',
    'planning_streak_suffix': '天',
    'back_to_today': '回到今天',
    'add_task': '添加任务',
    'new_task': '新任务',
    'quick_add': '快速添加',
    'task_title': '任务标题',
    'task_description': '描述',
    'priority': '优先级',
    'date': '日期',
    'repeat': '重复',
    'subtasks': '子任务',
    'add_subtask': '添加子任务',
    'no_tasks': '今天没有任务',
    'all_done': '全部完成！',
    'celebration_default': '今天表现太棒了！',
    'tasks_remaining': '个任务待完成',

    // Priority
    'priority_p0': 'P0 - 紧急且重要',
    'priority_p1': 'P1 - 重要',
    'priority_p2': 'P2 - 紧急',
    'priority_p3': 'P3 - 延后或放弃',
    'priority_p0_label': '立即执行',
    'priority_p0_desc': '紧急且重要',
    'priority_p1_label': '计划安排',
    'priority_p1_desc': '重要但不紧急',
    'priority_p2_label': '尽快处理',
    'priority_p2_desc': '紧急但不重要',
    'priority_p3_label': '延后或放弃',
    'priority_p3_desc': '不紧急也不重要',

    // Repeat
    'repeat_none': '不重复',
    'repeat_daily': '每天',
    'repeat_weekly': '每周',
    'repeat_monthly': '每月',
    'repeat_yearly': '每年',

    // View Page
    'view_week': '周视图',
    'view_month': '月视图',
    'pending': '待处理',
    'overdue': '已逾期',
    'completed': '已完成',
    'no_tasks_pending': '没有待处理的任务',
    'no_tasks_overdue': '没有逾期的任务',
    'no_tasks_completed': '没有已完成的任务',

    // Focus Page
    'focus_title': '专注',
    'focus_start': '开始专注',
    'focus_pause': '暂停',
    'focus_resume': '继续',
    'focus_stop': '停止',
    'focus_reset': '重置',
    'focus_complete': '专注完成！',
    'focus_sessions': '专注次数',
    'focus_total_time': '总时长',
    'focus_today': '今天',
    'focus_this_week': '本周',
    'focus_history': '历史记录',
    'minutes': '分钟',
    'min': '分钟',
    'hours': '小时',
    'pomodoro': '番茄钟',
    'short_break': '短休息',
    'long_break': '长休息',
    'pomodoro_completed': '番茄钟完成！',
    'pomodoro_completed_next': '番茄钟完成！开始下一轮...',
    'total_focus_time': '总专注时长',
    'total_focus_hours': '累计小时',
    'total_focus_seconds': '累计秒数',
    'longest_session': '最长专注',
    'times': '次',
    'pause_first': '请先暂停或结束计时器',
    'set_focus_duration': '设置专注时长',
    'duration_hint': '10 - 60 分钟',
    'sec': '秒',
    'focus_in_progress': '专注中...',
    'ready_to_focus': '准备开始',
    'set_time': '设置时间',
    'end': '结束',
    'auto_start_next': '自动开始下一轮',
    'start_focus': '开始专注',
    'starting': '正在开始...',
    'focus_start_failed': '无法开始专注',
    'focus_duration_too_short': '专注时长不能少于10分钟',
    'focus_duration_too_long': '专注时长不能超过60分钟',
    'focus_counted': '本次专注已计入:',
    'focus_not_counted': '完成不足50%，本次专注未计入',
    'close': '关闭',

    // Me Page
    'me_title': '我的',
    'planning_streak': '已坚持做计划',
    'days': '天',
    'edit_nickname': '编辑昵称',
    'nickname_empty': '昵称不能为空',
    'nickname_max_length': '昵称不能超过20个字符',
    'leaving_so_soon': '这么快就要走了？',
    'logout_message': '我们会想念你的！快回来完成更多目标吧。',
    'stay': '留下',
    'ip_address': 'IP:',

    // Account Section
    'account': '账户',
    'change_password': '修改密码',
    'logout': '退出登录',
    'logout_confirm_title': '退出登录',
    'logout_confirm_message': '确定要退出登录吗？',
    'current_password': '当前密码',
    'new_password': '新密码',
    'confirm_new_password': '确认新密码',
    'update_password': '更新密码',
    'password_updated': '密码更新成功',
    'all_fields_required': '所有字段都是必填的',
    'new_passwords_mismatch': '两次新密码不一致',

    // Settings Section
    'settings': '设置',
    'sound_effects': '音效',
    'device_management': '设备管理',
    'language': '语言',
    'devices_logged_in': '台设备已登录',
    'current_device': '当前设备',
    'last_login': '最近登录',
    'loading_devices': '正在加载设备...',
    'refresh': '刷新',
    'no_other_devices': '暂无其他登录设备',
    'logout_device_success': '设备已退出登录',

    // Avatar
    'choose_avatar': '选择头像',

    // Celebration
    'celebration_title': '恭喜！',
    'celebration_message': '你已完成今天所有任务！',

    // Calendar
    'today': '今天',
    'yesterday': '昨天',
    'tomorrow': '明天',
    'mon': '周一',
    'tue': '周二',
    'wed': '周三',
    'thu': '周四',
    'fri': '周五',
    'sat': '周六',
    'sun': '周日',

    // Months
    'month_1': '一月',
    'month_2': '二月',
    'month_3': '三月',
    'month_4': '四月',
    'month_5': '五月',
    'month_6': '六月',
    'month_7': '七月',
    'month_8': '八月',
    'month_9': '九月',
    'month_10': '十月',
    'month_11': '十一月',
    'month_12': '十二月',

    // Eisenhower Matrix
    'eisenhower_matrix': '艾森豪威尔矩阵',

    // Quadrant titles
    'quadrant_p0_title': '立即执行',
    'quadrant_p0_desc': '紧急且重要',
    'quadrant_p1_title': '计划安排',
    'quadrant_p1_desc': '重要不紧急',
    'quadrant_p2_title': '尽快处理',
    'quadrant_p2_desc': '紧急不重要',
    'quadrant_p3_title': '延后或放弃',
    'quadrant_p3_desc': '不紧急不重要',

    // Task Actions
    'delete_task': '删除任务',
    'delete_task_confirm': '确定要删除这个任务吗？',
    'mark_complete': '标记完成',
    'mark_incomplete': '标记未完成',

    // Sheets - Add Task
    'what_needs_done': '需要做什么？',
    'save_task': '保存任务',
    'quadrant': '象限',
    'auto_adjusted_today': '已自动调整为今天',
    'invalid_task_name': '请输入有效的任务名称',
    'task_name_too_long': '任务名称不能超过100个字符',
    'select_day': '选择日期',
    'every_nth_of_month': '每月%s号',
    'repeat_on_nth': '每月%s号重复',

    // Sheets - Subtask
    'new_subtask': '新建子任务',
    'save_subtask': '保存子任务',
    'invalid_subtask_name': '请输入有效的子任务名称',
    'subtask_name_too_long': '子任务名称不能超过100个字符',
    'subtasks_title': '子任务',
    'no_subtasks_yet': '暂无子任务',

    // Sheets - Edit Task
    'edit_task': '编辑任务',
    'task_name': '任务名称',
    'save_changes': '保存修改',
    'confirm_delete': '确认删除',
    'delete_repeating_confirm': '删除所有重复任务（包括未来的）？',
    'delete_this_task': '删除这个任务？',

    // Sheets - Me Page
    'logout_device': '退出设备',
    'logout_device_confirm': '确定要退出「%s」吗？',
    'device_logged_out': '「%s」已退出登录',
    'my_devices': '我的设备',
    'days_ago': '%d天前',

    // Additional keys for sheets and auth pages
    'enter_current_password': '请输入当前密码',
    'enter_new_password': '请输入新密码',
    'confirm_password_empty': '请确认新密码',
    'passwords_not_match': '密码不一致',
    'password_changed': '密码修改成功',
    'error_old_password_wrong': '当前密码不正确',
    'other_devices_logged_out': '其他设备已被强制下线',
    'new_password_same_as_old': '新密码不能与原密码相同',
    'please_use_different_password': '请设置一个不同于当前密码的新密码',
    'just_now': '刚刚',
    'minutes_ago': '%d分钟前',
    'hours_ago': '%d小时前',
    'select_language': '选择语言',

    // Statistics Page (additional keys)
    'all': '全部',
    'all_tasks': '全部任务',
    'week': '周',
    'month': '月',
    'completion_rate': '完成率',
    'todo': '待办',
    'ongoing_tasks': '进行中',
    'unfinished': '未完成',
    'reschedule': '重新安排',
    'week_1': '第1周',
    'week_2': '第2周',
    'week_3': '第3周',
    'week_4': '第4周',

    'app_slogan': '轻松管理你的生活',
    'no_account': '还没有账号？',
    'sign_up': '注册',
    'retrieve_password': '找回密码',
    'enter_email_reset': '输入邮箱以找回密码。',
    'send': '发送',
    'sending': '发送中...',
    'reset_link_sent': '重置链接已发送到您的邮箱',
    'password_reset_email_sent': '邮件已发送',
    'check_email_for_reset_link': '密码重置邮件已发送，请查收您的邮箱。',
    'email_send_limit': '请等待1分钟后再次发送',
    'have_account': '已有账号？',
    'sign_up_to_start': '注册开始使用',
    'registration_successful': '注册成功',
    'redirect_to_login': '正在跳转到登录页...',
    'registration_failed': '注册失败',
    'network_error': '网络错误，请重试',
    'error_parse': '响应解析错误',

    // Made in China
    'made_in_china': '用心设计 · 来自中国',
  };

  // Japanese strings
  static const Map<String, String> _jaStrings = {
    // Common
    'app_name': '少女の計画',
    'cancel': 'キャンセル',
    'confirm': '確認',
    'got_it': 'わかりました',
    'nickname_update_failed': 'ニックネームの更新に失敗しました',
    'avatar_update_failed': 'アバターの更新に失敗しました',
    'logout_failed': 'ログアウトに失敗しました',
    'device_kick_failed': 'デバイスの削除に失敗しました',
    'focus_not_counted_title': '記録されません',
    'save': '保存',
    'delete': '削除',
    'edit': '編集',
    'done': '完了',
    'ok': 'OK',
    'error': 'エラー',
    'success': '成功',
    'loading': '読み込み中...',
    'retry': '再試行',

    // Navigation
    'nav_plan': 'プラン',
    'nav_view': 'ビュー',
    'nav_focus': '集中',
    'nav_me': 'マイ',

    // Login/Register
    'login': 'ログイン',
    'register': '新規登録',
    'email': 'メール',
    'password': 'パスワード',
    'confirm_password': 'パスワード確認',
    'forgot_password': 'パスワードを忘れた？',
    'dont_have_account': 'アカウントをお持ちでないですか？',
    'already_have_account': 'すでにアカウントをお持ちですか？',
    'login_failed': 'ログインに失敗しました。認証情報を確認してください。',
    'register_success': '登録が完了しました！',
    'password_mismatch': 'パスワードが一致しません',
    'email_already_registered': 'このメールアドレスは既に登録されています',
    'nickname_contains_prohibited': 'ニックネームに禁止されている内容が含まれています',
    'nickname_length_invalid': 'ニックネームは1〜20文字にしてください',
    'nickname_too_long_title': 'ニックネームが長すぎます',
    'nickname_too_long_desc': 'ニックネームは20文字以内にしてください',
    'nickname': 'ニックネーム',
    'email_required': 'メールアドレスを入力してください',
    'email_invalid': 'メールアドレスの形式が正しくありません',
    'nickname_required': 'ニックネームを入力してください',
    'nickname_too_long': 'ニックネームは20文字以内で入力してください',

    // Error codes
    'error_bad_request': 'リクエストパラメータが不正です',
    'error_unauthorized': '未認証',
    'error_forbidden': 'アクセスが禁止されています',
    'error_not_found': 'リソースが見つかりません',
    'error_too_many_requests': 'リクエストが多すぎます、後でもう一度お試しください',
    'error_server': 'サーバーエラー、後でもう一度お試しください',
    'error_login_failed': 'メールアドレスまたはパスワードが間違っています',
    'error_device_limit': 'デバイス数が上限を超えました（最大10台）',
    'error_email_not_found': 'このメールアドレスは登録されていません',
    'error_cannot_logout_current': '現在のデバイスはログアウトできません',
    'error_device_not_found': 'デバイスが見つかりません',
    'error_task_title_invalid': 'タスクタイトルが空または長すぎます',
    'error_task_date_out_of_range': '日付が範囲外です',
    'error_task_daily_limit': '1日のタスク数が上限を超えました（最大50件）',
    'error_task_repeat_invalid': '繰り返し設定の形式が不正です',
    'error_task_has_incomplete_subtasks': '未完了のサブタスクがあるため完了できません',
    'error_task_parent_not_found': '親タスクが見つかりません',
    'error_task_subtask_limit': 'サブタスク数が上限を超えました（最大20件）',
    'error_focus_session_exists': '進行中の集中セッションがあります',
    'error_nickname_too_frequent': 'ニックネームは7日間で最大2回まで変更できます',
    'nickname_change_limit_title': '変更回数の上限に達しました',
    'password_required': 'パスワードを入力してください',
    'password_min_length': 'パスワードは6文字以上必要です',
    'welcome_back': 'お帰りなさい',
    'create_account': 'アカウント作成',
    'sign_in_continue': 'サインインしてプランニングを続けましょう',
    'join_us': '一緒にプランニングを始めましょう',

    // Plan Page
    'planning_streak_prefix': 'プラン継続',
    'planning_streak_suffix': '日目',
    'back_to_today': '今日に戻る',
    'add_task': 'タスク追加',
    'new_task': '新しいタスク',
    'quick_add': 'クイック追加',
    'task_title': 'タスク名',
    'task_description': '説明',
    'priority': '優先度',
    'date': '日付',
    'repeat': '繰り返し',
    'subtasks': 'サブタスク',
    'add_subtask': 'サブタスク追加',
    'no_tasks': 'この日のタスクはありません',
    'all_done': '全て完了！',
    'celebration_default': '今日も素晴らしい！',
    'tasks_remaining': '件のタスクが残っています',

    // Priority
    'priority_p0': 'P0 - 緊急＆重要',
    'priority_p1': 'P1 - 重要',
    'priority_p2': 'P2 - 緊急',
    'priority_p3': 'P3 - 後で',
    'priority_p0_label': '今すぐ実行',
    'priority_p0_desc': '緊急かつ重要',
    'priority_p1_label': '計画を立てる',
    'priority_p1_desc': '重要だが緊急ではない',
    'priority_p2_label': '早急に対応',
    'priority_p2_desc': '緊急だが重要ではない',
    'priority_p3_label': '延期または中止',
    'priority_p3_desc': '緊急でも重要でもない',

    // Repeat
    'repeat_none': 'なし',
    'repeat_daily': '毎日',
    'repeat_weekly': '毎週',
    'repeat_monthly': '毎月',
    'repeat_yearly': '毎年',

    // View Page
    'view_week': '週間',
    'view_month': '月間',
    'pending': '未完了',
    'overdue': '期限切れ',
    'completed': '完了',
    'no_tasks_pending': '未完了のタスクはありません',
    'no_tasks_overdue': '期限切れのタスクはありません',
    'no_tasks_completed': '完了したタスクはありません',

    // Focus Page
    'focus_title': '集中',
    'focus_start': '集中開始',
    'focus_pause': '一時停止',
    'focus_resume': '再開',
    'focus_stop': '停止',
    'focus_reset': 'リセット',
    'focus_complete': '集中完了！',
    'focus_sessions': '集中回数',
    'focus_total_time': '合計時間',
    'focus_today': '今日',
    'focus_this_week': '今週',
    'focus_history': '履歴',
    'minutes': '分',
    'hours': '時間',
    'pomodoro': 'ポモドーロ',
    'short_break': '短い休憩',
    'long_break': '長い休憩',
    'pomodoro_completed': 'ポモドーロ完了！',
    'pomodoro_completed_next': 'ポモドーロ完了！次のラウンドを開始...',
    'total_focus_time': '合計集中時間',
    'total_focus_hours': '合計時間',
    'total_focus_seconds': '合計秒数',
    'longest_session': '最長セッション',
    'times': '回',
    'pause_first': 'タイマーを一時停止または終了してください',
    'set_focus_duration': '集中時間を設定',
    'duration_hint': '10 - 60 分',
    'sec': '秒',
    'min': '分',
    'focus_in_progress': '集中中...',
    'ready_to_focus': '準備完了',
    'set_time': '時間設定',
    'end': '終了',
    'auto_start_next': '次のラウンドを自動開始',
    'start_focus': '集中開始',
    'starting': '開始中...',
    'focus_start_failed': '集中を開始できません',
    'focus_duration_too_short': '集中時間は10分以上にしてください',
    'focus_duration_too_long': '集中時間は60分を超えることはできません',
    'focus_counted': '集中時間が記録されました:',
    'focus_not_counted': '50%未満のため、今回の集中は記録されません',
    'close': '閉じる',

    // Me Page
    'me_title': 'マイページ',
    'planning_streak': 'プラン継続',
    'days': '日',
    'edit_nickname': 'ニックネーム編集',
    'nickname_empty': 'ニックネームを入力してください',
    'nickname_max_length': 'ニックネームは20文字以内',
    'leaving_so_soon': 'もう行っちゃうの？',
    'logout_message': '寂しくなるよ！また目標達成しに来てね。',
    'stay': '残る',
    'ip_address': 'IP:',

    // Account Section
    'account': 'アカウント',
    'change_password': 'パスワード変更',
    'logout': 'ログアウト',
    'logout_confirm_title': 'ログアウト',
    'logout_confirm_message': 'ログアウトしますか？',
    'current_password': '現在のパスワード',
    'new_password': '新しいパスワード',
    'confirm_new_password': '新しいパスワード（確認）',
    'update_password': 'パスワード更新',
    'password_updated': 'パスワードを更新しました',
    'all_fields_required': 'すべての項目を入力してください',
    'new_passwords_mismatch': '新しいパスワードが一致しません',

    // Settings Section
    'settings': '設定',
    'sound_effects': '効果音',
    'device_management': 'デバイス管理',
    'language': '言語',
    'devices_logged_in': '台のデバイスでログイン中',
    'current_device': '現在のデバイス',
    'last_login': '最終ログイン',
    'loading_devices': 'デバイスを読み込み中...',
    'refresh': '更新',
    'no_other_devices': '他にログイン中のデバイスはありません',
    'logout_device_success': 'デバイスからログアウトしました',

    // Avatar
    'choose_avatar': 'アバター選択',

    // Celebration
    'celebration_title': 'おめでとう！',
    'celebration_message': '今日のタスクを全て完了しました！',

    // Calendar
    'today': '今日',
    'yesterday': '昨日',
    'tomorrow': '明日',
    'mon': '月',
    'tue': '火',
    'wed': '水',
    'thu': '木',
    'fri': '金',
    'sat': '土',
    'sun': '日',

    // Months
    'month_1': '1月',
    'month_2': '2月',
    'month_3': '3月',
    'month_4': '4月',
    'month_5': '5月',
    'month_6': '6月',
    'month_7': '7月',
    'month_8': '8月',
    'month_9': '9月',
    'month_10': '10月',
    'month_11': '11月',
    'month_12': '12月',

    // Eisenhower Matrix
    'eisenhower_matrix': 'アイゼンハワーマトリクス',

    // Quadrant titles
    'quadrant_p0_title': '今すぐ実行',
    'quadrant_p0_desc': '緊急＆重要',
    'quadrant_p1_title': '計画を立てる',
    'quadrant_p1_desc': '重要、緊急でない',
    'quadrant_p2_title': '早急に対応',
    'quadrant_p2_desc': '緊急、重要でない',
    'quadrant_p3_title': '延期または中止',
    'quadrant_p3_desc': '緊急でも重要でもない',

    // Task Actions
    'delete_task': 'タスク削除',
    'delete_task_confirm': 'このタスクを削除しますか？',
    'mark_complete': '完了にする',
    'mark_incomplete': '未完了にする',

    // Sheets - Add Task
    'what_needs_done': '何をする必要がありますか？',
    'save_task': 'タスクを保存',
    'quadrant': '象限',
    'auto_adjusted_today': '今日に自動調整されました',
    'invalid_task_name': '有効なタスク名を入力してください',
    'task_name_too_long': 'タスク名は100文字以内で入力してください',
    'select_day': '日付を選択',
    'every_nth_of_month': '毎月%s日',
    'repeat_on_nth': '毎月%s日に繰り返し',

    // Sheets - Subtask
    'new_subtask': '新規サブタスク',
    'save_subtask': 'サブタスクを保存',
    'invalid_subtask_name': '有効なサブタスク名を入力してください',
    'subtask_name_too_long': 'サブタスク名は100文字以内で入力してください',
    'subtasks_title': 'サブタスク',
    'no_subtasks_yet': 'サブタスクはまだありません',

    // Sheets - Edit Task
    'edit_task': 'タスクを編集',
    'task_name': 'タスク名',
    'save_changes': '変更を保存',
    'confirm_delete': '削除の確認',
    'delete_repeating_confirm': 'すべての繰り返しタスク（将来のものを含む）を削除しますか？',
    'delete_this_task': 'このタスクを削除しますか？',

    // Sheets - Me Page
    'logout_device': 'デバイスからログアウト',
    'logout_device_confirm': '「%s」からログアウトしますか？',
    'device_logged_out': '「%s」からログアウトしました',
    'my_devices': 'マイデバイス',
    'days_ago': '%d日前',

    // Additional keys for sheets and auth pages
    'enter_current_password': '現在のパスワードを入力してください',
    'enter_new_password': '新しいパスワードを入力してください',
    'confirm_password_empty': '新しいパスワードを確認してください',
    'passwords_not_match': 'パスワードが一致しません',
    'password_changed': 'パスワードが変更されました',
    'error_old_password_wrong': '現在のパスワードが正しくありません',
    'other_devices_logged_out': '他のデバイスがログアウトされました',
    'new_password_same_as_old': '新しいパスワードは現在のパスワードと同じにできません',
    'please_use_different_password': '現在のパスワードと異なるパスワードを設定してください',
    'just_now': 'たった今',
    'minutes_ago': '%d分前',
    'hours_ago': '%d時間前',
    'select_language': '言語を選択',

    // Statistics Page (additional keys)
    'all': 'すべて',
    'all_tasks': 'すべてのタスク',
    'week': '週',
    'month': '月',
    'completion_rate': '完了率',
    'todo': '未完了',
    'ongoing_tasks': '進行中',
    'unfinished': '未完了',
    'reschedule': '再スケジュール',
    'week_1': '第1週',
    'week_2': '第2週',
    'week_3': '第3週',
    'week_4': '第4週',

    'app_slogan': '毎日を簡単に整理',
    'no_account': 'アカウントをお持ちでないですか？',
    'sign_up': '新規登録',
    'retrieve_password': 'パスワードを取得',
    'enter_email_reset': 'メールアドレスを入力してパスワードを回復してください。',
    'send': '送信',
    'sending': '送信中...',
    'reset_link_sent': 'リセットリンクがメールに送信されました',
    'password_reset_email_sent': 'メール送信完了',
    'check_email_for_reset_link': 'パスワードリセットメールを送信しました。メールボックスをご確認ください。',
    'email_send_limit': '1分後に再送信してください',
    'have_account': 'すでにアカウントをお持ちですか？',
    'sign_up_to_start': '登録して始める',
    'registration_successful': '登録成功',
    'redirect_to_login': 'ログインページに移動中...',
    'registration_failed': '登録に失敗しました',
    'network_error': 'ネットワークエラー、再試行してください',
    'error_parse': 'レスポンス解析エラー',

    // Made in China
    'made_in_china': '中国で愛を込めてデザインしました',
  };
}

/// Global shortcut for translation
String tr(String key) => LocaleService.instance.tr(key);
