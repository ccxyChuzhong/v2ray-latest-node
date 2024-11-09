import 'dart:io';

import 'package:v2ray_latest_node/utils/Utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:url_launcher/url_launcher.dart';

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
              child: const Text('复制节点', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                readFileContent(v2rayFileName);
              },
              child: const Text('V2Ray地址', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    readFileContent(clashFileName);
                  },
                  child:
                      const Text('复制Clash地址', style: TextStyle(fontSize: 20)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    importContentToClash(clashFileName);
                  },
                  child:
                      const Text('导入Clash地址', style: TextStyle(fontSize: 20)),
                ),
              ],
            )
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

  void importContentToClash(String name) async {
    client.read2File('/v2ray/$name', path + name, onProgress: (c, t) {
      _v2rayController.text = File(path + name).readAsStringSync();
    }).then((value) => _alertClashDialog(_v2rayController.text));
  }

  void _alertClashDialog(String value) async {
    List<String> urls = value.split('\n');
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('导入Clash订阅地址'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(urls.length, (index) {
                Uri uri = Uri.parse(urls[index]);
                String domain = uri.host;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      EasyLoading.showSuccess('正在导入。。。。。');
                      var uri = Uri.parse('clash://install-config?url=${urls[index]}&name=$domain');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,mode: LaunchMode.externalApplication);
                      } else {
                        throw 'Could not launch ${urls[index]}';
                      }
                    },
                    child: Text(domain),
                  ),
                );
              }),
            ),
          );
        });
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
