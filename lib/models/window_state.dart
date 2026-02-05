import 'package:flutter/material.dart' show Size, Offset;

/// 窗口状态模型
class WindowState {
  final bool isMaximized;
  final bool isMinimized;
  final bool isFullScreen;
  final bool isAlwaysOnTop;
  final double opacity;
  final Size windowSize;
  final Offset windowPosition;

  const WindowState({
    this.isMaximized = false,
    this.isMinimized = false,
    this.isFullScreen = false,
    this.isAlwaysOnTop = false,
    this.opacity = 1.0,
    this.windowSize = const Size(1280, 800),
    this.windowPosition = const Offset(100, 100),
  });

  WindowState copyWith({
    bool? isMaximized,
    bool? isMinimized,
    bool? isFullScreen,
    bool? isAlwaysOnTop,
    double? opacity,
    Size? windowSize,
    Offset? windowPosition,
  }) {
    return WindowState(
      isMaximized: isMaximized ?? this.isMaximized,
      isMinimized: isMinimized ?? this.isMinimized,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isAlwaysOnTop: isAlwaysOnTop ?? this.isAlwaysOnTop,
      opacity: opacity ?? this.opacity,
      windowSize: windowSize ?? this.windowSize,
      windowPosition: windowPosition ?? this.windowPosition,
    );
  }

  @override
  String toString() {
    return 'WindowState(isMaximized: $isMaximized, isMinimized: $isMinimized, '
        'isFullScreen: $isFullScreen, isAlwaysOnTop: $isAlwaysOnTop, '
        'opacity: $opacity, windowSize: $windowSize, windowPosition: $windowPosition)';
  }
}
