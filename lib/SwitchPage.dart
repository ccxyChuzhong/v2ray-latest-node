import 'package:v2ray_latest_node/WinIndexPage.dart';
import 'package:flutter/material.dart';

import 'SubscriptionPage.dart';
import 'WebDavClient.dart';

class SwitchPage extends StatefulWidget {
  const SwitchPage({super.key});

  @override
  State<SwitchPage> createState() => _SwitchPageState();
}

class _SwitchPageState extends State<SwitchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List tabs = ["订阅管理","节点管理"];
  List ta = [const SubscriptionPage(),const WinIndexPage()];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  Widget _buildSideMenuItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        hoverColor: Colors.white.withOpacity(0.08),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 统一去除侧边栏和抽屉，所有平台都只用顶部TabBar
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
                  enableInteractiveSelection: true,
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
                  enableInteractiveSelection: true,
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
                  await GlobalConfig.saveCredentials(usernameController.text, passwordController.text);
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
