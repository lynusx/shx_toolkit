#!/bin/bash

# SHX Toolkit Windows ZIP 打包脚本 (macOS/Linux)
# 用于在非 Windows 环境下准备 Windows 构建文件

echo "==================================="
echo "SHX Toolkit Windows 版本准备脚本"
echo "==================================="
echo ""

# 检查 Flutter
echo "[1/4] 检查 Flutter 环境..."
if ! command -v flutter &> /dev/null; then
    echo "错误: 未找到 Flutter"
    exit 1
fi
echo "Flutter 版本:"
flutter --version
echo ""

# 获取依赖
echo "[2/4] 获取依赖包..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "错误: 获取依赖失败"
    exit 1
fi
echo ""

# 分析项目
echo "[3/4] 分析项目..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "警告: 项目分析发现警告或错误"
fi
echo ""

# 创建输出目录
echo "[4/4] 准备 Windows 构建文件..."
OUTPUT_DIR="build/windows_output"
mkdir -p "$OUTPUT_DIR"

# 复制 Windows 配置文件
cp -r windows "$OUTPUT_DIR/"
cp pubspec.yaml "$OUTPUT_DIR/"

echo ""
echo "==================================="
echo "Windows 构建准备完成！"
echo "==================================="
echo ""
echo "请在 Windows 环境下执行以下操作："
echo "1. 复制整个项目到 Windows 电脑"
echo "2. 确保已安装 Flutter 和 Visual Studio 2022"
echo "3. 运行: flutter build windows --release"
echo "4. 或使用: installer/build_windows.bat"
echo ""
echo "Windows 配置文件已准备就绪："
echo "  - windows/runner/Runner.rc (应用信息)"
echo "  - windows/runner/main.cpp (窗口标题)"
echo "  - installer/windows_setup.iss (安装脚本)"
