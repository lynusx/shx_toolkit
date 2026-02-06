import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/router/app_router.dart';
import '../viewmodels/home_viewmodel.dart';
import 'widgets/window_title_bar.dart';

/// 主页视图（ShellRoute 布局容器）
///
/// 应用的主界面，包含:
/// - 自定义标题栏
/// - 侧边 NavigationRail 导航
/// - 内容区域（由路由提供）
class HomeView extends StatelessWidget {
  /// 子页面内容，由 ShellRoute 提供
  final Widget child;

  const HomeView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: _HomeViewContent(child: child),
    );
  }
}

class _HomeViewContent extends StatelessWidget {
  final Widget child;

  const _HomeViewContent({required this.child});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    // 获取当前路由路径
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = AppRouter.getIndexFromPath(location);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 自定义标题栏
          WindowTitleBar(
            title: AppConstants.appName,
            isMaximized: viewModel.isMaximized,
            isAlwaysOnTop: viewModel.isAlwaysOnTop,
            onMinimize: viewModel.minimizeWindow,
            onMaximize: viewModel.toggleMaximize,
            onClose: viewModel.closeWindow,
            onStartDrag: viewModel.startDragging,
            onToggleAlwaysOnTop: viewModel.toggleAlwaysOnTop,
          ),
          // 主内容区
          Expanded(
            child: Row(
              children: [
                // 侧边 NavigationRail 导航
                _buildSidebar(context, viewModel, selectedIndex),
                // 内容区域（由路由提供）
                Expanded(child: _buildContentArea(context, child)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建侧边 NavigationRail 导航
  Widget _buildSidebar(BuildContext context, HomeViewModel viewModel, int selectedIndex) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        // 使用 go_router 导航
        final path = AppRouter.getPathFromIndex(index);
        context.go(path);
      },
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelType: NavigationRailLabelType.selected,
      minWidth: 64,
      destinations: viewModel.navItems.map((item) {
        return NavigationRailDestination(
          icon: Icon(
            IconData(item.icon, fontFamily: 'MaterialIcons'),
            color: colorScheme.onSurface.withAlpha(153),
          ),
          selectedIcon: Icon(
            IconData(item.icon, fontFamily: 'MaterialIcons'),
            color: colorScheme.onPrimaryContainer,
          ),
          label: Text(item.label),
        );
      }).toList(),
    );
  }

  /// 构建内容区域
  Widget _buildContentArea(BuildContext context, Widget child) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: child,
    );
  }
}
