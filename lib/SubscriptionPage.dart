import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'WebDavClient.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class SubscriptionItem {
  String name;
  String url;
  String remark;
  String type; // 'clash', 'xray', 'xray+clash'
  SubscriptionItem({required this.name, required this.url, required this.remark, required this.type});

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'remark': remark,
    'type': type,
  };

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) => SubscriptionItem(
    name: json['name'] ?? '',
    url: json['url'] ?? '',
    remark: json['remark'] ?? '',
    type: json['type'] ?? 'clash',
  );
}


class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  List<SubscriptionItem> subscriptions = [];
  bool loading = true;
  bool isGridLayout = false; // 控制布局类型：false=列表，true=网格
  final String filePath = '/webdav-subscribe/subscription.json';
  late final dynamic client;

  @override
  void initState() {
    super.initState();
    client = WebDavClientService.getInstance().getClient();
    fetchSubscriptions();
  }

  Future<void> fetchSubscriptions() async {
    setState(() { loading = true; });
    try {
      final fileBytes = await client.read(filePath);
      final content = utf8.decode(fileBytes);
      final List<dynamic> jsonList = json.decode(content);
      subscriptions = jsonList.map((e) => SubscriptionItem.fromJson(e)).toList();
    } catch (e) {
      subscriptions = [];
      // 可选: 显示错误提示
    }
    setState(() { loading = false; });
  }

  Future<void> saveSubscriptions() async {
    final content = json.encode(subscriptions.map((e) => e.toJson()).toList());
    await client.write(filePath, utf8.encode(content));
  }

  void showEditDialog({SubscriptionItem? item, int? index}) {
    final nameCtrl = TextEditingController(text: item?.name ?? "");
    final urlCtrl = TextEditingController(text: item?.url ?? "");
    final remarkCtrl = TextEditingController(text: item?.remark ?? "");
    String type = item?.type ?? 'clash';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? "新增订阅" : "编辑订阅"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "名称")),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: "订阅地址")),
            TextField(controller: remarkCtrl, decoration: const InputDecoration(labelText: "备注")),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('类型:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'clash', child: Text('clash')),
                    DropdownMenuItem(value: 'xray', child: Text('xray')),
                    DropdownMenuItem(value: 'xray+clash', child: Text('xray+clash')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      type = v;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () async {
              final newItem = SubscriptionItem(
                name: nameCtrl.text,
                url: urlCtrl.text,
                remark: remarkCtrl.text,
                type: type,
              );
              setState(() {
                if (item == null) {
                  subscriptions.insert(0, newItem);
                } else if (index != null) {
                  subscriptions[index] = newItem;
                }
              });
              await saveSubscriptions();
              Navigator.pop(context);
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  void deleteSubscription(int index) async {
    setState(() {
      subscriptions.removeAt(index);
    });
    await saveSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // 顶部操作栏（新增订阅 + 布局切换）
    Widget topActionBar = Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Colors.blue[50],
              child: ListTile(
                leading: const Icon(Icons.add, color: Colors.blue),
                title: const Text("新增订阅", style: TextStyle(color: Colors.blue)),
                onTap: () => showEditDialog(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Card(
            color: Colors.purple[50],
            child: IconButton(
              icon: Icon(
                isGridLayout ? Icons.view_list : Icons.grid_view,
                color: Colors.purple,
              ),
              tooltip: isGridLayout ? "切换到列表视图" : "切换到网格视图",
              onPressed: () {
                setState(() {
                  isGridLayout = !isGridLayout;
                });
              },
            ),
          ),
        ],
      ),
    );
    
    // 列表视图
    Widget listView = ListView.builder(
      padding: const EdgeInsets.all(0), // 移除内边距，因为外部已有内边距
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final item = subscriptions[index];
        return _buildListCard(item, index);
      },
    );
    
    // 网格视图
    Widget gridView = GridView.builder(
      padding: const EdgeInsets.all(0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 每行4个
        childAspectRatio: 1.5, // 更矮的矩形
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final item = subscriptions[index];
        return _buildGridCard(item, index);
      },
    );
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: fetchSubscriptions,
          child: Column(
            children: [
              topActionBar,
              Expanded(
                child: subscriptions.isEmpty
                  ? Center(child: Text("没有订阅数据", style: TextStyle(color: Colors.grey[600])))
                  : isGridLayout ? gridView : listView,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建列表卡片
  Widget _buildListCard(SubscriptionItem item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.url,
              style: const TextStyle(color: Colors.blueAccent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.remark.isNotEmpty) Text("备注: ${item.remark}", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        trailing: _buildActionButtons(item, index),
      ),
    );
  }
  
  // 构建网格卡片
  Widget _buildGridCard(SubscriptionItem item, int index) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和类型
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getTypeColor(item.type),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.type,
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // URL
            Expanded(
              child: Text(
                item.url,
                style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // 备注
            if (item.remark.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  "备注: ${item.remark}", 
                  style: TextStyle(color: Colors.grey[600], fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
            // 操作按钮
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 16),
                  tooltip: "修改",
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () => showEditDialog(item: item, index: index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  tooltip: "删除",
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () => deleteSubscription(index),
                ),
                IconButton(
                  icon: Icon(Icons.flash_on, 
                    color: (item.type == 'clash' || item.type == 'xray+clash') ? Colors.blue : Colors.grey,
                    size: 16
                  ),
                  tooltip: "Clash导入",
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: (item.type == 'clash' || item.type == 'xray+clash') ? () async {
                    EasyLoading.showSuccess('正在导入.....');
                    var uri = Uri.parse(
                        'clash://install-config?url=${item.url}&name=${item.name}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      throw 'Could not launch ${item.url}';
                    }
                  } : null,
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.green, size: 16),
                  tooltip: "复制",
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: item.url));
                    EasyLoading.showSuccess('已复制到剪贴板');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 根据订阅类型获取颜色
  Color _getTypeColor(String type) {
    switch (type) {
      case 'clash': return Colors.blue;  
      case 'xray': return Colors.green;
      case 'xray+clash': return Colors.purple;
      default: return Colors.grey;
    }
  }
  
  // 构建操作按钮
  Widget _buildActionButtons(SubscriptionItem item, int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.orange),
          tooltip: "修改",
          iconSize: 20,
          padding: EdgeInsets.zero,
          onPressed: () => showEditDialog(item: item, index: index),
        ),
        const SizedBox(width: 2),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: "删除",
          iconSize: 20,
          padding: EdgeInsets.zero,
          onPressed: () => deleteSubscription(index),
        ),
        const SizedBox(width: 2),
        IconButton(
          icon: Icon(Icons.flash_on, color: (item.type == 'clash' || item.type == 'xray+clash') ? Colors.blue : Colors.grey),
          tooltip: "Clash导入",
          iconSize: 20,
          padding: EdgeInsets.zero,
          onPressed: (item.type == 'clash' || item.type == 'xray+clash') ? () async {
            EasyLoading.showSuccess('正在导入.....');
            var uri = Uri.parse(
                'clash://install-config?url=${item.url}&name=${item.name}');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri,
                  mode: LaunchMode.externalApplication);
            } else {
              throw 'Could not launch ${item.url}';
            }
          } : null,
        ),
        const SizedBox(width: 2),
        IconButton(
          icon: const Icon(Icons.copy, color: Colors.green),
          tooltip: "复制",
          iconSize: 20,
          padding: EdgeInsets.zero,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: item.url));
            EasyLoading.showSuccess('已复制到剪贴板');
          },
        ),
      ],
    );
  }
}