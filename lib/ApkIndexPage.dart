import 'dart:io';

import 'package:copyv2rayall/utils/Utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'WebDavClient.dart';

class ApkIndexPage extends StatefulWidget {
  const ApkIndexPage({super.key});

  @override
  State<ApkIndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<ApkIndexPage> {
  // 获取webDav客户端实例
  var client = WebDavClientService.getInstance().getClient();

  var path = "";

  var fileName = "v2rayN.txt";

  var v2rayFileName = "v2rayNAddress.txt";

  var clashFileName = "clashAddress.txt";

  final TextEditingController _v2rayController = TextEditingController();

  @override
  void initState() {
    Utils.getPathName().then((value) => {path = value});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Text("请点击下方按钮复制可用节点", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                client.read2File('/v2ray/$fileName', path + fileName,
                    onProgress: (c, t) {
                  Clipboard.setData(ClipboardData(
                      text: File(path + fileName).readAsStringSync()));
                  EasyLoading.showSuccess('可用节点已复制到剪切板');
                });
              },
              child: const Text('复制可用节点', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                readFileContent(v2rayFileName);
              },
              child: const Text('V2Ray订阅地址', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                readFileContent(clashFileName);
              },
              child: const Text('Clash订阅地址', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  readFileContent(String name) {
    client.read2File('/v2ray/$name', path + name, onProgress: (c, t) {
      _v2rayController.text = File(path + name).readAsStringSync();
    }).then((value) => _alertDialog());
  }

  // 展示V2ray的订阅地址
  _alertDialog() async {
    var result = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('可用订阅地址'),
            content: TextField(
                autofocus: true,
                textAlign: TextAlign.start,
                minLines: 5,
                maxLines: 20,
                keyboardType: TextInputType.multiline,
                controller: _v2rayController,
                onChanged: (v) {}),
            actions: <Widget>[
              TextButton(
                  child: const Text(
                    '取消',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.pop(context, "取消");
                  }),
              TextButton(
                child: const Text(
                  '全部复制',
                  style: TextStyle(color: Colors.blue),
                ),
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: _v2rayController.text.toString()));
                  EasyLoading.showSuccess('复制成功');
                },
              ),
            ],
          );
        });
  }
}
