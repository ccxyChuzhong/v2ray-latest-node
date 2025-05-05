import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'SwitchPage.dart';
import 'WebDavClient.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfig.loadCredentials();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    WebDavClientService.getInstance();

    return MaterialApp(
      title: 'KaiDao',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SwitchPage(),
      builder: EasyLoading.init(),
    );
  }
}
