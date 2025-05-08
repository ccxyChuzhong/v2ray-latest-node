import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webdav_client/webdav_client.dart';
import 'WebDavClient.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yaml/yaml.dart';

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

// 添加Clash-Verge配置相关类
class ClashVergeItem {
  String uid;
  String type;
  String? name;
  String file;
  int updated;
  String? url;
  Map<String, dynamic>? extra;
  bool existsInSubscriptions = false;

  ClashVergeItem({
    required this.uid,
    required this.type,
    this.name,
    required this.file,
    required this.updated,
    this.url,
    this.extra,
  });

  // 从解析好的Map创建实例
  factory ClashVergeItem.fromMap(Map<dynamic, dynamic> yaml) {
    return ClashVergeItem(
      uid: yaml['uid'] ?? '',
      type: yaml['type'] ?? '',
      name: yaml['name'],
      file: yaml['file'] ?? '',
      updated: yaml['updated'] ?? 0,
      url: yaml['url'],
      extra: yaml['extra'] != null ? Map<String, dynamic>.from(yaml['extra']) : null,
    );
  }
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
  late final Client client;

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

  // 获取Clash Verge配置文件
  Future<List<ClashVergeItem>> getClashVergeConfigs() async {
    List<ClashVergeItem> result = [];
    
    try {
      final String configPath = io.Platform.environment['USERPROFILE'] ?? '';
      if (configPath.isEmpty) {
        EasyLoading.showError('无法获取用户文件夹路径');
        return [];
      }
      
      final String vergeConfigPath = '$configPath\\AppData\\Roaming\\io.github.clash-verge-rev.clash-verge-rev\\profiles.yaml';
      
      final io.File file = io.File(vergeConfigPath);
      if (await file.exists()) {
        final String content = await file.readAsString();
        
        // 使用yaml库解析内容
        final dynamic yamlDoc = loadYaml(content);
        
        if (yamlDoc is YamlMap && yamlDoc['items'] is YamlList) {
          final YamlList items = yamlDoc['items'] as YamlList;
          
          if (items.isEmpty) {
            EasyLoading.showInfo('Clash Verge配置文件中没有找到订阅项');
            return [];
          }
          
          for (var item in items) {
            if (item is YamlMap) {
              final ClashVergeItem vergeItem = ClashVergeItem.fromMap(item);
              
              // 只处理带URL的配置项
              if (vergeItem.url != null && vergeItem.url!.isNotEmpty) {
                // 检查是否已存在于当前订阅中
                vergeItem.existsInSubscriptions = subscriptions.any((s) => s.url == vergeItem.url);
                result.add(vergeItem);
              }
            }
          }
          
          if (result.isEmpty) {
            EasyLoading.showInfo('Clash Verge配置文件中没有找到有效的URL订阅');
          }
        } else {
          EasyLoading.showError('Clash Verge配置文件格式不正确');
        }
      } else {
        EasyLoading.showError('未找到Clash Verge配置文件: $vergeConfigPath');
      }
    } catch (e) {
      EasyLoading.showError('读取配置文件失败: $e');
    }
    
    return result;
  }

