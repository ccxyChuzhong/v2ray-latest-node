import 'package:copyv2rayall/ApkIndexPage.dart';
import 'package:copyv2rayall/WinIndexPage.dart';
import 'package:flutter/material.dart';

class SwitchPage extends StatefulWidget {
  const SwitchPage({super.key});

  @override
  State<SwitchPage> createState() => _SwitchPageState();
}

class _SwitchPageState extends State<SwitchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List tabs = ["上传", "copy"];
  List ta = [WinIndexPage(), ApkIndexPage()];

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
          title: const Text("配置可用V2ray"),
          bottom: TabBar(
            tabs: tabs.map((e) => Tab(text: e)).toList(),
          ),
        ),
        body: TabBarView(
          //构建
          children: ta.map((e) {
            return Container(
              child: Container(alignment: Alignment.center, child: e),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 释放资源
    _tabController.dispose();
    super.dispose();
  }
}
