import 'package:flutter/foundation.dart';

/// ViewModel 基类
/// 
/// 提供通用的状态管理功能:
/// - 加载状态
/// - 错误处理
/// - 状态通知
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 安全地调用异步操作，自动处理加载状态和错误
  Future<T?> runAsync<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
    Function(String)? onError,
  }) async {
    if (showLoading) {
      setLoading(true);
    }
    clearError();

    try {
      final result = await operation();
      return result;
    } catch (e) {
      final errorMsg = e.toString();
      setError(errorMsg);
      onError?.call(errorMsg);
      return null;
    } finally {
      if (showLoading) {
        setLoading(false);
      }
    }
  }

  @override
  void dispose() {
    // 子类可以重写以清理资源
    super.dispose();
  }
}
