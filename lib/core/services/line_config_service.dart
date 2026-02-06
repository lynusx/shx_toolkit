import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../models/el_collection_task.dart';

/// 线别配置管理服务
///
/// 负责加载、保存和管理线别配置JSON文件
class LineConfigService {
  static final LineConfigService _instance = LineConfigService._internal();
  factory LineConfigService() => _instance;
  LineConfigService._internal();

  // 配置文件名
  static const String _configFileName = 'line_config.json';

  // 默认配置
  static const Map<String, dynamic> _defaultConfig = {
    "东区": {
      "1A": "\\\\10.108.8.232",
      "1B": "\\\\10.108.8.231",
      "2A": "\\\\10.108.8.230",
      "2B": "\\\\10.108.8.229",
      "3A": "\\\\10.108.8.228",
      "3B": "\\\\10.108.8.227",
      "4A": "\\\\10.108.8.226",
      "4B": "\\\\10.108.8.225",
      "5A": "\\\\10.108.8.224",
      "5B": "\\\\10.108.8.223",
      "6A": "\\\\10.108.8.222",
      "6B": "\\\\10.108.8.221",
      "7A": "\\\\10.108.8.220",
      "7B": "\\\\10.108.8.219",
      "8A": "\\\\10.108.8.218",
      "8B": "\\\\10.108.8.217",
      "9A": "\\\\10.108.8.216",
      "9B": "\\\\10.108.8.215",
      "10A": "\\\\10.108.8.214",
      "10B": "\\\\10.108.8.213",
      "LX2": "\\\\10.108.3.107",
      "LX3": "\\\\10.108.3.108",
    },
    "西区": {
      "1A": "\\\\10.108.229.131",
      "1B": "\\\\10.108.229.132",
      "2A": "\\\\10.108.229.133",
      "2B": "\\\\10.108.229.134",
      "3A": "\\\\10.108.229.135",
      "3B": "\\\\10.108.229.136",
      "4A": "\\\\10.108.229.137",
      "4B": "\\\\10.108.229.138",
      "5A": "\\\\10.108.229.139",
      "5B": "\\\\10.108.229.140",
      "6A": "\\\\10.108.229.141",
      "6B": "\\\\10.108.229.142",
      "7A": "\\\\10.108.229.143",
      "7B": "\\\\10.108.229.144",
      "8A": "\\\\10.108.229.145",
      "8B": "\\\\10.108.229.146",
      "9A": "\\\\10.108.229.147",
      "9B": "\\\\10.108.229.148",
      "10A": "\\\\10.108.229.149",
      "10B": "\\\\10.108.229.150",
      "LX1": "\\\\10.108.229.151",
      "LX2": "\\\\10.108.229.152",
      "LX3": "\\\\10.108.229.153",
    },
  };

  // 配置缓存
  List<LineConfig>? _cachedConfigs;

  /// 获取配置文件路径
  Future<String> get _configFilePath async {
    // 使用应用程序文档目录
    final appDir = await _getAppDirectory();
    return path.join(appDir, _configFileName);
  }

  /// 获取应用配置目录
  Future<String> _getAppDirectory() async {
    // 简化为当前工作目录下的 config 文件夹
    final configDir = Directory(path.join(Directory.current.path, 'config'));
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    return configDir.path;
  }

  /// 加载线别配置
  Future<List<LineConfig>> loadConfigs() async {
    if (_cachedConfigs != null) {
      return _cachedConfigs!;
    }

    try {
      final configPath = await _configFilePath;
      final file = File(configPath);

      Map<String, dynamic> jsonData;

      if (await file.exists()) {
        // 读取现有配置
        final content = await file.readAsString();
        jsonData = jsonDecode(content);
      } else {
        // 使用默认配置并保存
        jsonData = _defaultConfig;
        await saveConfigs(jsonData);
      }

      _cachedConfigs = _parseConfigs(jsonData);
      return _cachedConfigs!;
    } catch (e) {
      if (kDebugMode) {
        print('加载线别配置失败: $e');
      }
      // 返回默认配置
      _cachedConfigs = _parseConfigs(_defaultConfig);
      return _cachedConfigs!;
    }
  }

  /// 保存线别配置
  Future<void> saveConfigs(Map<String, dynamic> config) async {
    try {
      final configPath = await _configFilePath;
      final file = File(configPath);

      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(config);

      await file.writeAsString(jsonString);

      // 更新缓存
      _cachedConfigs = _parseConfigs(config);
    } catch (e) {
      if (kDebugMode) {
        print('保存线别配置失败: $e');
      }
      throw Exception('保存配置失败: $e');
    }
  }

  /// 解析配置JSON
  List<LineConfig> _parseConfigs(Map<String, dynamic> jsonData) {
    final List<LineConfig> configs = [];

    jsonData.forEach((region, lines) {
      if (lines is Map<String, dynamic>) {
        lines.forEach((lineName, ipAddress) {
          configs.add(
            LineConfig(
              region: region,
              lineName: lineName,
              ipAddress: ipAddress.toString(),
            ),
          );
        });
      }
    });

    // 按区域和线别排序
    configs.sort((a, b) {
      final regionCompare = a.region.compareTo(b.region);
      if (regionCompare != 0) return regionCompare;
      return a.lineName.compareTo(b.lineName);
    });

    return configs;
  }

  /// 将配置转换为JSON
  Map<String, dynamic> configsToJson(List<LineConfig> configs) {
    final Map<String, dynamic> result = {};

    for (final config in configs) {
      if (!result.containsKey(config.region)) {
        result[config.region] = {};
      }
      result[config.region][config.lineName] = config.ipAddress;
    }

    return result;
  }

  /// 添加线别配置
  Future<void> addConfig(LineConfig config) async {
    final configs = await loadConfigs();

    // 检查是否已存在
    final existingIndex = configs.indexWhere(
      (c) => c.region == config.region && c.lineName == config.lineName,
    );

    if (existingIndex >= 0) {
      configs[existingIndex] = config;
    } else {
      configs.add(config);
    }

    await saveConfigs(configsToJson(configs));
  }

  /// 删除线别配置
  Future<void> removeConfig(String region, String lineName) async {
    final configs = await loadConfigs();
    configs.removeWhere((c) => c.region == region && c.lineName == lineName);
    await saveConfigs(configsToJson(configs));
  }

  /// 获取所有区域
  Future<List<String>> getRegions() async {
    final configs = await loadConfigs();
    return configs.map((c) => c.region).toSet().toList()..sort();
  }

  /// 获取指定区域的线别
  Future<List<LineConfig>> getLinesByRegion(String region) async {
    final configs = await loadConfigs();
    return configs.where((c) => c.region == region).toList();
  }

  /// 重置为默认配置
  Future<void> resetToDefault() async {
    await saveConfigs(_defaultConfig);
  }

  /// 清除缓存
  void clearCache() {
    _cachedConfigs = null;
  }
}
