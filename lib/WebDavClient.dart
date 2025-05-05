import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart';

class GlobalConfig {
  static String username = '';
  static String password = '';

  static Future<void> saveCredentials(String userName, String passWord) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', userName);
    await prefs.setString('password', passWord);
    GlobalConfig.username = userName;
    GlobalConfig.password = passWord;
  }

  static Future<void> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('username') && prefs.containsKey('password')) {
      username = prefs.getString('username') ?? '';
      password = prefs.getString('password') ?? '';
    } else {
      EasyLoading.showError('账号或者密码为空！');
    }
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
    // 重新执行构造client 的方法 重新初始化
    _instance = WebDavClientService._();
    _instance!._initializeClient();
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
    try {
      // 尝试访问 _client。如果未初始化，会抛出 LateInitializationError。
      return _client;
    } catch (e) {
      // 捕获到错误，说明 _client 可能由于某种原因未被初始化。
      print("警告: WebDAV 客户端在 getClient() 中访问时未初始化，尝试重新初始化。错误: $e");
      // 这种情况通常表明 getInstance() 或 resetInstance() 的调用流程有问题。
      // 尝试在这里进行补救式初始化：
      _initializeClient();
      // 再次返回 _client。如果 _initializeClient() 内部失败，这里可能会再次抛出错误。
      return _client;
    }
  }
}
