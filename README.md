# SHX Toolkit

A Flutter desktop application toolkit for Windows/macOS with MVVM architecture.

## Features

- **Image Copy Tool**: Batch copy images with recursive directory scanning
- **EL Image Collection**: Manage EL (Electroluminescence) images for solar panel inspection
- **Window Management**: Custom title bar with transparency control and macOS traffic light fix
- **Navigation**: Sidebar navigation using go_router with ShellRoute

## Development

### Prerequisites

- Flutter 3.10.8 (stable channel)
- Dart 3.10.8
- Visual Studio 2022 with C++ desktop development (Windows)
- Inno Setup 6 (Windows installer)

### Getting Started

```bash
# Clone the repository
git clone <repo-url>
cd shx_toolkit

# Install dependencies
flutter pub get

# Run on macOS
flutter run -d macos

# Run on Windows
flutter run -d windows
```

### Project Structure

```
lib/
├── core/
│   ├── router/          # go_router configuration
│   ├── services/        # Business logic services
│   └── utils/           # Utilities and constants
├── models/              # Data models
├── viewmodels/          # MVVM ViewModels
├── views/               # UI screens and widgets
└── main.dart           # App entry point

config/
├── line_config.json    # Line configuration for EL collection
└── defect_types.json   # Custom defect types

installer/
└── windows_setup.iss   # Inno Setup installer script

.github/
└── workflows/
    ├── ci.yml          # Code analysis and tests
    └── build_windows.yml # Windows build and release
```

## Building

### Windows

```bash
# Build release version
flutter build windows --release

# Create installer (requires Inno Setup)
# Installer will be created at: build/SHX_Toolkit_Setup.exe
```

### macOS

```bash
# Build release version
flutter build macos --release

# Create DMG (requires create-dmg)
# See: https://github.com/create-dmg/create-dmg
```

## Automated Builds (GitHub Actions)

This project uses GitHub Actions for automated builds and releases.

### Triggering a Build

**Method 1: Push a tag**
```bash
git tag v1.1.0
git push origin v1.1.0
```

**Method 2: Manual trigger**
1. Go to **Actions** tab in GitHub
2. Select **Build Windows Installer**
3. Click **Run workflow**
4. Enter version number (optional)

### CI Workflow

Every push to main/master triggers:
- Code analysis (`flutter analyze`)
- Code formatting check (`dart format`)
- Tests (`flutter test`)

See [.github/workflows/README.md](.github/workflows/README.md) for detailed documentation.

## Configuration

### Line Configuration

Edit `config/line_config.json` to configure line IPs for EL image collection:

```json
{
  "东区": {
    "1A": "\\\\10.108.8.232",
    "1B": "\\\\10.108.8.233"
  }
}
```

### Defect Types

Default defect types can be customized via the Settings page. Configuration is stored in `config/defect_types.json`.

## License

MIT License

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Desktop Development](https://docs.flutter.dev/desktop)
- [GitHub Actions Documentation](https://docs.github.com/cn/actions)
