import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../constants/app_constants.dart';
import '../../models/window_state.dart';

/// 窗口管理服务
///
/// 负责所有与窗口相关的操作，包括:
/// - 初始化窗口配置
/// - 窗口状态管理（最大化、最小化、全屏等）
/// - 窗口尺寸和位置控制
/// - 窗口透明度调节
class WindowService with WindowListener {
  static final WindowService _instance = WindowService._internal();
  factory WindowService() => _instance;
  WindowService._internal();

  // 窗口状态变化回调
  final List<Function(WindowState)> _stateListeners = [];
  WindowState _currentState = const WindowState();

  WindowState get currentState => _currentState;

  /// 初始化窗口管理器
  Future<void> initialize() async {
    await windowManager.ensureInitialized();

    // 配置窗口选项
    WindowOptions windowOptions = const WindowOptions(
      size: Size(
        AppConstants.defaultWindowWidth,
        AppConstants.defaultWindowHeight,
      ),
      minimumSize: Size(
        AppConstants.minWindowWidth,
        AppConstants.minWindowHeight,
      ),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // 隐藏默认标题栏，使用自定义
      title: AppConstants.appName,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // 添加窗口监听
    windowManager.addListener(this);

    // 同步初始状态
    await _syncWindowState();
  }

  /// 添加状态监听（自动防止重复添加）
  void addStateListener(Function(WindowState) listener) {
    // 先移除已存在的相同监听器，防止重复
    _stateListeners.remove(listener);
    _stateListeners.add(listener);
  }

  /// 移除状态监听
  void removeStateListener(Function(WindowState) listener) {
    _stateListeners.remove(listener);
  }

  /// 清除所有状态监听
  void clearStateListeners() {
    _stateListeners.clear();
  }

  /// 通知所有监听器状态变化
  void _notifyStateChanged() {
    for (var listener in _stateListeners) {
      listener(_currentState);
    }
  }

  /// 同步窗口状态
  Future<void> _syncWindowState() async {
    _currentState = WindowState(
      isMaximized: await windowManager.isMaximized(),
      isMinimized: await windowManager.isMinimized(),
      isFullScreen: await windowManager.isFullScreen(),
      isAlwaysOnTop: await windowManager.isAlwaysOnTop(),
      opacity: await windowManager.getOpacity(),
    );
    _notifyStateChanged();
  }

  // ==================== 窗口控制方法 ====================

  /// 关闭窗口
  Future<void> closeWindow() async {
    await windowManager.close();
  }

  /// 最小化窗口
  Future<void> minimizeWindow() async {
    await windowManager.minimize();
  }

  /// 最大化/恢复窗口
  Future<void> toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  /// 全屏切换
  Future<void> toggleFullScreen() async {
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    } else {
      await windowManager.setFullScreen(true);
    }
  }

  /// 置顶切换
  Future<void> toggleAlwaysOnTop() async {
    if (await windowManager.isAlwaysOnTop()) {
      await windowManager.setAlwaysOnTop(false);
    } else {
      await windowManager.setAlwaysOnTop(true);
    }
  }

  /// 设置窗口透明度
  Future<void> setOpacity(double opacity) async {
    final clampedOpacity = opacity.clamp(0.1, 1.0);
    await windowManager.setOpacity(clampedOpacity);
    _currentState = _currentState.copyWith(opacity: clampedOpacity);
    _notifyStateChanged();
  }

  /// 开始拖拽窗口
  Future<void> startDragging() async {
    await windowManager.startDragging();
  }

  /// 设置窗口大小
  Future<void> setWindowSize(double width, double height) async {
    await windowManager.setSize(Size(width, height));
  }

  /// 居中窗口
  Future<void> centerWindow() async {
    await windowManager.center();
  }

  /// 显示窗口
  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// 隐藏窗口
  Future<void> hideWindow() async {
    await windowManager.hide();
  }

  // ==================== WindowListener 回调 ====================

  @override
  void onWindowResize() {
    _syncWindowState();
  }

  @override
  void onWindowMove() {
    _syncWindowState();
  }

  @override
  void onWindowMaximize() {
    _currentState = _currentState.copyWith(isMaximized: true);
    _notifyStateChanged();
  }

  @override
  void onWindowUnmaximize() {
    _currentState = _currentState.copyWith(isMaximized: false);
    _notifyStateChanged();
  }

  @override
  void onWindowMinimize() {
    _currentState = _currentState.copyWith(isMinimized: true);
    _notifyStateChanged();
  }

  @override
  void onWindowRestore() {
    _currentState = _currentState.copyWith(isMinimized: false);
    _notifyStateChanged();
  }

  @override
  void onWindowEnterFullScreen() {
    _currentState = _currentState.copyWith(isFullScreen: true);
    _notifyStateChanged();
  }

  @override
  void onWindowLeaveFullScreen() {
    _currentState = _currentState.copyWith(isFullScreen: false);
    _notifyStateChanged();
  }

  @override
  void onWindowEvent(String eventName) {
    debugPrint('Window event: $eventName');
  }

  @override
  void onWindowClose() {
    // 可以在这里添加关闭前的确认逻辑
    _stateListeners.clear();
    windowManager.removeListener(this);
  }

  @override
  void onWindowBlur() {}

  @override
  void onWindowFocus() {}

  @override
  void onWindowDocked() {}

  @override
  void onWindowUndocked() {}
}
