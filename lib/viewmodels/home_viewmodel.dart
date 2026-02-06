import 'dart:async';
import '../core/services/window_service.dart';
import '../models/window_state.dart';
import 'base_viewmodel.dart';

/// 主页 ViewModel
///
/// 管理主页的业务逻辑和状态，包括:
/// - 窗口状态管理
/// - 透明度控制
///
/// 注意：侧边栏导航由 go_router 管理，不再使用 selectedIndex
class HomeViewModel extends BaseViewModel {
  final WindowService _windowService = WindowService();

  // 窗口状态
  WindowState _windowState = const WindowState();

  // 透明度滑块值（0.1 - 1.0）
  double _opacitySliderValue = 1.0;

  // Getters
  WindowState get windowState => _windowState;
  double get opacitySliderValue => _opacitySliderValue;
  bool get isMaximized => _windowState.isMaximized;
  bool get isAlwaysOnTop => _windowState.isAlwaysOnTop;
  bool get isFullScreen => _windowState.isFullScreen;

  // 导航菜单项（供 NavigationRail 使用）
  final List<NavItem> navItems = [
    NavItem(
      icon: 0xe3b6,
      label: '离线EL',
      tooltip: '离线EL图片收集',
    ), // Icons.collections
    NavItem(icon: 0xe8b8, label: '设置', tooltip: '应用设置'), // Icons.settings
  ];

  StreamSubscription? _windowStateSubscription;

  HomeViewModel() {
    _init();
  }

  void _init() {
    // 监听窗口状态变化
    _windowService.addStateListener(_onWindowStateChanged);
    _windowState = _windowService.currentState;
    _opacitySliderValue = _windowState.opacity;
    notifyListeners();
  }

  void _onWindowStateChanged(WindowState state) {
    _windowState = state;
    _opacitySliderValue = state.opacity;
    notifyListeners();
  }

  // ==================== 窗口控制 ====================

  /// 关闭窗口
  Future<void> closeWindow() async {
    await _windowService.closeWindow();
  }

  /// 最小化窗口
  Future<void> minimizeWindow() async {
    await _windowService.minimizeWindow();
  }

  /// 最大化/恢复窗口
  Future<void> toggleMaximize() async {
    await _windowService.toggleMaximize();
  }

  /// 全屏切换
  Future<void> toggleFullScreen() async {
    await _windowService.toggleFullScreen();
  }

  /// 置顶切换
  Future<void> toggleAlwaysOnTop() async {
    await _windowService.toggleAlwaysOnTop();
  }

  /// 设置窗口透明度
  Future<void> setWindowOpacity(double opacity) async {
    _opacitySliderValue = opacity;
    await _windowService.setOpacity(opacity);
    // 不需要 notifyListeners，因为状态监听会触发更新
  }

  /// 开始拖拽窗口
  Future<void> startDragging() async {
    await _windowService.startDragging();
  }

  /// 居中窗口
  Future<void> centerWindow() async {
    await _windowService.centerWindow();
  }

  @override
  void dispose() {
    _windowService.removeStateListener(_onWindowStateChanged);
    _windowStateSubscription?.cancel();
    super.dispose();
  }
}

/// 导航项数据类
class NavItem {
  final int icon;
  final String label;
  final String tooltip;

  const NavItem({
    required this.icon,
    required this.label,
    required this.tooltip,
  });
}
