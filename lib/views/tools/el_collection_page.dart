import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../models/el_collection_task.dart';
import '../../viewmodels/el_collection_viewmodel.dart';

/// EL图片收集页面（独立页面版本）
class ELCollectionPage extends StatelessWidget {
  const ELCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ELCollectionViewModel()..init(),
      child: const _ELCollectionPageScaffold(),
    );
  }
}

/// 带 AppBar 的独立页面版本
class _ELCollectionPageScaffold extends StatelessWidget {
  const _ELCollectionPageScaffold();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.collections),
            SizedBox(width: 12),
            Text('离线EL收集'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showLineConfigDialogStatic(context),
            tooltip: '线别配置',
          ),
        ],
      ),
      body: const ELCollectionPageContent(),
    );
  }
}

/// 显示线别配置对话框（静态方法）
void _showLineConfigDialogStatic(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('线别配置'),
      content: const Text('线别配置管理功能将在后续版本完善。\n配置文件位置: config/line_config.json'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}

/// EL图片收集页面内容（路由使用）
class ELCollectionPageContent extends StatelessWidget {
  const ELCollectionPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ELCollectionViewModel()..init(),
      child: const _ELCollectionContentBody(),
    );
  }
}

/// EL图片收集内容体
class _ELCollectionContentBody extends StatefulWidget {
  const _ELCollectionContentBody();

  @override
  State<_ELCollectionContentBody> createState() =>
      _ELCollectionContentBodyState();
}

