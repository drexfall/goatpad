<div align="center">
  <a href="https://github.com/drexfall/goatpad">
    <img src="./goatpad-logo.png" alt="Logo" width="200" height="200">
  </a>

  <h1 align="center">GOATpad</h1>

  <p align="center">
    <strong>The Greatest Of All Text editors</strong>
   
  </p>
  <p> Presenting a is a simple, modern, cross-platform text editor built with Flutter, and a hell lot of coffee.</p>
  <br />
</div>



## Why GOATpad?

See, Microslop's Notepad sucks and Notepad++ also faced a recent vulnerability. But GOATpad shall never!

![img.png](img.png)

## Features

### Text Editing

- It writes
- ~~Stone~~, paper, scissors
- Multi-line support with auto-expanding text area along with intuitive cursor placement

### Sharing Capabilities

- Share text via standard share dialog (limit depends on platform)
- Generate and scan QR codes to share text easily (I don't know why you'd want to, but it was cool
  to implement)

### Customization

- 10 font families to choose from
- 5 font weights (Light, Normal, Medium, Semi-Bold, Bold)
- Adjustable font size (10-40pt)
- 5 theme presets:
    - Light: Clean white background with blue accents
    - Dark: True dark theme with blue accents
    - Nord: Popular Nordic color palette
    - Monokai: Classic dark code editor theme
    - Solarized: Easy on the eyes light theme
    - Custom: Create your own theme with custom colors

### Cross-Platform

- Android
- iOS
- Windows
- macOS
- Linux
- Web

## Installation

### Download Pre-built Releases

You can download the latest pre-built releases for your platform:

1. Visit the [Releases](https://github.com/drexfall/goatpad/releases) page
2. Download the appropriate file for your platform:
   - **Windows**: `goatpad-windows-x64.zip` - Extract and run `goatpad.exe`
   - **Linux**: `goatpad-linux-x64.tar.gz` - Extract and run the executable
   - **Android**: `app-release.apk` - Install on your device

### Build from Source

If you prefer to build from source, follow these steps:

#### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Willpower to download and run a text editor from GitHub

#### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/drexfall/goatpad.git
   cd goatpad
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

```bash
flutter run
```

### Building for Production

#### Android

```bash
flutter build apk
```

#### iOS

```bash
flutter build ios
```

#### Windows

```bash
flutter build windows
```

#### macOS

```bash
flutter build macos
```

#### Linux

```bash
flutter build linux
```

#### Web

```bash
flutter build web
```

## Usage

### Text Operations

- Write

### QR Code Features

- QR Code Generation: Tap the QR icon to generate a code from your text
- QR Code Scanning: Tap the scanner icon to open camera and scan codes

## Dependencies

- flutter: SDK
- google_fonts: Font customization
- qr_flutter: QR code generation
- mobile_scanner: QR code scanning
- share_plus: Cross-platform sharing
- loneliness: That's not something I can help you download though

## License

This project is licensed under the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License**.

You are free to:
* **Share** — copy and redistribute the material in any medium or format
* **Adapt** — remix, transform, and build upon the material

Under the following terms:
* **Attribution** — You must give appropriate credit to **drexfall** and **goatpad**, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
* **NonCommercial** — You may not use the material for commercial purposes.
* **ShareAlike** — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

For more details, see the [LICENSE](LICENSE) file.

## Support

For issues or feature requests, please create an issue in the repository. It's my first time, be
gentle please.
