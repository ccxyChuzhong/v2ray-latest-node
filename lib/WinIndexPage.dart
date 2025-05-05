import 'dart:io';

import 'package:v2ray_latest_node/utils/Utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

import 'WebDavClient.dart';

class WinIndexPage extends StatefulWidget {
  const WinIndexPage({super.key});

  @override
  State<WinIndexPage> createState() => _WinIndexPageState();
}

class _WinIndexPageState extends State<WinIndexPage> {
  // 获取webDav客户端实例
  var client = WebDavClientService.getInstance().getClient();

  var webdavPath = "webdav-subscribe";

  var subscribeFileName = "node-info.txt";

  final TextEditingController _unameController = TextEditingController();

  final TextEditingController _v2rayController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "上传节点信息",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "请在下方输入节点内容",
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 220.0,
                          ),
                          child: TextField(
                            autofocus: true,
                            textAlign: TextAlign.start,
                            minLines: 5,
                            maxLines: 10,
                            keyboardType: TextInputType.multiline,
                            controller: _unameController,
                            decoration: const InputDecoration(
                              hintText: '请输入节点内容',
                              filled: true,
                              fillColor: Color(0xFFF8F9FB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                            onChanged: (v) {},
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.cloud_upload),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.blueAccent,
                            ),
                            onPressed: () async {
                              await writeToFile('');
                            },
                            label: const Text('上传节点信息', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 新增底部节点统计和操作卡片
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: NodeSummaryCard(
                    client: client,
                    webdavPath: webdavPath,
                    subscribeFileName: subscribeFileName,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

writeToFile(String name) async {
  if (_unameController.text.isEmpty) {
    EasyLoading.showError('内容不能为空');
    return;
  }
  String remotePath = '$webdavPath/$subscribeFileName';
  String oldContent = '';
  try {
    final bytes = await client.read(remotePath);
    oldContent = String.fromCharCodes(bytes);
  } catch (e) {
    // ignore
  }
  // 追加内容
  String newContent = oldContent.isEmpty
      ? _unameController.text
      : (oldContent.trim() + '\n' + _unameController.text);
  Uint8List finalData = Uint8List.fromList(utf8.encode(newContent));
  await client.write(remotePath, finalData);
  EasyLoading.showSuccess('上传成功');
  _unameController.clear();
  setState(() {}); // 触发页面刷新（如节点统计）
}

}

class NodeSummaryCard extends StatefulWidget {
  final dynamic client;
  final String webdavPath;
  final String subscribeFileName;
  const NodeSummaryCard({Key? key, required this.client, required this.webdavPath, required this.subscribeFileName}) : super(key: key);

  @override
  State<NodeSummaryCard> createState() => _NodeSummaryCardState();
}

class _NodeSummaryCardState extends State<NodeSummaryCard> {
  int nodeCount = 0;
  String fileContent = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNodeInfo();
  }

  Future<void> fetchNodeInfo() async {
    setState(() { loading = true; });
    try {
      final bytes = await widget.client.read('${widget.webdavPath}/${widget.subscribeFileName}');
      fileContent = String.fromCharCodes(bytes);
      nodeCount = fileContent.trim().isEmpty ? 0 : fileContent.trim().split('\n').length;
    } catch (e) {
      fileContent = '';
      nodeCount = 0;
    }
    setState(() { loading = false; });
  }

  Future<void> resetNodes() async {
    await widget.client.write('${widget.webdavPath}/${widget.subscribeFileName}', Uint8List(0));
    await fetchNodeInfo();
    EasyLoading.showSuccess('已重置');
  }

  Future<void> copyAll() async {
    setState(() { loading = true; });
    try {
      final filePath = '${widget.webdavPath}/${widget.subscribeFileName}';
      final data = await widget.client.read(filePath);
      final content = String.fromCharCodes(data);
      if (content.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: content));
        EasyLoading.showSuccess('已复制全部');
      } else {
        EasyLoading.showInfo('无节点可复制');
      }
    } catch (e) {
      EasyLoading.showError('复制失败: ${e.toString()}');
    } finally {
      setState(() { loading = false; });
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
        child: loading
            ? const SizedBox(height: 28, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('节点总数: $nodeCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: resetNodes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('重置', style: TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: copyAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('全部复制', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