  // 显示Clash Verge配置列表弹窗
  void showVergeConfigsDialog() async {
    EasyLoading.show(status: '正在读取Clash Verge配置...');
    final List<ClashVergeItem> configs = await getClashVergeConfigs();
    EasyLoading.dismiss();
    
    if (configs.isEmpty) {
      EasyLoading.showInfo('没有找到有效的订阅配置');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clash Verge订阅'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6, // 限制高度
          child: Column(
            children: [
              Text('找到${configs.length}个订阅配置', style: const TextStyle(color: Colors.blue)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: configs.length,
                  itemBuilder: (context, index) {
                    final item = configs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          item.name ?? item.uid,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.url ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.existsInSubscriptions ? '状态: 已存在' : '状态: 未添加',
                              style: TextStyle(
                                fontSize: 12,
                                color: item.existsInSubscriptions ? Colors.grey : Colors.green,
                                fontWeight: item.existsInSubscriptions ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            color: item.existsInSubscriptions ? Colors.grey : Colors.blue,
                          ),
                          tooltip: "添加到订阅列表",
                          onPressed: item.existsInSubscriptions 
                            ? null 
                            : () => _addVergeConfigToSubscription(item, context),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _addAllVergeConfigs(configs, context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('全部添加'),
          ),
        ],
      ),
    );
  }
  
  // 将Verge配置添加到订阅
  void _addVergeConfigToSubscription(ClashVergeItem item, BuildContext dialogContext) async {
    if (item.url == null || item.url!.isEmpty) return;
    
    final newSubscription = SubscriptionItem(
      name: item.name ?? item.uid,
      url: item.url!,
      remark: '从Clash Verge导入',
      type: 'clash',
    );
    
    setState(() {
      subscriptions.insert(0, newSubscription);
    });
    
    await saveSubscriptions();
    EasyLoading.showSuccess('添加成功');
    
    // 更新状态
    item.existsInSubscriptions = true;
    (dialogContext as Element).markNeedsBuild();
  }
  
  // 批量添加所有未添加的配置
  void _addAllVergeConfigs(List<ClashVergeItem> configs, BuildContext dialogContext) async {
    int addedCount = 0;
    
    for (var item in configs) {
      if (!item.existsInSubscriptions && item.url != null && item.url!.isNotEmpty) {
        final newSubscription = SubscriptionItem(
          name: item.name ?? item.uid,
          url: item.url!,
          remark: '从Clash Verge导入',
          type: 'clash',
        );
        
        subscriptions.insert(0, newSubscription);
        item.existsInSubscriptions = true;
        addedCount++;
      }
    }
    
    if (addedCount > 0) {
      setState(() {});
      await saveSubscriptions();
      EasyLoading.showSuccess('成功添加$addedCount个订阅');
    } else {
      EasyLoading.showInfo('没有可添加的订阅');
    }
    
    Navigator.pop(dialogContext);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // 判断是否为手机端（Android/iOS 且屏幕宽度小于600）
    bool isMobile = (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS) &&
                    MediaQuery.of(context).size.width < 600;

    int crossAxisCount = isMobile ? 3 : 5;
    double aspectRatio = isMobile ? 0.8 : 1.4;
      
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
          // 添加Clash Verge配置获取按钮 - 仅在非移动端显示
          if (!isMobile) // 使用条件判断，移动端不显示
            Card(
              color: Colors.amber[50],
              child: IconButton(
                icon: const Icon(Icons.file_download, color: Colors.amber),
                tooltip: "获取Clash Verge配置",
                onPressed: () => showVergeConfigsDialog(),
              ),
            ),
          if (!isMobile) // 如果显示了上面的按钮，也要显示间距
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
    Widget listView = ReorderableListView.builder(
      padding: const EdgeInsets.all(0), // 移除内边距，因为外部已有内边距
      itemCount: subscriptions.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = subscriptions.removeAt(oldIndex);
          subscriptions.insert(newIndex, item);
        });
        saveSubscriptions(); // 保存更新后的顺序
      },
      buildDefaultDragHandles: false, // 不使用默认的拖动手柄
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            return Material(
              elevation: 4.0,
              color: Colors.transparent,
              shadowColor: Colors.blue.withOpacity(0.4),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final item = subscriptions[index];
        return _buildListCard(item, index);
      },
    );

