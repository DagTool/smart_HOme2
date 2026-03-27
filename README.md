# SmartHome2

A Flutter-based smart home application built with Dart for controlling and managing IoT devices in your home.

## Features

- 🏠 **Device Control**: Manage multiple smart home devices from a single interface
- 📱 **Mobile-First Design**: Optimized for smartphones and tablets
- ⚡ **Real-Time Updates**: Live status monitoring of connected devices
- 🔐 **Secure Connection**: Safe communication with IoT devices
- 🎯 **User-Friendly UI**: Intuitive interface for easy device management

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **Platform**: iOS, Android

## Project Structure

```
smart_HOme2/
├── smart_home_app/          # Main Flutter application
├── README.md                # Project documentation
└── pubspec.yaml            # Flutter dependencies
```

## Getting Started

### Prerequisites

- Flutter SDK (version 3.0 or higher)
- Dart SDK
- iOS: Xcode (for macOS/iOS development)
- Android: Android Studio or Android SDK

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/DangDacTu/smart_HOme2.git
   cd smart_HOme2
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

Before running the app, ensure you have:
- Connected device or emulator running
- Required permissions configured in AndroidManifest.xml (for Android)
- Required permissions configured in Info.plist (for iOS)

## Usage

1. Launch the app on your device
2. Configure your smart home devices
3. Monitor and control devices from the main dashboard
4. Create custom automation rules (if available)

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### iOS App
```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Troubleshooting

### Common Issues

- **Flutter not found**: Make sure Flutter SDK is installed and added to PATH
- **Dependency errors**: Run `flutter pub get` or `flutter pub upgrade`
- **Build issues**: Clean and rebuild with `flutter clean && flutter pub get && flutter run`

## Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Format Code
```bash
dart format .
```

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For support, open an issue on the [GitHub Issues](https://github.com/DangDacTu/smart_HOme2/issues) page.

## Author

**DangDacTu**
- GitHub: [@DangDacTu](https://github.com/DangDacTu)

---

**Last Updated**: 2026-03-27 09:09:51