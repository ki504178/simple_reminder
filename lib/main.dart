import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:sample/components/templates/top.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notfiy_model.dart';

void main() {
  timeZoneSettings();
  runApp(const MyApp());
}

void timeZoneSettings() {
  // ローカル通知用設定
  tz.initializeTimeZones();
  // https://qiita.com/1d7678174656/items/0c2f233d70e7b678e2f7 を参考にして実装したけど、getLocalTimezon()でぬるぽになるため直接指定
  // final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  // tz.setLocalLocation(tz.getLocation(timeZoneName));
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reminder',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: ChangeNotifierProvider(
        create: (_) => NotifyModel(),
        child: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

final localNotify = FlutterLocalNotificationsPlugin();

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    // ローカル通知設定初期化
    localNotify.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_stat_access_alarm'),
      iOS: IOSInitializationSettings(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Top(localNotify: localNotify);
  }
}
