import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';

/// 应用程序根组件
/// 
/// 配置应用的主题和路由（使用 go_router）
class ShxToolkitApp extends StatelessWidget {
  const ShxToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }

  /// 构建浅色主题
  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withAlpha(50),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withAlpha(25),
      ),
    );
  }

  /// 构建深色主题
  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withAlpha(50),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withAlpha(25),
      ),
    );
  }
}
