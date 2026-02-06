import 'dart:io';
import 'package:flutter/material.dart';

/// 窗口标题栏
///
/// 自定义的窗口标题栏，包含:
/// - 标题和图标
/// - 拖拽区域
/// - 窗口控制按钮（最小化、最大化、关闭）
///
/// 注意: macOS 上会自动预留红绿灯按钮空间
class WindowTitleBar extends StatelessWidget {
  final String title;
  final bool isMaximized;
  final bool isAlwaysOnTop;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onClose;
  final VoidCallback onStartDrag;
  final VoidCallback? onToggleAlwaysOnTop;

  const WindowTitleBar({
    super.key,
    required this.title,
    required this.isMaximized,
    required this.isAlwaysOnTop,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
    required this.onStartDrag,
    this.onToggleAlwaysOnTop,
  });

  /// 是否为 macOS 平台
  bool get _isMacOS => Platform.isMacOS;

  /// macOS 红绿灯按钮区域宽度
  static const double _macOSButtonAreaWidth = 80;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withAlpha(25)),
        ),
      ),
      child: Row(
        children: [
          // macOS: 预留红绿灯按钮空间
          if (_isMacOS) const SizedBox(width: _macOSButtonAreaWidth),

          // 拖拽区域（左侧）
          Expanded(
            child: GestureDetector(
              onPanStart: (_) => onStartDrag(),
              onDoubleTap: _isMacOS ? null : onMaximize, // macOS 双击由系统处理
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: _isMacOS ? 12 : 16),
                child: Row(
                  children: [
                    // 非 macOS 显示应用图标
                    if (!_isMacOS) ...[
                      Icon(Icons.apps, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 10),
                    ],
                    // 标题
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // 置顶指示器（非 macOS 显示在标题区域）
                    if (!_isMacOS && isAlwaysOnTop)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.push_pin,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 窗口控制按钮（右侧）
          // macOS: 隐藏默认控制按钮，只显示置顶按钮
          // Windows/Linux: 显示完整控制按钮
          _WindowControlButtons(
            isMaximized: isMaximized,
            isAlwaysOnTop: isAlwaysOnTop,
            onMinimize: onMinimize,
            onMaximize: onMaximize,
            onClose: onClose,
            onToggleAlwaysOnTop: onToggleAlwaysOnTop,
            isMacOS: _isMacOS,
          ),
        ],
      ),
    );
  }
}

/// 窗口控制按钮组
class _WindowControlButtons extends StatelessWidget {
  final bool isMaximized;
  final bool isAlwaysOnTop;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onClose;
  final VoidCallback? onToggleAlwaysOnTop;
  final bool isMacOS;

  const _WindowControlButtons({
    required this.isMaximized,
    required this.isAlwaysOnTop,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
    this.onToggleAlwaysOnTop,
    required this.isMacOS,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // macOS: 只显示置顶按钮（系统自带关闭/最小化/最大化按钮）
    if (isMacOS) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 置顶按钮
          _WindowButton(
            icon: isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
            tooltip: isAlwaysOnTop ? '取消置顶' : '置顶窗口',
            onPressed: onToggleAlwaysOnTop,
            iconSize: 16,
            iconColor: isAlwaysOnTop ? colorScheme.primary : null,
          ),
          const SizedBox(width: 8), // 右侧留一点间距
        ],
      );
    }

    // Windows/Linux: 显示完整控制按钮
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 置顶按钮
        _WindowButton(
          icon: isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
          tooltip: isAlwaysOnTop ? '取消置顶' : '置顶窗口',
          onPressed: onToggleAlwaysOnTop,
          iconSize: 16,
          iconColor: isAlwaysOnTop ? colorScheme.primary : null,
        ),
        // 最小化
        _WindowButton(
          icon: Icons.remove,
          tooltip: '最小化',
          onPressed: onMinimize,
        ),
        // 最大化/恢复
        _WindowButton(
          icon: isMaximized ? Icons.filter_none : Icons.crop_square,
          tooltip: isMaximized ? '恢复' : '最大化',
          onPressed: onMaximize,
          iconSize: isMaximized ? 14 : 18,
        ),
        // 关闭
        _WindowButton(
          icon: Icons.close,
          tooltip: '关闭',
          onPressed: onClose,
          hoverColor: Colors.red,
          iconColor: colorScheme.onSurface,
          hoverIconColor: Colors.white,
        ),
      ],
    );
  }
}

/// 单个窗口控制按钮
class _WindowButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color? hoverColor;
  final Color? iconColor;
  final Color? hoverIconColor;

  const _WindowButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.iconSize = 18,
    this.hoverColor,
    this.iconColor,
    this.hoverIconColor,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = widget.hoverColor ?? colorScheme.onSurface.withAlpha(25);
    final defaultIconColor = widget.iconColor ?? colorScheme.onSurface;
    final activeIconColor = widget.hoverIconColor ?? defaultIconColor;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 46,
            height: 40,
            decoration: BoxDecoration(
              color: _isHovered ? bgColor : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: _isHovered ? activeIconColor : defaultIconColor,
            ),
          ),
        ),
      ),
    );
  }
}
