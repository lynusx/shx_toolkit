import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../core/services/defect_type_service.dart';
import '../core/services/line_config_service.dart';
import '../models/el_collection_task.dart';
import 'base_viewmodel.dart';

/// EL图片收集 ViewModel
class ELCollectionViewModel extends BaseViewModel {
  final LineConfigService _lineConfigService = LineConfigService();
  final DefectTypeService _defectTypeService = DefectTypeService();

  // 任务状态
  ELCollectionTask _task = const ELCollectionTask();

  // 线别配置列表
  List<LineConfig> _lineConfigs = [];

  // 脏污类型列表
  List<DefectType> _defectTypes = [];

  // 取消标记
  bool _isCancelled = false;

  // Getters
  ELCollectionTask get task => _task;
  List<LineConfig> get lineConfigs => _lineConfigs;
  List<DefectType> get defectTypes => _defectTypes;
  bool get isRunning =>
      task.status == ELCollectionStatus.scanning ||
      task.status == ELCollectionStatus.copying;

  /// 初始化
  Future<void> init() async {
    await Future.wait([_loadLineConfigs(), _loadDefectTypes()]);
    _initDefaultValues();
  }

  /// 加载线别配置
  Future<void> _loadLineConfigs() async {
    try {
      _lineConfigs = await _lineConfigService.loadConfigs();
      notifyListeners();
    } catch (e) {
      setError('加载线别配置失败: $e');
    }
  }

  /// 加载脏污类型
  Future<void> _loadDefectTypes() async {
    try {
      _defectTypes = await _defectTypeService.loadDefectTypes();
      notifyListeners();
    } catch (e) {
      setError('加载脏污类型失败: $e');
    }
  }

  /// 初始化默认值
  void _initDefaultValues() {
    final now = DateTime.now();
    final shift = ShiftTypeUtil.getCurrentShift();
    final timeSlot = ShiftTypeUtil.getCurrentTimeSlot();

    // 检查当前时间段是否在班次范围内
    final validTimeSlots = shift.timeSlots;
    final selectedTimeSlots = validTimeSlots.contains(timeSlot)
        ? [timeSlot]
        : validTimeSlots;

    _task = ELCollectionTask(
      date: DateFormat('yyyyMMdd').format(now),
      shift: shift,
      timeSlots: selectedTimeSlots,
      defectTypes: DefectType.defaults.map((d) => d.folderName).toList(),
    );
    notifyListeners();
  }

  // ==================== 配置设置 ====================

  /// 切换线别选择（支持多选，东西区互斥）
  void toggleLineConfig(LineConfig config) {
    final currentConfigs = List<LineConfig>.from(_task.lineConfigs);
    final configIndex = currentConfigs.indexWhere(
      (c) => c.region == config.region && c.lineName == config.lineName,
    );

    if (configIndex >= 0) {
      // 如果已选中，则取消选择
      currentConfigs.removeAt(configIndex);
    } else {
      // 如果未选中，先检查是否选择了不同区域的线别
      if (currentConfigs.isNotEmpty) {
        final firstRegion = currentConfigs.first.region;
        if (firstRegion != config.region) {
          // 选择了不同区域，清空当前选择
          currentConfigs.clear();
        }
      }
      // 添加新选择的线别
      currentConfigs.add(config);
    }

    _task = _task.copyWith(lineConfigs: currentConfigs);
    notifyListeners();
  }

  /// 清空线别选择
  void clearLineConfigs() {
    _task = _task.copyWith(lineConfigs: []);
    notifyListeners();
  }

  /// 检查线别是否已选中
  bool isLineConfigSelected(LineConfig config) {
    return _task.lineConfigs.any(
      (c) => c.region == config.region && c.lineName == config.lineName,
    );
  }

  /// 设置日期
  void setDate(String date) {
    _task = _task.copyWith(date: date);
    notifyListeners();
  }

  /// 使用今天日期
  void useTodayDate() {
    final now = DateTime.now();
    setDate(DateFormat('yyyyMMdd').format(now));
  }

