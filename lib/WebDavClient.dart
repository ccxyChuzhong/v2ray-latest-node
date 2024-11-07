import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart';

class GlobalConfig {
  static String username = '';
  static String password = '';

  static Future<void> saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
  }

  static Future<void> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    password = prefs.getString('password') ?? '';
  }
}

class WebDavClientService {
  static WebDavClientService? _instance;
  late Client _client;

  // 私有构造函数
  WebDavClientService._();

  // 获取单例实例
  static WebDavClientService getInstance() {
    if (_instance == null) {
      _instance = WebDavClientService._();
      _instance!._initializeClient();
    }
    return _instance!;
  }

  static void resetInstance() {
    _instance = null;
    getInstance();
  }

  // 构造函数
  void _initializeClient() {
    _client = newClient(
      'https://dav.jianguoyun.com/dav/',
      user: GlobalConfig.username,
      password: GlobalConfig.password,
    );

    // 设置默认的请求头
    _client.setHeaders({
      'accept-charset': 'utf-8',
      'content-type': 'multipart/form-data',
    });

    // 设置连接超时时间
    _client.setConnectTimeout(8000);
    // 设置发送数据超时时间
    _client.setSendTimeout(8000);
    // 设置接收数据超时时间
    _client.setReceiveTimeout(8000);

    _client.ping();
  }

  // 获取当前的 WebDav 客户端实例
  Client getClient() {
    return _client;
  }
}
