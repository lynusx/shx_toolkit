import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/image_copy_task.dart';
import 'base_viewmodel.dart';

/// 图片拷贝 ViewModel
/// 
/// 管理图片拷贝任务的业务逻辑：
/// - 选择源目录和目标目录
/// - 递归扫描图片文件
/// - 执行拷贝操作
/// - 显示进度和状态
class ImageCopyViewModel extends BaseViewModel {
  ImageCopyTask _task = const ImageCopyTask(
    sourceDir: '',
    targetDir: '',
  );

  // 取消标记
  bool _isCancelled = false;
  
  // 流控制器用于进度通知
  final _progressController = StreamController<ImageCopyTask>.broadcast();
  Stream<ImageCopyTask> get progressStream => _progressController.stream;

  ImageCopyTask get task => _task;
  bool get isRunning => 
      _task.status == ImageCopyTaskStatus.scanning || 
      _task.status == ImageCopyTaskStatus.copying;
  bool get canStart => 
      _task.sourceDir.isNotEmpty && 
      _task.targetDir.isNotEmpty && 
      !isRunning;
  bool get hasCompleted => _task.status == ImageCopyTaskStatus.completed;
  @override
  bool get hasError => _task.status == ImageCopyTaskStatus.error || super.hasError;

  /// 选择源目录
  Future<void> selectSourceDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择源目录',
        lockParentWindow: true,
      );
      
      if (selectedDirectory != null && selectedDirectory != _task.sourceDir) {
        _task = ImageCopyTask(
          sourceDir: selectedDirectory,
          targetDir: _task.targetDir,
          status: ImageCopyTaskStatus.idle,
        );
        notifyListeners();
      }
    } catch (e) {
      setError('无法打开目录选择器: $e');
    }
  }

  /// 选择目标目录
  Future<void> selectTargetDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择目标目录',
        lockParentWindow: true,
      );
      
      if (selectedDirectory != null && selectedDirectory != _task.targetDir) {
        _task = _task.copyWith(
          targetDir: selectedDirectory,
          status: ImageCopyTaskStatus.idle,
        );
        notifyListeners();
      }
    } catch (e) {
      setError('无法打开目录选择器: $e');
    }
  }

  /// 选择父目录并在其下新建文件夹作为目标目录
  Future<void> createAndSelectTargetDirectory(String folderName) async {
    try {
      // 先选择父目录
      String? parentDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择父目录（将在其下创建"$folderName"文件夹）',
        lockParentWindow: true,
      );
      
      if (parentDir == null) return;

      // 在父目录下创建新文件夹
      final newFolderPath = path.join(parentDir, folderName);
      final newDir = Directory(newFolderPath);
      
      if (await newDir.exists()) {
        setError('文件夹 "$folderName" 已存在');
        return;
      }

      await newDir.create(recursive: true);
      
      _task = _task.copyWith(
        targetDir: newFolderPath,
        status: ImageCopyTaskStatus.idle,
      );
      notifyListeners();
    } catch (e) {
      setError('创建文件夹失败: $e');
    }
  }

  /// 是否可以开始扫描（只需要源目录）
  bool get canScan => _task.sourceDir.isNotEmpty && !isRunning;
  
  /// 是否可以开始复制（需要扫描完成且有图片）
  bool get canCopy => 
      _task.sourceDir.isNotEmpty && 
      _task.targetDir.isNotEmpty && 
      _task.images.isNotEmpty && 
      (_task.status == ImageCopyTaskStatus.idle || 
       _task.status == ImageCopyTaskStatus.scanning ||
       _task.status == ImageCopyTaskStatus.completed) &&
      !isRunning;

  /// 开始扫描
  Future<void> startScan() async {
    if (_task.sourceDir.isEmpty) {
      setError('请选择源目录');
      return;
    }

    _isCancelled = false;
    clearError();

    try {
      await _scanImages();
    } catch (e) {
      if (!_isCancelled) {
        _task = _task.copyWith(
          status: ImageCopyTaskStatus.error,
          errorMessage: e.toString(),
        );
        setError(e.toString());
        notifyListeners();
      }
    }
  }

  /// 开始复制
  Future<void> startCopy() async {
    if (_task.sourceDir.isEmpty || _task.targetDir.isEmpty) {
      setError('请选择源目录和目标目录');
      return;
    }

    if (_task.images.isEmpty) {
      setError('没有可复制的图片，请先扫描');
      return;
    }

    // 检查源目录和目标目录是否相同
    if (path.normalize(_task.sourceDir) == path.normalize(_task.targetDir)) {
      setError('源目录和目标目录不能相同');
      return;
    }

    // 检查目标目录是否在源目录内
    if (path.isWithin(
      path.normalize(_task.sourceDir), 
      path.normalize(_task.targetDir)
    )) {
      setError('目标目录不能在源目录内');
      return;
    }

    _isCancelled = false;
    clearError();

    try {
      await _copyImages();
    } catch (e) {
      if (!_isCancelled) {
        _task = _task.copyWith(
          status: ImageCopyTaskStatus.error,
          errorMessage: e.toString(),
          endTime: DateTime.now(),
        );
        setError(e.toString());
        notifyListeners();
      }
    }
  }

  /// 扫描图片文件
  Future<void> _scanImages() async {
    _task = _task.copyWith(
      status: ImageCopyTaskStatus.scanning,
      images: [],
      copiedCount: 0,
      failedCount: 0,
      errorMessage: null,
      startTime: DateTime.now(),
      endTime: null,
    );
    notifyListeners();

    final List<ImageFileInfo> images = [];
    final sourceDir = Directory(_task.sourceDir);

    if (!await sourceDir.exists()) {
      throw Exception('源目录不存在');
    }

    await for (final entity in sourceDir.list(recursive: true, followLinks: false)) {
      if (_isCancelled) break;

      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (ImageExtensions.all.contains(ext)) {
          try {
            final stat = await entity.stat();
            images.add(ImageFileInfo(
              path: entity.path,
              name: path.basename(entity.path),
              size: stat.size,
              modifiedTime: stat.modified,
              extension: ext,
            ));
            
            // 每扫描到 10 个文件更新一次进度
            if (images.length % 10 == 0) {
              _task = _task.copyWith(images: List.unmodifiable(images));
              notifyListeners();
            }
          } catch (e) {
            // 忽略无法访问的文件
          }
        }
      }
    }

    if (!_isCancelled) {
      _task = _task.copyWith(
        images: List.unmodifiable(images),
        status: ImageCopyTaskStatus.idle, // 扫描完成后恢复空闲状态
      );
      notifyListeners();
    }
  }

  /// 拷贝图片文件
  Future<void> _copyImages() async {
    _task = _task.copyWith(status: ImageCopyTaskStatus.copying);
    notifyListeners();

    // 确保目标目录存在
    final targetDir = Directory(_task.targetDir);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    int copiedCount = 0;
    int failedCount = 0;

    for (int i = 0; i < _task.images.length; i++) {
      if (_isCancelled) break;

      final image = _task.images[i];
      
      try {
        // 生成目标文件路径
        final targetPath = _generateTargetPath(image.name);
        
        // 复制文件
        await File(image.path).copy(targetPath);
        copiedCount++;
      } catch (e) {
        failedCount++;
        if (kDebugMode) {
          print('复制文件失败: ${image.path}, 错误: $e');
        }
      }

      // 每处理 5 个文件更新一次进度
      if ((i + 1) % 5 == 0 || i == _task.images.length - 1) {
        _task = _task.copyWith(
          copiedCount: copiedCount,
          failedCount: failedCount,
        );
        notifyListeners();
      }
    }

    if (!_isCancelled) {
      _task = _task.copyWith(
        status: ImageCopyTaskStatus.completed,
        copiedCount: copiedCount,
        failedCount: failedCount,
        endTime: DateTime.now(),
      );
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
    _task = _task.copyWith(status: ImageCopyTaskStatus.cancelled);
    notifyListeners();
  }

  /// 重置任务
  void resetTask() {
    _isCancelled = false;
    _task = ImageCopyTask(
      sourceDir: '',
      targetDir: '',
    );
    clearError();
    notifyListeners();
  }

  /// 清空源目录选择
  void clearSourceDir() {
    _task = ImageCopyTask(
      sourceDir: '',
      targetDir: _task.targetDir,
    );
    notifyListeners();
  }

  /// 清空目标目录选择
  void clearTargetDir() {
    _task = _task.copyWith(targetDir: '');
    notifyListeners();
  }

  @override
  void dispose() {
    _progressController.close();
    super.dispose();
  }
}
