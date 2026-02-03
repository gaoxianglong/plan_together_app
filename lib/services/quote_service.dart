import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

/// 励志名言服务
/// 负责管理名言的随机选择和定时刷新
class QuoteService {
  QuoteService._();
  static final QuoteService instance = QuoteService._();

  final _random = Random();
  Timer? _timer;
  String _currentQuote = '';
  List<String> _quotes = [];

  /// 获取当前名言
  String get currentQuote => _currentQuote;

  /// 名言更新流
  final _quoteController = StreamController<String>.broadcast();
  Stream<String> get quoteStream => _quoteController.stream;

  /// 初始化服务（启动时调用一次）
  Future<void> initialize() async {
    // 从 JSON 文件加载名言
    await _loadQuotes();
    
    // 随机选择一条初始名言
    _currentQuote = _getRandomQuote();
    _quoteController.add(_currentQuote);

    // 启动定时器，每30分钟刷新一次
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) {
      refreshQuote();
    });
  }

  /// 从 JSON 文件加载名言
  Future<void> _loadQuotes() async {
    try {
      final jsonString = await rootBundle.loadString('assets/quotes.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _quotes = List<String>.from(jsonData['quotes'] ?? []);
      
      if (_quotes.isEmpty) {
        // 如果加载失败，提供默认名言
        _quotes = ['Success is not final, failure is not fatal: it is the courage to continue that counts.'];
      }
    } catch (e) {
      // 加载失败时使用默认名言
      _quotes = ['Success is not final, failure is not fatal: it is the courage to continue that counts.'];
    }
  }

  /// 手动刷新名言
  void refreshQuote() {
    _currentQuote = _getRandomQuote();
    _quoteController.add(_currentQuote);
  }

  /// 获取随机名言
  String _getRandomQuote() {
    if (_quotes.isEmpty) {
      return 'Success is not final, failure is not fatal: it is the courage to continue that counts.';
    }
    final index = _random.nextInt(_quotes.length);
    return _quotes[index];
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
    _quoteController.close();
  }
}
