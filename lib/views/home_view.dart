import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../viewmodels/home_viewmodel.dart';
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
                Expanded(
                  child: _buildContentArea(context, viewModel),
                ),
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
          right: BorderSide(
            color: colorScheme.outline.withAlpha(25),
          ),
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
          // 透明度调节
          _OpacitySlider(
            value: viewModel.opacitySliderValue,
            onChanged: viewModel.setWindowOpacity,
          ),
          const SizedBox(height: 16),
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
            child: _buildPageContent(viewModel.selectedIndex),
          ),
        ],
      ),
    );
  }

  /// 根据索引构建页面内容
  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return const _HomePageContent();
      case 1:
        return const _ToolsPageContent();
      case 2:
        return const _SettingsPageContent();
      case 3:
        return const _AboutPageContent();
      default:
        return const _HomePageContent();
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

/// 透明度滑块组件
class _OpacitySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _OpacitySlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: '窗口透明度: ${(value * 100).toInt()}%',
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RotatedBox(
          quarterTurns: 3,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 12,
              ),
            ),
            child: Slider(
              value: value,
              min: 0.3,
              max: 1.0,
              onChanged: onChanged,
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.outline.withAlpha(50),
            ),
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

/// 首页内容
class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欢迎卡片
          Card(
            elevation: 0,
            color: colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.desktop_windows,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '欢迎使用 SHX Toolkit',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '这是一个基于 MVVM 架构的 Flutter 桌面应用示例，集成了 window_manager 进行窗口管理。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 功能特性
          Text(
            '功能特性',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _FeatureCard(
                icon: Icons.window,
                title: '窗口管理',
                description: '支持最大化、最小化、全屏、置顶等操作',
                color: colorScheme.primary,
              ),
              _FeatureCard(
                icon: Icons.opacity,
                title: '透明调节',
                description: '可自由调节窗口透明度',
                color: colorScheme.secondary,
              ),
              _FeatureCard(
                icon: Icons.drag_indicator,
                title: '自定义标题栏',
                description: '自定义样式的窗口标题栏',
                color: colorScheme.tertiary,
              ),
              _FeatureCard(
                icon: Icons.architecture,
                title: 'MVVM 架构',
                description: '清晰的分层架构设计',
                color: colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 特性卡片
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 工具箱页面
class _ToolsPageContent extends StatelessWidget {
  const _ToolsPageContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 页面标题
          Text(
            '实用工具',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '选择下面的工具开始使用',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 24),
          // 工具列表
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ToolCard(
                icon: Icons.copy,
                title: '图片拷贝',
                description: '递归扫描目录中的所有图片文件，并复制到指定目录',
                color: colorScheme.primary,
                onTap: () => _openImageCopyTool(context),
              ),
              // 可以在这里添加更多工具卡片
            ],
          ),
        ],
      ),
    );
  }

  /// 打开图片拷贝工具
  void _openImageCopyTool(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        insetPadding: EdgeInsets.all(24),
        child: SizedBox(
          width: 900,
          height: 700,
          child: tools.ImageCopyPage(),
        ),
      ),
    );
  }
}

/// 工具卡片
class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: color.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(50)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '开始使用',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 设置页面
class _SettingsPageContent extends StatelessWidget {
  const _SettingsPageContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
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

/// 关于页面
class _AboutPageContent extends StatelessWidget {
  const _AboutPageContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 应用图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.apps,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '版本 ${AppConstants.appVersion}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '一款基于 Flutter 和 window_manager 构建的桌面应用，'
              '采用 MVVM 架构设计，提供流畅的用户体验。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(204),
              ),
            ),
            const SizedBox(height: 32),
            // 技术栈
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _TechChip(label: 'Flutter', color: colorScheme.primary),
                _TechChip(label: 'Dart', color: colorScheme.secondary),
                _TechChip(label: 'window_manager', color: colorScheme.tertiary),
                _TechChip(label: 'MVVM', color: colorScheme.error),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 技术标签
class _TechChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TechChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