    // 网格视图
    Widget gridView = GridView.builder(
      padding: const EdgeInsets.all(0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount, // 每行4个
        childAspectRatio: aspectRatio, // 更矮的矩形
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
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Center(child: Text("没有订阅数据", style: TextStyle(color: Colors.grey[600]))),
                        ),
                      ],
                    )
                  : (isGridLayout ? gridView : listView),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建列表卡片
  Widget _buildListCard(SubscriptionItem item, int index) {
    // 判断是否是移动设备
    final bool isMobileView = MediaQuery.of(context).size.width < 600;
    
    // 四个按钮，每个宽度30，至少需要120宽度
    final double minButtonAreaWidth = 120.0;
    
    // 根据屏幕宽度和设备类型计算按钮区域宽度
    final screenWidth = MediaQuery.of(context).size.width;
    double dynamicButtonWidth;
    
    if (isMobileView) {
      // 在移动设备上使用更大比例但更窄的最小宽度
      dynamicButtonWidth = screenWidth * 0.35; // 屏幕宽度的35%
      dynamicButtonWidth = dynamicButtonWidth.clamp(minButtonAreaWidth, 160.0); // 移动设备上的范围
    } else {
      // 在桌面设备上有更多空间
      dynamicButtonWidth = screenWidth * 0.22; // 屏幕宽度的22%
      dynamicButtonWidth = dynamicButtonWidth.clamp(minButtonAreaWidth, 200.0); // 桌面设备上的范围
    }
    
    return Card(
      key: ValueKey(index),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle, color: Colors.grey),
        ),
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
        trailing: SizedBox(
          width: dynamicButtonWidth, // 动态宽度
          child: _buildActionButtons(item, index, isMobileView: isMobileView),
        ),
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
            const Divider(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 修改按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => showEditDialog(item: item, index: index),
                    child: Tooltip(
                      message: "修改",
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.edit, color: Colors.orange, size: 10),
                      ),
                    ),
                  ),
                ),
                
                // 删除按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => deleteSubscription(index),
                    child: Tooltip(
                      message: "删除",
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.delete, color: Colors.red, size: 10),
                      ),
                    ),
                  ),
                ),
                
                // Clash导入按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: (item.type == 'clash' || item.type == 'xray+clash') ? () async {
                      EasyLoading.showSuccess('正在导入.....');
                      var uri = Uri.parse(
                          'clash://install-config?url=${item.url}&name=${item.name}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        throw 'Could not launch ${item.url}';
                      }
                    } : null,
                    child: Tooltip(
                      message: "Clash导入",
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.flash_on, 
                          color: (item.type == 'clash' || item.type == 'xray+clash') ? Colors.blue : Colors.grey,
                          size: 10
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 复制按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: item.url));
                      EasyLoading.showSuccess('已复制到剪贴板');
                    },
                    child: Tooltip(
                      message: "复制",
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.copy, color: Colors.green, size: 10),
                      ),
                    ),
                  ),
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
  Widget _buildActionButtons(SubscriptionItem item, int index, {bool isMobileView = false}) {
    // 根据视图类型调整图标大小和内边距
    final double iconSize = isMobileView ? 16.0 : 18.0;
    // 使用更小的内边距来减少总宽度
    final double spacing = isMobileView ? 0.0 : 2.0;
    
    // 使用FittedBox包装整个Row，确保在空间不足时可以缩放
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 编辑按钮
          Container(
            width: 28,
            height: 28,
            margin: EdgeInsets.only(right: spacing),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              tooltip: "修改",
              iconSize: iconSize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(), // 移除默认约束
              onPressed: () => showEditDialog(item: item, index: index),
            ),
          ),
          
          // 删除按钮
          Container(
            width: 28,
            height: 28,
            margin: EdgeInsets.only(right: spacing),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: "删除",
              iconSize: iconSize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(), // 移除默认约束
              onPressed: () => deleteSubscription(index),
            ),
          ),
          
          // Clash导入按钮
          Container(
            width: 28,
            height: 28,
            margin: EdgeInsets.only(right: spacing),
            child: IconButton(
              icon: Icon(Icons.flash_on, color: (item.type == 'clash' || item.type == 'xray+clash') ? Colors.blue : Colors.grey),
              tooltip: "Clash导入",
              iconSize: iconSize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(), // 移除默认约束
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
          ),
          
          // 复制按钮
          Container(
            width: 28,
            height: 28,
            child: IconButton(
              icon: const Icon(Icons.copy, color: Colors.green),
              tooltip: "复制",
              iconSize: iconSize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(), // 移除默认约束
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: item.url));
                EasyLoading.showSuccess('已复制到剪贴板');
              },
            ),
          ),
        ],
      ),
    );
  }
}