class _ELCollectionContentBodyState extends State<_ELCollectionContentBody> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ELCollectionViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLineConfigSection(context, viewModel),
          const SizedBox(height: 16),
          _buildDateShiftSection(context, viewModel),
          const SizedBox(height: 16),
          _buildTimeSlotsSection(context, viewModel),
          const SizedBox(height: 16),
          _buildDefectTypesSection(context, viewModel),
          const SizedBox(height: 16),
          _buildTargetDirSection(context, viewModel),
          const SizedBox(height: 24),
          _buildActionButtons(context, viewModel),
          const SizedBox(height: 24),
          if (viewModel.isRunning ||
              viewModel.task.images.isNotEmpty ||
              viewModel.task.status == ELCollectionStatus.completed ||
              viewModel.task.status == ELCollectionStatus.error)
            _buildProgressSection(context, viewModel),
        ],
      ),
    );
  }

  /// 线别配置区域 - 下拉选择，东西区互斥
  Widget _buildLineConfigSection(
    BuildContext context,
    ELCollectionViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final task = viewModel.task;

    // 获取所有区域
    final regions = viewModel.lineConfigs.map((c) => c.region).toSet().toList()
      ..sort();

    // 获取当前选中的区域（从已选线别中推断）
    String? selectedRegion;
    if (task.selectedLineConfigs.isNotEmpty) {
      selectedRegion = task.selectedLineConfigs.first.region;
    }

    // 获取当前区域下的线别
    final currentRegionLines = selectedRegion != null
        ? viewModel.lineConfigs
              .where((c) => c.region == selectedRegion)
              .toList()
        : <LineConfig>[];

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('线别配置', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  onPressed: () => _showLineConfigDialog(context),
                  tooltip: '编辑配置',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (viewModel.lineConfigs.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 区域选择下拉框
                  DropdownButtonFormField<String>(
                    value: selectedRegion,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '选择区域',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('请选择区域'),
                    items: regions.map((region) {
                      return DropdownMenuItem(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                    onChanged: (region) {
                      if (region != null) {
                        // 切换区域时，清空之前的线别选择（东西区互斥）
                        viewModel.clearLineConfigs();
                        // 自动全选当前区域的所有线别
                        final regionConfigs = viewModel.lineConfigs
                            .where((c) => c.region == region)
                            .toList();
                        for (final config in regionConfigs) {
                          viewModel.toggleLineConfig(config);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // 线别多选下拉框
                  if (selectedRegion != null) ...[
                    InkWell(
                      onTap: () => _showLineMultiSelectDialog(
                        context,
                        viewModel,
                        currentRegionLines,
                        task.selectedLineConfigs,
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '选择线别',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: task.selectedLineConfigs.isEmpty
                            ? const Text(
                                '请选择线别',
                                style: TextStyle(color: Colors.grey),
                              )
                            : Text(
                                '已选择 ${task.selectedLineConfigs.length} 个线别',
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 显示已选线别
                    if (task.selectedLineConfigs.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: task.selectedLineConfigs.map((config) {
                          return Chip(
                            label: Text(config.lineName),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => viewModel.toggleLineConfig(config),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 显示线别多选对话框
  void _showLineMultiSelectDialog(
    BuildContext context,
    ELCollectionViewModel viewModel,
    List<LineConfig> availableLines,
    List<LineConfig> selectedLines,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择线别'),
              content: SizedBox(
                width: 300,
                height: 300,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: availableLines.map((line) {
                      final isSelected = selectedLines.any(
                        (c) =>
                            c.region == line.region &&
                            c.lineName == line.lineName,
                      );
                      return CheckboxListTile(
                        title: Text(line.lineName),
                        value: isSelected,
                        onChanged: (checked) {
                          viewModel.toggleLineConfig(line);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('完成'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 日期班次区域
  Widget _buildDateShiftSection(
    BuildContext context,
    ELCollectionViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final task = viewModel.task;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('日期与班次', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            // 日期选择
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: '日期',
                      hintText: '20260205',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(text: task.date),
                    onChanged: viewModel.setDate,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: viewModel.useTodayDate,
                  icon: const Icon(Icons.today),
                  label: const Text('今天'),
                ),
                TextButton.icon(
                  onPressed: viewModel.useYesterdayDate,
                  icon: const Icon(Icons.history),
                  label: const Text('昨天'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 班次选择
            Row(
              children: [
                const Text('班次:'),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('白班 (8:30-20:30)'),
                  selected: task.shift == ShiftType.dayShift,
                  onSelected: (_) => viewModel.setShift(ShiftType.dayShift),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('夜班 (20:30-8:30)'),
                  selected: task.shift == ShiftType.nightShift,
                  onSelected: (_) => viewModel.setShift(ShiftType.nightShift),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 时间段区域
  Widget _buildTimeSlotsSection(
    BuildContext context,
    ELCollectionViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final task = viewModel.task;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('时间段', style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    TextButton(
                      onPressed: viewModel.selectAllTimeSlots,
                      child: const Text('全选'),
                    ),
                    TextButton(
                      onPressed: viewModel.clearTimeSlots,
                      child: const Text('清空'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (task.shift == null)
              const Text('请先选择班次')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: task.shift!.timeSlots.map((slot) {
                  final isSelected = task.timeSlots.contains(slot);
                  return FilterChip(
                    label: Text('$slot:00'),
                    selected: isSelected,
                    onSelected: (_) => viewModel.toggleTimeSlot(slot),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// 脏污类型区域
  Widget _buildDefectTypesSection(
    BuildContext context,
    ELCollectionViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final task = viewModel.task;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('脏污类型', style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _showDefectTypeManager(context, viewModel),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('管理'),
                    ),
                    TextButton(
                      onPressed: viewModel.selectAllDefectTypes,
                      child: const Text('全选'),
                    ),
                    TextButton(
                      onPressed: viewModel.clearDefectTypes,
                      child: const Text('清空'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (viewModel.defectTypes.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: viewModel.defectTypes.map((defect) {
                  final isSelected = task.defectTypes.contains(
                    defect.folderName,
                  );
                  return FilterChip(
                    label: Text(defect.name),
                    selected: isSelected,
                    onSelected: (_) =>
                        viewModel.toggleDefectType(defect.folderName),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// 目标目录区域
  Widget _buildTargetDirSection(
    BuildContext context,
    ELCollectionViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final task = viewModel.task;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目标目录', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.targetDir.isEmpty ? '未选择' : task.targetDir,
                      style: TextStyle(
                        color: task.targetDir.isEmpty
                            ? colorScheme.outline
                            : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: viewModel.selectTargetDirectory,
                  child: const Text('选择'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButtons(
    BuildContext context,
    ELCollectionViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final task = viewModel.task;

    return Row(
      children: [
        FilledButton.icon(
          onPressed: task.canScan && !viewModel.isRunning
              ? viewModel.startScan
              : null,
          icon: task.status == ELCollectionStatus.scanning
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
            task.status == ELCollectionStatus.scanning ? '扫描中...' : '开始扫描',
          ),
          style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: task.canCopy && !viewModel.isRunning
              ? viewModel.startCopy
              : null,
          icon: task.status == ELCollectionStatus.copying
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
            task.status == ELCollectionStatus.copying ? '复制中...' : '开始复制',
          ),
          style: FilledButton.styleFrom(backgroundColor: colorScheme.secondary),
        ),
        if (viewModel.isRunning) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: viewModel.cancelTask,
            icon: const Icon(Icons.stop),
            label: const Text('取消'),
            style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
          ),
        ],
        const Spacer(),
        if (task.images.isNotEmpty ||
            task.status == ELCollectionStatus.completed)
          TextButton.icon(
            onPressed: viewModel.resetTask,
            icon: const Icon(Icons.refresh),
            label: const Text('重置'),
          ),
      ],
    );
  }

  /// 进度区域
  Widget _buildProgressSection(
    BuildContext context,
    ELCollectionViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final task = viewModel.task;

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
                Text(
                  _getStatusText(task.status),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 当前扫描路径
            if (task.status == ELCollectionStatus.scanning &&
                task.currentScanningPath != null)
              Text(
                '正在扫描: ${task.currentScanningPath}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            // 进度条
            if (task.status == ELCollectionStatus.copying)
              LinearProgressIndicator(value: task.progress),

            const SizedBox(height: 16),

            // 统计信息
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _StatItem(label: '找到图片', value: '${task.images.length} 张'),
                if (task.status == ELCollectionStatus.copying ||
                    task.status == ELCollectionStatus.completed)
                  _StatItem(
                    label: '已复制',
                    value: '${task.copiedCount} 张',
                    color: Colors.green,
                  ),
                if (task.failedCount > 0)
                  _StatItem(
                    label: '失败',
                    value: '${task.failedCount} 张',
                    color: Colors.red,
                  ),
                _StatItem(label: '总大小', value: task.formattedTotalSize),
              ],
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
                    Icon(Icons.error_outline, color: colorScheme.error),
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

  String _getStatusText(ELCollectionStatus status) {
    switch (status) {
      case ELCollectionStatus.idle:
        return '准备就绪';
      case ELCollectionStatus.scanning:
        return '正在扫描...';
      case ELCollectionStatus.copying:
        return '正在复制...';
      case ELCollectionStatus.completed:
        return '任务完成';
      case ELCollectionStatus.error:
        return '任务出错';
      case ELCollectionStatus.cancelled:
        return '已取消';
    }
  }

  /// 显示线别配置对话框
  void _showLineConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('线别配置'),
        content: const Text(
          '线别配置管理功能将在后续版本完善。\n配置文件位置: config/line_config.json',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示脏污类型管理对话框
  void _showDefectTypeManager(
    BuildContext context,
    ELCollectionViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => _DefectTypeManagerDialog(viewModel: viewModel),
    );
  }
}

/// 状态图标
class _StatusIcon extends StatelessWidget {
  final ELCollectionStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case ELCollectionStatus.idle:
        return Icon(Icons.hourglass_empty, color: colorScheme.outline);
      case ELCollectionStatus.scanning:
      case ELCollectionStatus.copying:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        );
      case ELCollectionStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case ELCollectionStatus.error:
        return Icon(Icons.error, color: colorScheme.error);
      case ELCollectionStatus.cancelled:
        return Icon(Icons.cancel, color: colorScheme.outline);
    }
  }
}

/// 统计项
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

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
      child: Text(
        '$label: $value',
        style: TextStyle(color: itemColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 脏污类型管理对话框
class _DefectTypeManagerDialog extends StatefulWidget {
  final ELCollectionViewModel viewModel;

  const _DefectTypeManagerDialog({required this.viewModel});

  @override
  State<_DefectTypeManagerDialog> createState() =>
      _DefectTypeManagerDialogState();
}

class _DefectTypeManagerDialogState extends State<_DefectTypeManagerDialog> {
  @override
  Widget build(BuildContext context) {
    final defectTypes = widget.viewModel.defectTypes;

    return AlertDialog(
      title: Row(
        children: [
          const Text('管理脏污类型'),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showAddDefectTypeDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加'),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: defectTypes.isEmpty
            ? const Center(child: Text('暂无脏污类型'))
            : ListView.builder(
                itemCount: defectTypes.length,
                itemBuilder: (context, index) {
                  final defect = defectTypes[index];
                  return ListTile(
                    title: Text(defect.name),
                    subtitle: Text(defect.folderName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _showEditDefectTypeDialog(context, defect),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _showDeleteConfirm(context, defect),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await widget.viewModel.resetToDefaultDefectTypes();
            setState(() {});
          },
          child: const Text('恢复默认'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  /// 显示添加对话框
  void _showAddDefectTypeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final folderController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加脏污类型'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '显示名称',
                  hintText: '如：脏污、划伤',
                ),
                validator: (v) => v?.isEmpty ?? true ? '请输入名称' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: folderController,
                decoration: const InputDecoration(
                  labelText: '文件夹名称',
                  hintText: '如：NG_脏污_B',
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return '请输入文件夹名称';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final nav = Navigator.of(context);
                await widget.viewModel.addDefectType(
                  nameController.text.trim(),
                  folderController.text.trim(),
                );
                if (mounted) {
                  setState(() {});
                  nav.pop();
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 显示编辑对话框
  void _showEditDefectTypeDialog(BuildContext context, DefectType defect) {
    final nameController = TextEditingController(text: defect.name);
    final folderController = TextEditingController(text: defect.folderName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑脏污类型'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '显示名称'),
                validator: (v) => v?.isEmpty ?? true ? '请输入名称' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: folderController,
                decoration: const InputDecoration(labelText: '文件夹名称'),
                validator: (v) {
                  if (v?.isEmpty ?? true) return '请输入文件夹名称';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final nav = Navigator.of(context);
                await widget.viewModel.updateDefectType(
                  defect.folderName,
                  nameController.text.trim(),
                  folderController.text.trim(),
                );
                if (mounted) {
                  setState(() {});
                  nav.pop();
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认
  void _showDeleteConfirm(BuildContext context, DefectType defect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${defect.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await widget.viewModel.removeDefectType(defect.folderName);
              if (mounted) {
                setState(() {});
                nav.pop();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
