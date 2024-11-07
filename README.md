# copyv2rayall

一个可以在任何设备运行的软件，无需服务器。使用webdav。在线copy。
主要是v2ray。clash订阅链接。来回复制不方便，使用此app。丝滑同步！！！


目前我自己用的是坚果云服务，免费的够用！

#### 计划 

- [x] 动态设置webdav账号密码和地址。
- [x] 添加导入功能
- [ ] 优化ui
- [ ] 待定。。。

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