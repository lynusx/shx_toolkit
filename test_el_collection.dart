import 'dart:io';
import 'dart:convert';

/// EL图片收集测试脚本
/// 
/// 使用方法:
/// 1. 创建测试目录: mkdir -p test_data/...
/// 2. 运行测试: dart test_el_collection.dart

void main() async {
  print('=== EL图片收集功能测试 ===\n');

  // 测试配置
  final testConfig = {
    '测试线别': {
      '1A': 'test_data/line_10.108.8.232',
    }
  };

  // 保存测试配置
  final configDir = Directory('config');
  if (!await configDir.exists()) {
    await configDir.create();
  }
  
  await File('config/line_config.json').writeAsString(
    JsonEncoder.withIndent('  ').convert(testConfig),
  );
  print('✓ 测试配置已保存到 config/line_config.json');

  // 扫描测试目录
  final basePath = 'test_data/line_10.108.8.232/SaveImages/A-01-B';
  final date = '20260206';
  final shift = '白班';
  final timeSlots = [8, 9, 10, 14];
  final defectTypes = ['NG_脏污_B', 'NG_划伤_B', 'NG_断删_B'];

  print('\n=== 开始扫描测试目录 ===');
  print('基础路径: $basePath');
  print('日期: $date');
  print('班次: $shift');
  print('时间段: $timeSlots');
  print('脏污类型: $defectTypes');

  final List<String> foundImages = [];

  for (final timeSlot in timeSlots) {
    for (final defectType in defectTypes) {
      final scanPath = '$basePath/$date/$shift/$timeSlot/$defectType';
      
      print('\n扫描: $scanPath');
      
      final dir = Directory(scanPath);
      if (!await dir.exists()) {
        print('  ✗ 目录不存在 (剪枝)');
        continue;
      }

      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          final path = entity.path;
          if (path.endsWith('.png') || path.endsWith('.jpg')) {
            foundImages.add(path);
            print('  ✓ 发现图片: ${path.split('/').last}');
          }
        }
      }
    }
  }

  print('\n=== 扫描结果 ===');
  print('共找到 ${foundImages.length} 张图片');
  
  if (foundImages.isNotEmpty) {
    print('\n图片列表:');
    for (final img in foundImages) {
      print('  - $img');
    }

    // 测试复制到目标目录
    final targetDir = Directory('test_output');
    if (!await targetDir.exists()) {
      await targetDir.create();
    }

    print('\n=== 测试复制功能 ===');
    print('目标目录: ${targetDir.path}');

    for (final imgPath in foundImages) {
      final fileName = imgPath.split('/').last;
      final targetPath = '${targetDir.path}/$fileName';
      
      try {
        await File(imgPath).copy(targetPath);
        print('✓ 已复制: $fileName');
      } catch (e) {
        print('✗ 复制失败: $fileName - $e');
      }
    }

    print('\n✓ 测试完成！输出目录: ${targetDir.path}');
  } else {
    print('\n! 未找到任何图片，请检查测试目录结构');
  }
}
