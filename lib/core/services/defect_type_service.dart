import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../models/el_collection_task.dart';

/// 脏污类型配置管理服务
class DefectTypeService {
  static final DefectTypeService _instance = DefectTypeService._internal();
  factory DefectTypeService() => _instance;
  DefectTypeService._internal();

  // 配置文件名
  static const String _configFileName = 'defect_types.json';

  // 默认配置
  static const List<Map<String, String>> _defaultConfig = [
    {'name': '脏污', 'folderName': 'NG_脏污_B'},
    {'name': '划伤', 'folderName': 'NG_划伤_B'},
    {'name': '断删', 'folderName': 'NG_断删_A'},
    {'name': '隐裂', 'folderName': 'NG_隐裂_A'},
    {'name': '虚焊', 'folderName': 'NG_虚焊_A'},
    {'name': '异物', 'folderName': 'NG_异物_B'},
    {'name': '崩边', 'folderName': 'NG_崩边_B'},
    {'name': '色差', 'folderName': 'NG_色差_A'},
  ];

  // 配置缓存
  List<DefectType>? _cachedTypes;

  /// 获取配置文件路径
  Future<String> get _configFilePath async {
    final appDir = await _getAppDirectory();
    return path.join(appDir, _configFileName);
  }

  /// 获取应用配置目录
  Future<String> _getAppDirectory() async {
    final configDir = Directory(path.join(Directory.current.path, 'config'));
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    return configDir.path;
  }

  /// 加载脏污类型配置
  Future<List<DefectType>> loadDefectTypes() async {
    if (_cachedTypes != null) {
      return _cachedTypes!;
    }

    try {
      final configPath = await _configFilePath;
      final file = File(configPath);

      List<dynamic> jsonData;

      if (await file.exists()) {
        final content = await file.readAsString();
        jsonData = jsonDecode(content);
      } else {
        jsonData = _defaultConfig;
        await saveDefectTypes(_parseDefectTypes(jsonData));
      }

      _cachedTypes = _parseDefectTypes(jsonData);
      return _cachedTypes!;
    } catch (e) {
      if (kDebugMode) {
        print('加载脏污类型配置失败: $e');
      }
      _cachedTypes = _parseDefectTypes(_defaultConfig);
      return _cachedTypes!;
    }
  }

  /// 保存脏污类型配置
  Future<void> saveDefectTypes(List<DefectType> types) async {
    try {
      final configPath = await _configFilePath;
      final file = File(configPath);

      final jsonData = types
          .map((t) => {'name': t.name, 'folderName': t.folderName})
          .toList();

      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(jsonData);

      await file.writeAsString(jsonString);
      _cachedTypes = types;
    } catch (e) {
      if (kDebugMode) {
        print('保存脏污类型配置失败: $e');
      }
      throw Exception('保存配置失败: $e');
    }
  }

  /// 解析配置JSON
  List<DefectType> _parseDefectTypes(List<dynamic> jsonData) {
    return jsonData
        .map(
          (item) => DefectType(
            name: item['name'] as String,
            folderName: item['folderName'] as String,
          ),
        )
        .toList();
  }

  /// 添加脏污类型
  Future<void> addDefectType(DefectType defectType) async {
    final types = await loadDefectTypes();

    // 检查是否已存在
    final existingIndex = types.indexWhere(
      (t) => t.folderName == defectType.folderName,
    );

    if (existingIndex >= 0) {
      types[existingIndex] = defectType;
    } else {
      types.add(defectType);
    }

    await saveDefectTypes(types);
  }

  /// 删除脏污类型
  Future<void> removeDefectType(String folderName) async {
    final types = await loadDefectTypes();
    types.removeWhere((t) => t.folderName == folderName);
    await saveDefectTypes(types);
  }

  /// 更新脏污类型
  Future<void> updateDefectType(
    String oldFolderName,
    DefectType newType,
  ) async {
    final types = await loadDefectTypes();
    final index = types.indexWhere((t) => t.folderName == oldFolderName);
    if (index >= 0) {
      types[index] = newType;
      await saveDefectTypes(types);
    }
  }

  /// 重置为默认配置
  Future<void> resetToDefault() async {
    await saveDefectTypes(_parseDefectTypes(_defaultConfig));
  }

  /// 清除缓存
  void clearCache() {
    _cachedTypes = null;
  }

  /// 验证文件夹名称格式
  static bool isValidFolderName(String folderName) {
    // 验证格式：NG_xxx_A/B
    final pattern = RegExp(r'^NG_[\u4e00-\u9fa5_a-zA-Z0-9]+_[AB]$');
    return pattern.hasMatch(folderName);
  }

  /// 生成建议的文件夹名称
  static String suggestFolderName(String name) {
    // 从名称生成建议的文件夹名称
    final pinyin = name.replaceAll(RegExp(r'[^\u4e00-\u9fa5a-zA-Z0-9]'), '');
    return 'NG_${pinyin}_B';
  }
}
