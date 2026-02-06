import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../views/home_view.dart';
import '../../views/settings_page.dart';
import '../../views/tools/image_copy_page.dart' as tools;
import '../../views/tools/el_collection_page.dart' as el;

/// 应用路由配置
///
/// 使用 go_router 管理应用路由，侧边栏导航通过路由驱动：
/// - /                   离线EL收集（默认）
/// - /settings           设置页面
/// - /tools/image-copy   图片拷贝工具（独立页面）
/// - /tools/el-collection EL收集工具（独立页面）
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// 路由配置
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // ShellRoute: 包含侧边栏的页面布局
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeView(child: child),
        routes: [
          // 离线EL收集（首页）
          GoRoute(
            path: '/',
            builder: (context, state) => const el.ELCollectionPageContent(),
          ),
          // 设置页面
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      // 独立页面（不含侧边栏）
      GoRoute(
        path: '/tools/image-copy',
        builder: (context, state) => const tools.ImageCopyPage(),
      ),
      GoRoute(
        path: '/tools/el-collection',
        builder: (context, state) => const el.ELCollectionPage(),
      ),
    ],
  );

  // 路由路径常量
  static const String home = '/';
  static const String settings = '/settings';
  static const String imageCopy = '/tools/image-copy';
  static const String elCollection = '/tools/el-collection';

  /// 根据路由路径获取导航索引
  static int getIndexFromPath(String path) {
    switch (path) {
      case '/':
        return 0;
      case '/settings':
        return 1;
      default:
        return 0;
    }
  }

  /// 根据导航索引获取路由路径
  static String getPathFromIndex(int index) {
    switch (index) {
      case 0:
        return '/';
      case 1:
        return '/settings';
      default:
        return '/';
    }
  }
}
