/// 图片拷贝任务状态
enum ImageCopyTaskStatus {
  idle, // 空闲
  scanning, // 扫描中
  copying, // 拷贝中
  completed, // 完成
  error, // 错误
  cancelled, // 已取消
}

/// 图片文件信息
class ImageFileInfo {
  final String path; // 文件路径
  final String name; // 文件名
  final int size; // 文件大小（字节）
  final DateTime modifiedTime; // 修改时间
  final String extension; // 文件扩展名

  const ImageFileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedTime,
    required this.extension,
  });

  /// 格式化文件大小
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  String toString() => 'ImageFileInfo($name, $formattedSize)';
}

/// 图片拷贝任务
class ImageCopyTask {
  final String sourceDir; // 源目录
  final String targetDir; // 目标目录
  final ImageCopyTaskStatus status; // 任务状态
  final List<ImageFileInfo> images; // 扫描到的图片列表
  final int copiedCount; // 已拷贝数量
  final int failedCount; // 失败数量
  final String? errorMessage; // 错误信息
  final DateTime? startTime; // 开始时间
  final DateTime? endTime; // 结束时间

  const ImageCopyTask({
    required this.sourceDir,
    required this.targetDir,
    this.status = ImageCopyTaskStatus.idle,
    this.images = const [],
    this.copiedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    this.startTime,
    this.endTime,
  });

  /// 获取进度（0.0 - 1.0）
  double get progress {
    if (images.isEmpty) return 0.0;
    return (copiedCount + failedCount) / images.length;
  }

  /// 获取总文件大小
  int get totalSize => images.fold(0, (sum, img) => sum + img.size);

  /// 格式化总大小
  String get formattedTotalSize {
    final size = totalSize;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  /// 获取任务耗时
  Duration? get elapsedTime {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  ImageCopyTask copyWith({
    String? sourceDir,
    String? targetDir,
    ImageCopyTaskStatus? status,
    List<ImageFileInfo>? images,
    int? copiedCount,
    int? failedCount,
    String? errorMessage,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ImageCopyTask(
      sourceDir: sourceDir ?? this.sourceDir,
      targetDir: targetDir ?? this.targetDir,
      status: status ?? this.status,
      images: images ?? this.images,
      copiedCount: copiedCount ?? this.copiedCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// 支持的图片扩展名
class ImageExtensions {
  static const Set<String> all = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
    '.tiff',
    '.tif',
    '.svg',
    '.raw',
    '.cr2',
    '.nef',
    '.heic',
    '.heif',
    '.ico',
    '.jfif',
    '.pjpeg',
    '.pjp',
  };

  static bool isImage(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    return all.contains('.$ext');
  }
}
