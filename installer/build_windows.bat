@echo off
chcp 65001
echo ===================================
echo SHX Toolkit Windows 版本构建脚本
echo ===================================
echo.

:: 检查 Flutter 环境
echo [1/5] 检查 Flutter 环境...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到 Flutter，请确保 Flutter 已安装并添加到 PATH
    exit /b 1
)
echo Flutter 环境检查通过
echo.

:: 清理旧构建
echo [2/5] 清理旧构建文件...
flutter clean
if errorlevel 1 (
    echo 警告: 清理失败，继续构建...
)
echo.

:: 获取依赖
echo [3/5] 获取依赖包...
flutter pub get
if errorlevel 1 (
    echo 错误: 获取依赖失败
    exit /b 1
)
echo.

:: 构建 Windows 版本
echo [4/5] 构建 Windows 版本...
flutter build windows --release
if errorlevel 1 (
    echo 错误: 构建失败
    exit /b 1
)
echo Windows 版本构建成功
echo.

:: 检查 Inno Setup
echo [5/5] 检查 Inno Setup...
set ISCC="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if not exist %ISCC% (
    set ISCC="C:\Program Files\Inno Setup 6\ISCC.exe"
)

if exist %ISCC% (
    echo 找到 Inno Setup，开始创建安装包...
    %ISCC% windows_setup.iss
    if errorlevel 1 (
        echo 警告: 创建安装包失败
    ) else (
        echo 安装包创建成功！
        echo 输出位置: ..\build\installer\
    )
) else (
    echo 警告: 未找到 Inno Setup，跳过安装包创建
    echo 请手动下载安装: https://jrsoftware.org/isdl.php
    echo 构建的 Windows 版本位于: ..\build\windows\x64\runner\Release\
)

echo.
echo ===================================
echo 构建完成！
echo ===================================
pause
