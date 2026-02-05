import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/image_copy_task.dart';
import '../../viewmodels/image_copy_viewmodel.dart';
import '../widgets/window_title_bar.dart';
import '../../core/constants/app_constants.dart';

/// 图片拷贝工具页面
class ImageCopyPage extends StatelessWidget {
  const ImageCopyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImageCopyViewModel(),
      child: const _ImageCopyPageContent(),
    );
  }
}

class _ImageCopyPageContent extends StatelessWidget {
  const _ImageCopyPageContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ImageCopyViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Column(
        children: [
          // 自定义标题栏
          WindowTitleBar(
            title: '${AppConstants.appName} - 图片拷贝',
            isMaximized: false,
            isAlwaysOnTop: false,
            onMinimize: () {},
            onMaximize: () {},
            onClose: () => Navigator.of(context).pop(),
            onStartDrag: () {},
          ),
          // 主内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 页面标题
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  // 目录选择区域
                  _buildDirectorySelection(context, viewModel),
                  const SizedBox(height: 24),
                  // 操作按钮
                  _buildActionButtons(context, viewModel),
                  const SizedBox(height: 24),
                  // 进度和结果
                  if (viewModel.isRunning || 
                      viewModel.hasCompleted || 
                      viewModel.hasError || 
                      viewModel.task.images.isNotEmpty)
                    _buildProgressSection(context, viewModel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建页面标题
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.copy,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              '图片拷贝工具',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '选择一个目录，递归扫描所有子目录中的图片文件，并复制到指定目录。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        const SizedBox(height: 8),
        // 支持的格式
        Wrap(
          spacing: 8,
          children: ImageExtensions.all.map((ext) {
            return Chip(
              label: Text(
                ext,
                style: const TextStyle(fontSize: 11),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              backgroundColor: theme.colorScheme.primaryContainer,
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建目录选择区域
  Widget _buildDirectorySelection(BuildContext context, ImageCopyViewModel viewModel) {
    return Column(
      children: [
        // 源目录选择
        _DirectorySelector(
          label: '源目录',
          hint: '选择要扫描的目录',
          path: viewModel.task.sourceDir,
          onSelect: viewModel.selectSourceDirectory,
          onClear: viewModel.clearSourceDir,
          icon: Icons.folder_open,
        ),
        const SizedBox(height: 16),
        // 目标目录选择
        _DirectorySelector(
          label: '目标目录',
          hint: '选择图片保存的目录',
          path: viewModel.task.targetDir,
          onSelect: viewModel.selectTargetDirectory,
          onClear: viewModel.clearTargetDir,
          onCreateNew: () => _showCreateFolderDialog(context, viewModel),
          icon: Icons.drive_file_move,
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context, ImageCopyViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // 开始扫描按钮
        FilledButton.icon(
          onPressed: viewModel.canScan ? viewModel.startScan : null,
          icon: viewModel.task.status == ImageCopyTaskStatus.scanning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.search),
          label: Text(
            viewModel.task.status == ImageCopyTaskStatus.scanning 
                ? '扫描中...' 
                : '开始扫描'
          ),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        
        // 开始复制按钮
        FilledButton.icon(
          onPressed: viewModel.canCopy ? viewModel.startCopy : null,
          icon: viewModel.task.status == ImageCopyTaskStatus.copying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.copy),
          label: Text(
            viewModel.task.status == ImageCopyTaskStatus.copying 
                ? '复制中...' 
                : '开始复制'
          ),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        
        // 取消按钮
        if (viewModel.isRunning)
          OutlinedButton.icon(
            onPressed: viewModel.cancelTask,
            icon: const Icon(Icons.stop),
            label: const Text('取消'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
          ),
        
        // 重置按钮
        if (viewModel.hasCompleted || viewModel.hasError || viewModel.task.images.isNotEmpty)
          OutlinedButton.icon(
            onPressed: viewModel.resetTask,
            icon: const Icon(Icons.refresh),
            label: const Text('重置'),
          ),
      ],
    );
  }

  /// 显示新建文件夹对话框
  Future<void> _showCreateFolderDialog(
    BuildContext context,
    ImageCopyViewModel viewModel,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '文件夹名称',
              hintText: '请输入文件夹名称',
              prefixIcon: Icon(Icons.folder),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入文件夹名称';
              }
              // 检查非法字符
              final invalidChars = RegExp(r'[<>"/\\|?*]');
              if (invalidChars.hasMatch(value)) {
                return '文件夹名称包含非法字符';
              }
              return null;
            },
            onFieldSubmitted: (value) {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // 选择父目录并在其下创建新文件夹
      await viewModel.createAndSelectTargetDirectory(result);
    }

    controller.dispose();
  }

  /// 构建进度区域
  Widget _buildProgressSection(BuildContext context, ImageCopyViewModel viewModel) {
    final task = viewModel.task;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态标题
            Row(
              children: [
                _StatusIcon(status: task.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStatusText(task.status),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 进度条
            if (task.status == ImageCopyTaskStatus.scanning ||
                task.status == ImageCopyTaskStatus.copying)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: colorScheme.outline.withAlpha(25),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(task.progress * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // 统计信息
            _buildStatistics(context, task),
            
            // 扫描完成提示
            if (task.status == ImageCopyTaskStatus.idle && task.images.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '扫描完成！找到 ${task.images.length} 张图片，点击"开始复制"按钮开始复制',
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            
            // 错误信息
            if (task.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息
  Widget _buildStatistics(BuildContext context, ImageCopyTask task) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _StatItem(
          label: '扫描到图片',
          value: '${task.images.length} 张',
          icon: Icons.image,
        ),
        if (task.status == ImageCopyTaskStatus.copying ||
            task.status == ImageCopyTaskStatus.completed ||
            task.status == ImageCopyTaskStatus.error)
          _StatItem(
            label: '已拷贝',
            value: '${task.copiedCount} 张',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        if (task.failedCount > 0)
          _StatItem(
            label: '失败',
            value: '${task.failedCount} 张',
            icon: Icons.error,
            color: Colors.red,
          ),
        _StatItem(
          label: '总大小',
          value: task.formattedTotalSize,
          icon: Icons.storage,
        ),
        if (task.elapsedTime != null)
          _StatItem(
            label: '耗时',
            value: _formatDuration(task.elapsedTime!),
            icon: Icons.timer,
          ),
      ],
    );
  }

  /// 获取状态文本
  String _getStatusText(ImageCopyTaskStatus status) {
    switch (status) {
      case ImageCopyTaskStatus.idle:
        return '准备就绪';
      case ImageCopyTaskStatus.scanning:
        return '正在扫描图片...';
      case ImageCopyTaskStatus.copying:
        return '正在拷贝图片...';
      case ImageCopyTaskStatus.completed:
        return '任务完成';
      case ImageCopyTaskStatus.error:
        return '任务出错';
      case ImageCopyTaskStatus.cancelled:
        return '任务已取消';
    }
  }

  /// 格式化耗时
  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} 秒';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} 分 ${duration.inSeconds % 60} 秒';
    } else {
      return '${duration.inHours} 时 ${duration.inMinutes % 60} 分';
    }
  }
}

/// 目录选择器组件
class _DirectorySelector extends StatelessWidget {
  final String label;
  final String hint;
  final String path;
  final VoidCallback onSelect;
  final VoidCallback onClear;
  final VoidCallback? onCreateNew;
  final IconData icon;

  const _DirectorySelector({
    required this.label,
    required this.hint,
    required this.path,
    required this.onSelect,
    required this.onClear,
    this.onCreateNew,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPath = path.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasPath 
                  ? colorScheme.primary.withAlpha(100)
                  : colorScheme.outline.withAlpha(50),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: hasPath ? colorScheme.primary : colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasPath)
                      Text(
                        hint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      )
                    else
                      Text(
                        path,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasPath)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: '清除',
                  visualDensity: VisualDensity.compact,
                ),
              // 新建文件夹按钮（仅目标目录显示）
              if (onCreateNew != null)
                TextButton.icon(
                  onPressed: onCreateNew,
                  icon: const Icon(Icons.create_new_folder, size: 18),
                  label: const Text('新建'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              FilledButton.tonal(
                onPressed: onSelect,
                child: const Text('选择'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 状态图标
class _StatusIcon extends StatelessWidget {
  final ImageCopyTaskStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    IconData icon;
    Color color;
    
    switch (status) {
      case ImageCopyTaskStatus.idle:
        icon = Icons.hourglass_empty;
        color = colorScheme.outline;
      case ImageCopyTaskStatus.scanning:
        icon = Icons.search;
        color = colorScheme.primary;
      case ImageCopyTaskStatus.copying:
        icon = Icons.copy;
        color = colorScheme.primary;
      case ImageCopyTaskStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
      case ImageCopyTaskStatus.error:
        icon = Icons.error;
        color = colorScheme.error;
      case ImageCopyTaskStatus.cancelled:
        icon = Icons.cancel;
        color = colorScheme.outline;
    }

    if (status == ImageCopyTaskStatus.scanning || 
        status == ImageCopyTaskStatus.copying) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    return Icon(icon, color: color);
  }
}

/// 统计项
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemColor = color ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: itemColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: itemColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(153),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }
}
