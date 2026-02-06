# SHX Toolkit Windows 版本构建指南

## 项目信息

- **应用名称**: SHX Toolkit
- **版本**: 1.1.0
- **应用描述**: 图片工具集 - 支持图片拷贝和离线EL图片收集

## Windows 版本特性

- ✅ 自定义标题栏（支持最大化/最小化/关闭）
- ✅ 窗口置顶功能
- ✅ 透明度调节
- ✅ 图片拷贝工具
- ✅ 离线EL图片收集（支持自定义脏污类型）
- ✅ 线别配置管理

## 系统要求

### 开发环境

- Windows 10 (版本 1903 或更高) / Windows 11
- Visual Studio 2022 (Community 版本即可)
  - 必需组件: "使用 C++ 的桌面开发"
- Flutter SDK 3.10.8+
- Dart SDK 3.0+

### 运行时环境

- Windows 10 (版本 1803 或更高) / Windows 11
- 64 位系统
- 可选: Visual C++ Redistributable 2022

## 构建步骤

### 1. 克隆项目

```bash
git clone <项目地址>
cd shx_toolkit
```

### 2. 配置 Windows 支持

```bash
flutter config --enable-windows-desktop
```

### 3. 获取依赖

```bash
flutter pub get
```

### 4. 构建 Windows 版本

#### 开发版本（调试）
```bash
flutter run -d windows
```

#### 发布版本
```bash
flutter build windows --release
```

构建输出位置：`build/windows/x64/runner/Release/`

## 创建安装包

### 方法：使用 Inno Setup

#### 1. 安装 Inno Setup

下载地址：https://jrsoftware.org/isdl.php

#### 2. 运行构建脚本

```batch
cd installer
build_windows.bat
```

#### 3. 输出文件

安装包生成位置：`build/installer/SHX_Toolkit_Setup_v1.1.0.exe`

## 目录结构

```
shx_toolkit/
├── lib/                      # Flutter 源代码
│   ├── core/                 # 核心功能
│   ├── models/               # 数据模型
│   ├── viewmodels/           # 业务逻辑
│   ├── views/                # 页面UI
│   └── main.dart             # 入口文件
├── windows/                  # Windows 平台配置
│   └── runner/
│       ├── Runner.rc         # 资源文件（应用信息）
│       └── main.cpp          # 程序入口
├── installer/                # 安装包配置
│   ├── build_windows.bat     # 自动构建脚本
│   ├── windows_setup.iss     # Inno Setup 脚本
│   └── README.md             # 安装包说明
├── config/                   # 运行时配置文件
│   ├── line_config.json      # 线别配置
│   └── defect_types.json     # 脏污类型配置
└── pubspec.yaml              # 项目配置
```

## 版本更新清单

更新 Windows 版本时需要修改：

1. **pubspec.yaml**
   ```yaml
   version: 1.1.0+2
   ```

2. **installer/windows_setup.iss**
   ```pascal
   #define MyAppVersion "1.1.0"
   ```

3. **windows/runner/Runner.rc**（可选）
   - 文件属性中的版本信息

## 常见问题

### Q1: 构建失败，提示 "Visual Studio not installed"

**解决**: 安装 Visual Studio 2022，确保选择 "使用 C++ 的桌面开发" 工作负载

### Q2: 应用图标不显示

**解决**: 需要创建 `assets/app_icon.ico` 文件（256x256 像素）

### Q3: 安装包被杀毒软件拦截

**解决**: 
- 为安装包添加数字签名（推荐）
- 或提示用户添加到白名单

### Q4: 运行时缺少 DLL

**解决**: 安装 Visual C++ Redistributable 2022

## 配置文件说明

Windows 版本的配置文件存储在：
```
%AppData%\SHX Toolkit\config\
├── line_config.json      # 线别配置
└── defect_types.json     # 脏污类型配置
```

卸载时可以选择保留或删除配置文件夹。

## 分发方式

| 方式 | 优点 | 缺点 |
|------|------|------|
| 安装包 (.exe) | 用户友好，自动创建快捷方式 | 需要管理员权限 |
| ZIP 压缩包 | 便携，无需安装 | 需要手动创建快捷方式 |

推荐使用安装包方式分发。

## 技术支持

如有问题，请联系开发团队。
