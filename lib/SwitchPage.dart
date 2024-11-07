import 'package:copyv2rayall/ApkIndexPage.dart';
import 'package:copyv2rayall/WinIndexPage.dart';
import 'package:flutter/material.dart';

import 'WebDavClient.dart';

class SwitchPage extends StatefulWidget {
  const SwitchPage({super.key});

  @override
  State<SwitchPage> createState() => _SwitchPageState();
}

class _SwitchPageState extends State<SwitchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List tabs = ["上传", "拷贝"];
  List ta = [const WinIndexPage(), const ApkIndexPage()];

  // List ta = [ApkIndexPage(), ApkIndexPage()];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("配置可用订阅/节点"),
          bottom: TabBar(
            tabs: tabs
                .map((e) => Tab(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  e,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ))
                .toList(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _showSettingsDialog(context);
              },
            ),
          ],
        ),
        body: TabBarView(
          //构建
          children: ta.map((e) {
            return Container(alignment: Alignment.center, child: e);
          }).toList(),
        ),
      ),
    );
  }

  bool _isPasswordVisible = false;

  void _showSettingsDialog(BuildContext context) {
    TextEditingController usernameController =
    TextEditingController(text: GlobalConfig.username);
    TextEditingController passwordController =
    TextEditingController(text: GlobalConfig.password);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Login Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Update global configuration
                  GlobalConfig.username = usernameController.text;
                  GlobalConfig.password = passwordController.text;
                  await GlobalConfig.saveCredentials();
                  // Reinitialize the client with new credentials
                  WebDavClientService.resetInstance();
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  void dispose() {
    // 释放资源
    _tabController.dispose();
    super.dispose();
  }
}
