import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/image_copy_viewmodel.dart';
import 'widgets/window_title_bar.dart';
import 'tools/image_copy_page.dart' as tools;

/// 主页视图
///
/// 应用的主界面，包含:
/// - 自定义标题栏
/// - 侧边导航栏
/// - 内容区域
/// - 状态栏
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const _HomeViewContent(),
    );
  }
}

class _HomeViewContent extends StatelessWidget {
  const _HomeViewContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

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
                // 侧边导航栏
                _buildSidebar(context, viewModel),
                // 内容区域
                Expanded(child: _buildContentArea(context, viewModel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建侧边导航栏
  Widget _buildSidebar(BuildContext context, HomeViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outline.withAlpha(25)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // 导航项
          ...List.generate(
            viewModel.navItems.length,
            (index) => _NavItem(
              icon: viewModel.navItems[index].icon,
              label: viewModel.navItems[index].label,
              tooltip: viewModel.navItems[index].tooltip,
              isSelected: viewModel.selectedIndex == index,
              onTap: () => viewModel.setSelectedIndex(index),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentArea(BuildContext context, HomeViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 页面标题
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  viewModel.getPageTitle(viewModel.selectedIndex),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                // 窗口状态指示器
                if (viewModel.isMaximized)
                  _StatusBadge(
                    icon: Icons.crop_square,
                    label: '最大化',
                    color: colorScheme.primary,
                  ),
                if (viewModel.isAlwaysOnTop) ...[
                  const SizedBox(width: 8),
                  _StatusBadge(
                    icon: Icons.push_pin,
                    label: '置顶',
                    color: colorScheme.tertiary,
                  ),
                ],
              ],
            ),
          ),
          // 页面内容
          Expanded(
            child: _buildPageContent(viewModel.selectedIndex, viewModel),
          ),
        ],
      ),
    );
  }

  /// 根据索引构建页面内容
  Widget _buildPageContent(int index, HomeViewModel viewModel) {
    switch (index) {
      case 0:
        return ChangeNotifierProvider(
          create: (_) => ImageCopyViewModel(),
          child: const tools.ImageCopyPageContent(),
        );
      case 1:
        return _SettingsPageContent(viewModel: viewModel);
      default:
        return ChangeNotifierProvider(
          create: (_) => ImageCopyViewModel(),
          child: const tools.ImageCopyPageContent(),
        );
    }
  }
}

/// 导航项组件
class _NavItem extends StatelessWidget {
  final int icon;
  final String label;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconData(icon, fontFamily: 'MaterialIcons'),
                size: 24,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface.withAlpha(153),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 状态徽章组件
class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 页面内容组件 ====================

/// 设置页面
class _SettingsPageContent extends StatelessWidget {
  final HomeViewModel viewModel;

  const _SettingsPageContent({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 窗口设置
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '窗口设置',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingTile(
                    icon: Icons.push_pin,
                    title: '窗口置顶',
                    subtitle: '将窗口保持在其他窗口之上',
                    trailing: Switch(
                      value: viewModel.isAlwaysOnTop,
                      onChanged: (_) => viewModel.toggleAlwaysOnTop(),
                    ),
                  ),
                  const Divider(),
                  _SettingTile(
                    icon: Icons.fullscreen,
                    title: '全屏模式',
                    subtitle: '进入或退出全屏模式',
                    trailing: Switch(
                      value: viewModel.isFullScreen,
                      onChanged: (_) => viewModel.toggleFullScreen(),
                    ),
                  ),
                  const Divider(),
                  _SettingTile(
                    icon: Icons.center_focus_strong,
                    title: '居中窗口',
                    subtitle: '将窗口移动到屏幕中央',
                    trailing: TextButton(
                      onPressed: viewModel.centerWindow,
                      child: const Text('居中'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 外观设置
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '外观',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 透明度设置
                  Row(
                    children: [
                      Icon(Icons.opacity, color: colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('窗口透明度', style: theme.textTheme.bodyMedium),
                            Text(
                              '调整窗口的透明程度',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withAlpha(153),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('30%'),
                      Expanded(
                        child: Slider(
                          value: viewModel.opacitySliderValue,
                          min: 0.3,
                          max: 1.0,
                          divisions: 14,
                          label:
                              '${(viewModel.opacitySliderValue * 100).toInt()}%',
                          onChanged: viewModel.setWindowOpacity,
                        ),
                      ),
                      const Text('100%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 设置项
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha(153),
        ),
      ),
      trailing: trailing,
    );
  }
}
