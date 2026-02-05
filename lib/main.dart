import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/window_service.dart';

/// 应用程序入口
///
/// 1. 初始化 Flutter binding
/// 2. 初始化窗口管理器
/// 3. 运行应用
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理器
  await WindowService().initialize();

  runApp(const ShxToolkitApp());
}
