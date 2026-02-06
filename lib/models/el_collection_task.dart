/// EL图片收集任务状态
enum ELCollectionStatus {
  idle,       // 空闲
  scanning,   // 扫描中
  copying,    // 复制中
  completed,  // 完成
  error,      // 错误
  cancelled,  // 已取消
}

/// 班次类型
enum ShiftType {
  dayShift,   // 白班 8:30-20:30
  nightShift, // 夜班 20:30-8:30
}

extension ShiftTypeExtension on ShiftType {
  String get displayName {
    switch (this) {
      case ShiftType.dayShift:
        return '白班';
      case ShiftType.nightShift:
        return '夜班';
    }
  }

  /// 获取时间段列表
  List<int> get timeSlots {
    switch (this) {
      case ShiftType.dayShift:
        return [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
      case ShiftType.nightShift:
        return [20, 0, 1, 2, 3, 4, 5, 6, 7];
    }
  }
}

/// 班次工具类
class ShiftTypeUtil {
  /// 根据当前时间自动判断班次
  static ShiftType getCurrentShift() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final timeValue = hour * 60 + minute;
    
    // 白班: 8:30-20:30 (510-1230)
    // 夜班: 20:30-8:30 (1230-510)
    final dayShiftStart = 8 * 60 + 30;  // 510
    final dayShiftEnd = 20 * 60 + 30;   // 1230
    
    if (timeValue >= dayShiftStart && timeValue < dayShiftEnd) {
      return ShiftType.dayShift;
    } else {
      return ShiftType.nightShift;
    }
  }

  /// 获取当前时间段
  static int getCurrentTimeSlot() {
    final now = DateTime.now();
    return now.hour;
  }
}

/// 线别配置
class LineConfig {
  final String region;    // 区域（东区/西区）
  final String lineName;  // 线别名称（1A, 1B等）
  final String ipAddress; // IP地址（\10.108.8.232）

  const LineConfig({
    required this.region,
    required this.lineName,
    required this.ipAddress,
  });

  /// 完整路径前缀
  String get basePath => '$ipAddress\\SaveImages\\A-01-B';

  String get displayName => '$region-$lineName';
}

/// 脏污类型
class DefectType {
  final String name;      // 显示名称
  final String folderName; // 文件夹名称（如 NG_脏污_B）

  const DefectType({
    required this.name,
    required this.folderName,
  });

  /// 默认脏污类型列表
  static const List<DefectType> defaults = [
    DefectType(name: '脏污', folderName: 'NG_脏污_B'),
    DefectType(name: '划伤', folderName: 'NG_划伤_B'),
    DefectType(name: '断删', folderName: 'NG_断删_A'),
    DefectType(name: '隐裂', folderName: 'NG_隐裂_A'),
    DefectType(name: '虚焊', folderName: 'NG_虚焊_A'),
    DefectType(name: '异物', folderName: 'NG_异物_B'),
  ];
}

/// EL图片文件信息
class ELImageFile {
  final String path;           // 完整路径
  final String name;           // 文件名
  final String lineName;       // 线别
  final String date;           // 日期
  final String shift;          // 班次
  final int timeSlot;          // 时间段
  final String defectType;     // 脏污类型
  final int size;              // 文件大小
  final DateTime modifiedTime; // 修改时间

  const ELImageFile({
    required this.path,
    required this.name,
    required this.lineName,
    required this.date,
    required this.shift,
    required this.timeSlot,
    required this.defectType,
    required this.size,
    required this.modifiedTime,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}

/// EL图片收集任务
class ELCollectionTask {
  // 配置参数
  final LineConfig? lineConfig;           // 线别配置
  final String date;                      // 日期（20260205）
  final ShiftType? shift;                 // 班次
  final List<int> timeSlots;              // 时间段列表
  final List<String> defectTypes;         // 脏污类型列表
  final String targetDir;                 // 目标目录
  
  // 任务状态
  final ELCollectionStatus status;
  final List<ELImageFile> images;         // 扫描到的图片
  final int copiedCount;                  // 已复制数量
  final int failedCount;                  // 失败数量
  final String? errorMessage;             // 错误信息
  final DateTime? startTime;              // 开始时间
  final DateTime? endTime;                // 结束时间
  final String? currentScanningPath;      // 当前正在扫描的路径

  const ELCollectionTask({
    this.lineConfig,
    this.date = '',
    this.shift,
    this.timeSlots = const [],
    this.defectTypes = const [],
    this.targetDir = '',
    this.status = ELCollectionStatus.idle,
    this.images = const [],
    this.copiedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    this.startTime,
    this.endTime,
    this.currentScanningPath,
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
    if (size < 1024 * 1024 * 1024) return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  /// 获取任务耗时
  Duration? get elapsedTime {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  /// 是否可以开始扫描
  bool get canScan => lineConfig != null && date.isNotEmpty;

  /// 是否可以开始复制
  bool get canCopy => images.isNotEmpty && targetDir.isNotEmpty;

  ELCollectionTask copyWith({
    LineConfig? lineConfig,
    String? date,
    ShiftType? shift,
    List<int>? timeSlots,
    List<String>? defectTypes,
    String? targetDir,
    ELCollectionStatus? status,
    List<ELImageFile>? images,
    int? copiedCount,
    int? failedCount,
    String? errorMessage,
    DateTime? startTime,
    DateTime? endTime,
    String? currentScanningPath,
  }) {
    return ELCollectionTask(
      lineConfig: lineConfig ?? this.lineConfig,
      date: date ?? this.date,
      shift: shift ?? this.shift,
      timeSlots: timeSlots ?? this.timeSlots,
      defectTypes: defectTypes ?? this.defectTypes,
      targetDir: targetDir ?? this.targetDir,
      status: status ?? this.status,
      images: images ?? this.images,
      copiedCount: copiedCount ?? this.copiedCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentScanningPath: currentScanningPath ?? this.currentScanningPath,
    );
  }
}
