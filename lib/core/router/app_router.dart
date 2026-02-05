import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../views/home_view.dart';
import '../../views/tools/image_copy_page.dart';

/// 应用路由配置
/// 
/// 使用 go_router 管理应用路由：
/// - /                  主页
/// - /tools/image-copy  图片拷贝工具
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  /// 路由配置
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // 主页
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeView(),
      ),
      // 图片拷贝工具
      GoRoute(
        path: '/tools/image-copy',
        builder: (context, state) => const ImageCopyPage(),
      ),
    ],
  );

  // 路由路径常量
  static const String home = '/';
  static const String imageCopy = '/tools/image-copy';
}
