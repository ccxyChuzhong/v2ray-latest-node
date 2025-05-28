# V2Ray Latest Node

一个跨平台的v2ray节点管理工具，支持通过WebDAV服务在多设备间同步v2ray节点信息和clash订阅链接。

浏览器插件版本：https://github.com/ccxyChuzhong/kaidao-browser-plugin

## ✨ 功能特点

- 🌐 **跨平台支持** - 支持Android、iOS、Windows、Linux、Web等多个平台
- ☁️ **云端同步** - 基于WebDAV协议，支持坚果云等云存储服务
- 📱 **无需服务器** - 完全依赖WebDAV，无需额外服务器部署
- 🔄 **实时同步** - 在线复制，多设备间丝滑同步节点信息
- 📋 **订阅管理** - 支持v2ray节点和clash订阅链接的统一管理
- 🎯 **简单易用** - 界面简洁，操作便捷

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.5.4
- Dart SDK >= 3.5.4
- 各平台对应的开发环境（Android Studio、Xcode等）

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/ccxyChuzhong/v2ray-latest-node.git
   cd v2ray-latest-node
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **配置WebDAV**
   - 首次运行时需要设置WebDAV账号和密码
   - 推荐使用坚果云服务（免费版本够用）

## 📦 构建应用

### Android APK
```bash
# 构建多架构APK
flutter build apk --target-platform android-arm,android-arm64,android-x64 --split-per-abi

# 构建ARM64 APK（减少体积）
flutter build apk --target-platform android-arm64 --split-per-abi
```

### Windows
```bash
flutter build windows
```

### Linux
```bash
flutter build linux
```

### iOS
```bash
flutter build ios
```

### Web
```bash
flutter build web
```

## 🔧 配置说明

### WebDAV设置

应用支持动态配置WebDAV服务：
- **服务器地址**: 默认支持坚果云WebDAV地址
- **用户名**: 您的WebDAV账号用户名
- **密码**: 您的WebDAV账号密码或应用专用密码

### 数据存储

- 节点信息存储在WebDAV的 `webdav-subscribe/node-info.txt` 文件中
- 支持导入和导出功能
- 自动统计节点数量

## 📁 项目结构

```
lib/
├── main.dart              # 应用入口
├── WinIndexPage.dart      # 主界面
├── SwitchPage.dart        # 页面切换
├── WebDavClient.dart      # WebDAV客户端服务
└── utils/
    └── Utils.dart         # 工具类

android/                  # Android平台代码
ios/                      # iOS平台代码
windows/                  # Windows平台代码
linux/                    # Linux平台代码
web/                      # Web平台代码
```

## 🛠️ 技术栈

- **前端框架**: Flutter
- **状态管理**: StatefulWidget
- **网络请求**: webdav_client
- **本地存储**: shared_preferences
- **UI组件**: Material Design 3
- **加载提示**: flutter_easyloading

## 📋 TODO列表

- [x] 动态设置WebDAV账号密码和地址
- [x] 添加导入功能
- [ ] 优化UI界面
- [ ] 添加更多云存储服务支持
- [ ] 节点延迟测试功能
- [ ] 批量导入/导出

## 🤝 贡献指南

1. Fork 本项目
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📝 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 📞 联系方式

如果您有任何问题或建议，请通过以下方式联系：

- 提交 [Issue](https://github.com/ccxyChuzhong/v2ray-latest-node/issues)
- 发起 [Discussion](https://github.com/ccxyChuzhong/v2ray-latest-node/discussions)

## ⭐ Star History

如果这个项目对您有帮助，请给我们一个 Star ⭐️

---

**注意**: 本应用仅供学习和技术交流使用，请遵守当地法律法规。
