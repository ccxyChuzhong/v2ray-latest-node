import 'dart:io';

import 'package:v2ray_latest_node/ApkIndexPage.dart';
import 'package:v2ray_latest_node/utils/Utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'WebDavClient.dart';

class WinIndexPage extends StatefulWidget {
  const WinIndexPage({super.key});

  @override
  State<WinIndexPage> createState() => _WinIndexPageState();
}

class _WinIndexPageState extends State<WinIndexPage> {
  // 获取webDav客户端实例
  var client = WebDavClientService.getInstance().getClient();

  var path = "";

  var fileName = "v2rayN.txt";

  var v2rayFileName = "v2rayNAddress.txt";

  var clashFileName = "clashAddress.txt";

  final TextEditingController _unameController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
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
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 300.0, // Set the maximum height for the TextField
              ),
              child: SingleChildScrollView(
                child: TextField(
                  autofocus: true,
                  textAlign: TextAlign.start,
                  minLines: 5,
                  maxLines: 10,
                  // Allow the TextField to expand
                  keyboardType: TextInputType.multiline,
                  controller: _unameController,
                  onChanged: (v) {},
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                writeToFile(fileName);
              },
              child: const Text('上传节点信息', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                writeToFile(v2rayFileName);
              },
              child: const Text('上传V2ray订阅地址', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                writeToFile(clashFileName);
              },
              child: const Text('上传clash订阅地址', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  writeToFile(String name) async {
    // 判断_unameController.text是否为空
    if (_unameController.text.isEmpty) {
      EasyLoading.showError('内容不能为空');
      return;
    }
    //将数据信息写入到本地文件中
    File file = File(path + name);
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync();
    file.writeAsString(_unameController.text).then((value) => {
          client
              .writeFromFile(path + name, '/v2ray/$name')
              .then((value) => {EasyLoading.showSuccess('上传成功')})
        });
  }
}
