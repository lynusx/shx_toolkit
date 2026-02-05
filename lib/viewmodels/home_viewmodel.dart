import 'dart:async';
import '../core/services/window_service.dart';
import '../models/window_state.dart';
import 'base_viewmodel.dart';

/// 主页 ViewModel
/// 
/// 管理主页的业务逻辑和状态，包括:
/// - 窗口状态管理
/// - 透明度控制
/// - 侧边栏导航
class HomeViewModel extends BaseViewModel {
  final WindowService _windowService = WindowService();

  // 窗口状态
  WindowState _windowState = const WindowState();
  
  // 当前选中的导航索引
  int _selectedIndex = 0;
  
  // 透明度滑块值（0.1 - 1.0）
  double _opacitySliderValue = 1.0;

  // Getters
  WindowState get windowState => _windowState;
  int get selectedIndex => _selectedIndex;
  double get opacitySliderValue => _opacitySliderValue;
  bool get isMaximized => _windowState.isMaximized;
  bool get isAlwaysOnTop => _windowState.isAlwaysOnTop;
  bool get isFullScreen => _windowState.isFullScreen;

  // 导航菜单项
  final List<NavItem> navItems = [
    NavItem(icon: 0xe88a, label: '首页', tooltip: '应用首页'),
    NavItem(icon: 0xe8b8, label: '工具', tooltip: '工具箱'),
    NavItem(icon: 0xe8f9, label: '设置', tooltip: '应用设置'),
    NavItem(icon: 0xe88f, label: '关于', tooltip: '关于应用'),
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

  /// 设置选中索引
  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
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

  // ==================== 页面内容 ====================

  /// 根据索引获取页面标题
  String getPageTitle(int index) {
    switch (index) {
      case 0:
        return '首页';
      case 1:
        return '工具箱';
      case 2:
        return '设置';
      case 3:
        return '关于';
      default:
        return '首页';
    }
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
