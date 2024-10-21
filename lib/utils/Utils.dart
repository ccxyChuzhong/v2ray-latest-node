import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Utils {
  static String getFormattedDate(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  static String getFormattedTime(DateTime dateTime) {
    return "${dateTime.hour}:${dateTime.minute}";
  }

  static Future<String> getPathName() async {
    // 获取应用程序目录
    Directory appDocumentDriectory = await getApplicationDocumentsDirectory();
    // 路径，Platform.pathSeparator 平台下的路径分隔符
    var path = '${appDocumentDriectory.path}${Platform.pathSeparator}DataInfo';
    // 读取对应路径下的文件夹
    var dir = Directory(path);
    if (dir.existsSync()) {
    } else {
      // 创建文件,可选参数recursive：true表示可以创建嵌套文件夹，false表示只能创建最后一级文件夹（上一级文件不存在会报错），默认false
      await dir.create(recursive: true);
    }
    return path;
  }
}
