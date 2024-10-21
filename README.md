# copyv2rayall

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 生成APK
flutter build apk --target-platform android-arm,android-arm64,android-x64 --split-per-abi

## 生成arm64APK 减少体积
flutter build apk --target-platform android-arm64 --split-per-abi   

## 生成windows
flutter build windows     