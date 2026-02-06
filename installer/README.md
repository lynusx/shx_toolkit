# SHX Toolkit Windows 安装包构建指南

## 前置要求

1. **Windows 10/11** 操作系统
2. **Flutter SDK** 3.10.8 或更高版本
3. **Visual Studio 2022** (包含 C++ 桌面开发组件)
4. **Inno Setup 6** (可选，用于创建安装包)

## 安装 Inno Setup

下载地址: https://jrsoftware.org/isdl.php

安装后确保 `ISCC.exe` 在以下路径之一：
- `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`
- `C:\Program Files\Inno Setup 6\ISCC.exe`

## 构建步骤

### 方法一：使用批处理脚本（推荐）

1. 打开命令提示符，进入 `installer` 目录
2. 运行构建脚本：
```batch
cd installer
build_windows.bat
```

3. 等待构建完成，安装包将生成在 `build/installer/` 目录

### 方法二：手动构建

#### 1. 清理旧构建
```batch
flutter clean
```

#### 2. 获取依赖
```batch
flutter pub get
```

#### 3. 构建 Windows 版本
```batch
flutter build windows --release
```

构建输出位于：`build/windows/x64/runner/Release/`

#### 4. 创建安装包
使用 Inno Setup 编译 `windows_setup.iss` 脚本：
```batch
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows_setup.iss
```

安装包将生成在 `build/installer/` 目录

## 目录结构

```
installer/
├── build_windows.bat      # 自动构建脚本
├── windows_setup.iss      # Inno Setup 安装脚本
└── README.md              # 本说明文件
```

## 安装包特性

- ✅ 自动检测 64 位 Windows 系统
- ✅ 创建开始菜单快捷方式
- ✅ 可选创建桌面快捷方式
- ✅ 自动卸载程序
- ✅ 版本信息（文件属性中可查看）
- ✅ 中文/英文安装界面

## 版本更新

更新版本时需要修改：

1. `pubspec.yaml` 中的版本号
2. `installer/windows_setup.iss` 中的 `MyAppVersion`
3. `windows/runner/Runner.rc` 中的版本信息（可选）

## 分发说明

构建完成后，可分发以下文件：

| 文件 | 说明 |
|------|------|
| `SHX_Toolkit_Setup_v1.1.0.exe` | 安装包（推荐） |
| `build/windows/x64/runner/Release/` | 便携版文件夹 |

## 注意事项

1. **首次运行**需要管理员权限安装
2. **配置文件**存储在用户目录：`%AppData%\SHX Toolkit\config\`
3. **卸载时**配置文件夹可选择保留

## 常见问题

### Q: 构建失败，提示找不到 Visual Studio？
A: 确保安装了 Visual Studio 2022 的 "使用 C++ 的桌面开发" 工作负载

### Q: Inno Setup 未找到？
A: 安装后重启命令提示符，或检查安装路径是否正确

### Q: 安装包无法运行？
A: 确保目标系统已安装 Visual C++ Redistributable
