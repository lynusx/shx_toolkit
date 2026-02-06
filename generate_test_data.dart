import 'dart:io';
import 'dart:math';

/// 生成大量测试数据用于性能测试
void main() async {
  print('=== 生成EL图片测试数据 ===\n');

  final random = Random();
  final defectTypes = ['NG_脏污_B', 'NG_划伤_B', 'NG_断删_B', 'NG_隐裂_A', 'NG_虚焊_A'];
  final timeSlots = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
  
  int totalFiles = 0;

  // 生成3个线别的数据
  for (int line = 1; line <= 3; line++) {
    final basePath = 'test_data/line_10.108.8.${230 + line}/SaveImages/A-01-B/20260206/白班';
    
    print('生成线别 $line 的数据...');
    
    for (final timeSlot in timeSlots) {
      // 每个时间段随机选择2-4种脏污类型
      final selectedDefects = defectTypes.where((_) => random.nextBool()).toList();
      if (selectedDefects.isEmpty) selectedDefects.add(defectTypes.first);
      
      for (final defectType in selectedDefects.take(random.nextInt(3) + 2)) {
        final dir = Directory('$basePath/$timeSlot/$defectType');
        await dir.create(recursive: true);
        
        // 每个目录生成1-5张图片
        final fileCount = random.nextInt(5) + 1;
        for (int i = 1; i <= fileCount; i++) {
          final file = File('${dir.path}/EL_${timeSlot}_${defectType}_${i.toString().padLeft(3, '0')}.png');
          await file.writeAsString('Test image content $i');
          totalFiles++;
        }
      }
    }
  }

  print('\n✓ 测试数据生成完成！');
  print('总图片数: $totalFiles');
  print('\n目录结构:');
  
  // 显示目录统计
  final result = await Process.run('find', ['test_data', '-type', 'f']);
  final files = (result.stdout as String).split('\n').where((f) => f.isNotEmpty).toList();
  print('  共 ${files.length} 个文件');
  
  // 显示前10个文件
  print('\n前10个文件:');
  for (final file in files.take(10)) {
    print('  $file');
  }
}
