# GitHub Actions 工作流说明

## 工作流文件

### `build_windows.yml`

自动构建 Windows 版本并创建安装包。

## 触发方式

### 1. 自动触发（推送标签）

```bash
# 创建标签并推送
git tag v1.1.0
git push origin v1.1.0
```

推送标签后自动触发构建，并创建 GitHub Release。

### 2. 手动触发

在 GitHub 仓库页面：
1. 点击 **Actions** 标签
2. 选择 **Build Windows Installer**
3. 点击 **Run workflow**
4. 输入版本号（可选）
5. 点击 **Run workflow**

### 3. PR 触发

提交 Pull Request 到 `main` 或 `master` 分支时自动触发构建（仅构建，不发布）。

## 构建流程

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Checkout   │ -> │   Build     │ -> │   Create    │ -> │   Release   │
│    Code     │    │   Windows   │    │  Installer  │    │  (optional) │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       |                  |                  |                  |
       v                  v                  v                  v
   检出代码         编译 Flutter         Inno Setup         创建 Release
                   Windows 版本         打包安装包         上传安装包
```

## 输出产物

| 产物 | 说明 |
|------|------|
| `windows-release-{run_id}` | Windows 可执行文件目录 |
| `windows-installer-{run_id}` | Windows 安装包 (.exe) |

## 发布版本

### 自动发布

推送 `v*` 标签时自动创建 Release：

```bash
git tag v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0
```

### 手动下载

每次构建完成后，可以在 Actions 页面下载构建产物。

## 版本号规则

版本号优先级：
1. Git 标签（`v1.1.0` -> `1.1.0`）
2. 手动输入版本号
3. `pubspec.yaml` 中的版本号
4. 默认值 `1.0.0`

## 常见问题

### Q: 构建失败？

检查以下几点：
- `pubspec.yaml` 版本格式是否正确
- 代码分析是否通过 `flutter analyze`
- `installer/windows_setup.iss` 是否存在

### Q: 如何查看构建日志？

1. 进入 GitHub 仓库
2. 点击 **Actions** 标签
3. 点击失败的 workflow
4. 查看详细日志

### Q: 安装包在哪里下载？

- **Release 版本**: 在 GitHub Releases 页面下载
- **开发版本**: 在 Actions 页面的 Artifacts 中下载

## 配置 secrets

如果发布到其他平台（如第三方存储），需要配置 secrets：

1. 进入仓库 **Settings** -> **Secrets and variables** -> **Actions**
2. 点击 **New repository secret**
3. 添加所需的 secrets

## 参考文档

- [GitHub Actions 文档](https://docs.github.com/cn/actions)
- [Flutter 构建文档](https://docs.flutter.dev/deployment/windows)
- [Inno Setup 文档](https://jrsoftware.org/isinfo.php)
