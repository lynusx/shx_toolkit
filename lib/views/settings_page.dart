import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: context.read<HomeViewModel>(),
      child: const _SettingsPageContent(),
    );
  }
}

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
          // 页面标题
          Text(
            '设置',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
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