  /// 使用昨天日期
  void useYesterdayDate() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    setDate(DateFormat('yyyyMMdd').format(yesterday));
  }

  /// 设置班次
  void setShift(ShiftType? shift) {
    // 切换班次时自动更新时间段
    final newTimeSlots = shift?.timeSlots ?? [];
    _task = _task.copyWith(shift: shift, timeSlots: newTimeSlots);
    notifyListeners();
  }

  /// 切换时间段选择
  void toggleTimeSlot(int timeSlot) {
    final currentSlots = List<int>.from(_task.timeSlots);
    if (currentSlots.contains(timeSlot)) {
      currentSlots.remove(timeSlot);
    } else {
      currentSlots.add(timeSlot);
      currentSlots.sort();
    }
    _task = _task.copyWith(timeSlots: currentSlots);
    notifyListeners();
  }

  /// 全选时间段
  void selectAllTimeSlots() {
    if (_task.shift != null) {
      _task = _task.copyWith(timeSlots: _task.shift!.timeSlots);
      notifyListeners();
    }
  }

  /// 清空时间段
  void clearTimeSlots() {
    _task = _task.copyWith(timeSlots: []);
    notifyListeners();
  }

  /// 切换脏污类型
  void toggleDefectType(String defectType) {
    final currentTypes = List<String>.from(_task.defectTypes);
    if (currentTypes.contains(defectType)) {
      currentTypes.remove(defectType);
    } else {
      currentTypes.add(defectType);
    }
    _task = _task.copyWith(defectTypes: currentTypes);
    notifyListeners();
  }

  /// 全选脏污类型
  void selectAllDefectTypes() {
    _task = _task.copyWith(
      defectTypes: DefectType.defaults.map((d) => d.folderName).toList(),
    );
    notifyListeners();
  }

  /// 清空脏污类型
  void clearDefectTypes() {
    _task = _task.copyWith(defectTypes: []);
    notifyListeners();
  }

  /// 选择目标目录
  Future<void> selectTargetDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择目标目录',
        lockParentWindow: true,
      );

      if (selectedDirectory != null) {
        _task = _task.copyWith(targetDir: selectedDirectory);
        notifyListeners();
      }
    } catch (e) {
      setError('无法打开目录选择器: $e');
    }
  }

  // ==================== 扫描和复制 ====================

  /// 开始扫描
  Future<void> startScan() async {
    if (_task.lineConfigs.isEmpty) {
      setError('请至少选择一个线别');
      return;
    }
    if (_task.date.isEmpty) {
      setError('请输入日期');
      return;
    }
    if (_task.shift == null) {
      setError('请选择班次');
      return;
    }
    if (_task.timeSlots.isEmpty) {
      setError('请至少选择一个时间段');
      return;
    }
    if (_task.defectTypes.isEmpty) {
      setError('请至少选择一种脏污类型');
      return;
    }

    _isCancelled = false;
    clearError();

    try {
      await _scanImages();
    } catch (e) {
      if (!_isCancelled) {
        _task = _task.copyWith(
          status: ELCollectionStatus.error,
          errorMessage: e.toString(),
        );
        setError(e.toString());
        notifyListeners();
      }
    }
  }

  /// 扫描图片（智能剪枝）
  Future<void> _scanImages() async {
    _task = _task.copyWith(
      status: ELCollectionStatus.scanning,
      images: [],
      copiedCount: 0,
      failedCount: 0,
      errorMessage: null,
      startTime: DateTime.now(),
      endTime: null,
      currentScanningPath: null,
    );
    notifyListeners();

    final List<ELImageFile> images = [];
    final List<String> scanErrors = []; // 收集扫描错误
    final date = _task.date;
    final shiftName = _task.shift!.displayName;

    // 遍历所有选中的线别
    for (final lineConfig in _task.lineConfigs) {
      if (_isCancelled) break;

      final basePath = lineConfig.basePath;

      // 构建扫描路径列表
      for (final timeSlot in _task.timeSlots) {
        for (final defectType in _task.defectTypes) {
          // 构建完整路径: \\ip\SaveImages\A-01-B\20260205\夜班\21\NG_脏污_B
          final scanPath = path.join(
            basePath,
            date,
            shiftName,
            timeSlot.toString(),
            defectType,
          );

          if (_isCancelled) break;

          _task = _task.copyWith(currentScanningPath: scanPath);
          notifyListeners();

          // 检查目录是否存在（剪枝）- 包裹在try-catch中防止网络路径错误
          final dir = Directory(scanPath);
          bool dirExists = false;
          try {
            dirExists = await dir.exists();
          } catch (e) {
            // 网络路径访问失败，记录错误但继续执行
            final errorMsg = '无法访问路径: $scanPath';
            if (!scanErrors.contains(errorMsg)) {
              scanErrors.add(errorMsg);
            }
            if (kDebugMode) {
              print('$errorMsg, 错误: $e');
            }
            continue;
          }

          if (!dirExists) {
            // 目录不存在，直接剪枝
            continue;
          }

          // 扫描目录中的图片文件
          try {
            await for (final entity in dir.list(followLinks: false)) {
              if (_isCancelled) break;

              if (entity is File) {
                final ext = path.extension(entity.path).toLowerCase();
                if (ext == '.png' ||
                    ext == '.jpg' ||
                    ext == '.jpeg' ||
                    ext == '.bmp') {
                  try {
                    final stat = await entity.stat();
                    images.add(
                      ELImageFile(
                        path: entity.path,
                        name: path.basename(entity.path),
                        lineName: lineConfig.displayName,
                        date: date,
                        shift: shiftName,
                        timeSlot: timeSlot,
                        defectType: defectType,
                        size: stat.size,
                        modifiedTime: stat.modified,
                      ),
                    );

                    // 每扫描到10个文件更新一次
                    if (images.length % 10 == 0) {
                      _task = _task.copyWith(images: List.unmodifiable(images));
                      notifyListeners();
                    }
                  } catch (e) {
                    // 忽略无法访问的文件
                    if (kDebugMode) {
                      print('无法读取文件: ${entity.path}, 错误: $e');
                    }
                  }
                }
              }
            }
          } catch (e) {
            // 目录访问失败，记录错误但继续下一个
            final errorMsg = '访问目录失败: $scanPath';
            if (!scanErrors.contains(errorMsg)) {
              scanErrors.add(errorMsg);
            }
            if (kDebugMode) {
              print('$errorMsg, 错误: $e');
            }
          }
        }
      }
      if (_isCancelled) break;
    }

    if (!_isCancelled) {
      // 如果有错误，构建错误信息
      String? finalErrorMessage;
      if (scanErrors.isNotEmpty && images.isEmpty) {
        // 只有错误且没有扫描到图片时，显示错误
        finalErrorMessage = scanErrors.length == 1
            ? scanErrors.first
            : '扫描过程中遇到 ${scanErrors.length} 个错误:\n${scanErrors.take(3).join('\n')}${scanErrors.length > 3 ? '\n...' : ''}';
      }

      _task = _task.copyWith(
        status: finalErrorMessage != null ? ELCollectionStatus.error : ELCollectionStatus.idle,
        images: List.unmodifiable(images),
        currentScanningPath: null,
        errorMessage: finalErrorMessage,
      );
      
      if (finalErrorMessage != null) {
        setError(finalErrorMessage);
      }
      
      notifyListeners();
    }
  }

  /// 开始复制
  Future<void> startCopy() async {
    if (_task.images.isEmpty) {
      setError('没有可复制的图片，请先扫描');
      return;
    }
    if (_task.targetDir.isEmpty) {
      setError('请选择目标目录');
      return;
    }

    _isCancelled = false;
    clearError();

    try {
      await _copyImages();
    } catch (e) {
      if (!_isCancelled) {
        _task = _task.copyWith(
          status: ELCollectionStatus.error,
          errorMessage: e.toString(),
          endTime: DateTime.now(),
        );
        setError(e.toString());
        notifyListeners();
      }
    }
  }

  /// 复制图片文件
  Future<void> _copyImages() async {
    _task = _task.copyWith(status: ELCollectionStatus.copying);
    notifyListeners();

    // 确保目标目录存在
    final targetDir = Directory(_task.targetDir);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    int copiedCount = 0;
    int failedCount = 0;
    final List<String> copyErrors = []; // 收集复制错误

    for (int i = 0; i < _task.images.length; i++) {
      if (_isCancelled) break;

      final image = _task.images[i];

      try {
        // 生成目标文件路径（处理重名）
        final targetPath = _generateTargetPath(image.name);

        // 复制文件
        await File(image.path).copy(targetPath);
        copiedCount++;
      } catch (e) {
        failedCount++;
        final errorMsg = '${image.name}: $e';
        copyErrors.add(errorMsg);
        if (kDebugMode) {
          print('复制文件失败: ${image.path}, 错误: $e');
        }
      }

      // 每处理5个文件更新一次进度
      if ((i + 1) % 5 == 0 || i == _task.images.length - 1) {
        _task = _task.copyWith(
          copiedCount: copiedCount,
          failedCount: failedCount,
        );
        notifyListeners();
      }
    }

    if (!_isCancelled) {
      // 构建完成状态的错误信息（如果有失败的话）
      String? finalErrorMessage;
      if (failedCount > 0) {
        finalErrorMessage = '复制完成: $copiedCount 个成功, $failedCount 个失败';
        if (copyErrors.isNotEmpty) {
          finalErrorMessage += '\n\n失败详情:\n${copyErrors.take(3).join('\n')}${copyErrors.length > 3 ? '\n...等 ${copyErrors.length} 个错误' : ''}';
        }
      }

      _task = _task.copyWith(
        status: ELCollectionStatus.completed,
        copiedCount: copiedCount,
        failedCount: failedCount,
        endTime: DateTime.now(),
        errorMessage: finalErrorMessage,
      );
      
      if (finalErrorMessage != null && failedCount > copiedCount) {
        // 如果失败数量超过成功数量，显示警告
        setError(finalErrorMessage);
      }
      
      notifyListeners();
    }
  }

  /// 生成目标文件路径（处理重名）
  String _generateTargetPath(String fileName) {
    final baseName = path.basenameWithoutExtension(fileName);
    final ext = path.extension(fileName);

    String targetPath = path.join(_task.targetDir, fileName);
    int counter = 1;

    // 如果文件已存在，添加序号
    while (File(targetPath).existsSync()) {
      final newName = '${baseName}_$counter$ext';
      targetPath = path.join(_task.targetDir, newName);
      counter++;
    }

    return targetPath;
  }

  /// 取消任务
  void cancelTask() {
    _isCancelled = true;
    _task = _task.copyWith(status: ELCollectionStatus.cancelled);
    notifyListeners();
  }

  /// 重置任务
  void resetTask() {
    _isCancelled = false;
    _initDefaultValues();
    _task = _task.copyWith(
      lineConfigs: [],
      targetDir: '',
      status: ELCollectionStatus.idle,
      images: [],
      copiedCount: 0,
      failedCount: 0,
      errorMessage: null,
      startTime: null,
      endTime: null,
      currentScanningPath: null,
    );
    clearError();
    notifyListeners();
  }

  // ==================== 配置管理 ====================

  /// 刷新线别配置
  Future<void> refreshLineConfigs() async {
    await _loadLineConfigs();
  }

  /// 添加线别配置
  Future<void> addLineConfig(LineConfig config) async {
    try {
      await _lineConfigService.addConfig(config);
      await _loadLineConfigs();
    } catch (e) {
      setError('添加线别配置失败: $e');
    }
  }

  /// 删除线别配置
  Future<void> removeLineConfig(String region, String lineName) async {
    try {
      await _lineConfigService.removeConfig(region, lineName);
      await _loadLineConfigs();

      // 如果当前选中的线别被删除，从选择列表中移除
      final updatedConfigs = _task.lineConfigs.where(
        (c) => !(c.region == region && c.lineName == lineName),
      ).toList();
      _task = _task.copyWith(lineConfigs: updatedConfigs);
      notifyListeners();
    } catch (e) {
      setError('删除线别配置失败: $e');
    }
  }

  /// 重置为默认配置
  Future<void> resetToDefaultConfigs() async {
    try {
      await _lineConfigService.resetToDefault();
      await _loadLineConfigs();
    } catch (e) {
      setError('重置配置失败: $e');
    }
  }

  // ==================== 脏污类型管理 ====================

  /// 刷新脏污类型
  Future<void> refreshDefectTypes() async {
    await _loadDefectTypes();
  }

  /// 添加脏污类型
  Future<void> addDefectType(String name, String folderName) async {
    try {
      final defectType = DefectType(name: name, folderName: folderName);
      await _defectTypeService.addDefectType(defectType);
      await _loadDefectTypes();
    } catch (e) {
      setError('添加脏污类型失败: $e');
    }
  }

  /// 删除脏污类型
  Future<void> removeDefectType(String folderName) async {
    try {
      await _defectTypeService.removeDefectType(folderName);
      await _loadDefectTypes();

      // 从已选列表中移除
      if (_task.defectTypes.contains(folderName)) {
        toggleDefectType(folderName);
      }
    } catch (e) {
      setError('删除脏污类型失败: $e');
    }
  }

  /// 更新脏污类型
  Future<void> updateDefectType(
    String oldFolderName,
    String newName,
    String newFolderName,
  ) async {
    try {
      final newType = DefectType(name: newName, folderName: newFolderName);
      await _defectTypeService.updateDefectType(oldFolderName, newType);
      await _loadDefectTypes();

      // 更新已选列表
      if (_task.defectTypes.contains(oldFolderName)) {
        final newTypes = List<String>.from(_task.defectTypes);
        newTypes.remove(oldFolderName);
        newTypes.add(newFolderName);
        _task = _task.copyWith(defectTypes: newTypes);
        notifyListeners();
      }
    } catch (e) {
      setError('更新脏污类型失败: $e');
    }
  }

  /// 重置为默认脏污类型
  Future<void> resetToDefaultDefectTypes() async {
    try {
      await _defectTypeService.resetToDefault();
      await _loadDefectTypes();
    } catch (e) {
      setError('重置脏污类型失败: $e');
    }
  }
}
