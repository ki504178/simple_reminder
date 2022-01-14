import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/components/templates/create_remind.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import 'components/molucules/confirm_dialog.dart';

Future<void> main() async {
  await timeZoneSettings();
  runApp(const MyApp());
}

Future<void> timeZoneSettings() async {
  // ローカル通知用設定
  tz.initializeTimeZones();
  // https://qiita.com/1d7678174656/items/0c2f233d70e7b678e2f7 を参考にして実装したけど、getLocalTimezon()でぬるぽになるため直接指定
  // final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  // tz.setLocalLocation(tz.getLocation(timeZoneName));
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
}

class NotifyModel extends ChangeNotifier {
  void notify() => notifyListeners();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
final DateFormat timeFormat = DateFormat('HH:mm');
DateTime nowJp() => DateTime.now();

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

  String _formatDateTime(List<String> list) {
    final yyyyMMdd = list[1];
    final hhMM = list[2];
    return yyyyMMdd + ' ' + hhMM;
  }

  Future<Widget> _remindList(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    if (keys.isEmpty) {
      return SizedBox(
        width: 500,
        height: 500,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Center(
              child: Flexible(
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.red,
                  size: 100.0,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
              ),
              child: Flexible(
                  child: Text(
                '''このアプリはアカウント登録やログイン不要です。
忘れがちな予定をサクッと追加して、
リマインドで気付けるようにてくれます。
先ずは + ボタンからリマインドしたい予定を追加しましょう！！''',
                style: TextStyle(),
              )),
            ),
          ],
        ),
      );
    }

    // 予定が近い順にソート
    keys.sort((a, b) {
      var listA = prefs.getStringList(a);
      var listB = prefs.getStringList(b);
      if (listA is List<String> && listB is List<String>) {
        final dateTimeA = DateTime.parse(_formatDateTime(listA) + ':00');
        final dateTimeB = DateTime.parse(_formatDateTime(listB) + ':00');

        return dateTimeA.compareTo(dateTimeB);
      }

      // 本来は入らないけどコンパイルエラー回避のため
      return 0;
    });

    return ListView(
        children: keys.map((key) {
      var list = prefs.getStringList(key);
      if (list is List<String>) {
        final dateTimeStr = _formatDateTime(list);
        final dateTime = DateTime.parse(dateTimeStr + ':00');
        final remainingHour = dateTime.difference(nowJp()).inHours;
        final remainingMinute = dateTime.difference(nowJp()).inMinutes;
        final remainingMessage = remainingHour.clamp(1, 23) == remainingHour
            ? '予定まで 約 $remainingHour 時間'
            : remainingHour >= 24
                ? '予定まで 約 ${dateTime.difference(DateTime.now()).inDays} 日'
                : remainingMinute > 0 && remainingMinute < 60
                    ? '予定まで 約 $remainingMinute 分'
                    : remainingMinute == 0
                        ? '予定時間です'
                        : '予定時間を過ぎています';
        final isOver = remainingMessage == '予定時間を過ぎています';
        final fontWeight = isOver ? FontWeight.bold : FontWeight.normal;
        final color = isOver ? Colors.red : Colors.black;

        final title = list[0];
        return ListTile(
          title: Text(dateTimeStr),
          subtitle: Text(title),
          trailing: Text(
            remainingMessage,
            style: TextStyle(
              fontWeight: fontWeight,
              color: color,
            ),
          ),
          onTap: () => showDialog(
              context: context,
              builder: (_) => ConfirmDialog(
                    content: '選択した予定($title)を削除します。よろしいですか？',
                    onPressedOk: () {
                      prefs.remove(key);
                      localNotify.cancel(key.hashCode);

                      context.read<NotifyModel>().notify();
                      Navigator.pop(context);
                      Fluttertoast.showToast(msg: '予定($title)を削除しました。');
                    },
                  )),
        );
      } else {
        throw Exception('システム異常：SharedPreferenceにkey($key)はあるがデータがない');
      }
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Simple Reminder')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<NotifyModel>().notify(),
            tooltip: '最新の一覧を表示',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('過去の予定を削除'),
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => ConfirmDialog(
                        content: '過去の予定をすべて削除します。よろしいですか？',
                        onPressedOk: () async {
                          final prefs = await SharedPreferences.getInstance();
                          prefs.getKeys().toList().forEach((key) {
                            final list = prefs.getStringList(key);
                            if (list is List<String>) {
                              final dateTimeStr = _formatDateTime(list);
                              final dateTime =
                                  DateTime.parse(dateTimeStr + ':00');
                              final remainingSecond =
                                  dateTime.difference(nowJp()).inSeconds;
                              if (remainingSecond <= 0) {
                                prefs.remove(key);
                                localNotify.cancel(key.hashCode);
                              }
                            } else {
                              throw Exception(
                                  'システム異常：SharedPreferenceにkey($key)はあるがデータがList<String>ではない');
                            }
                          });

                          context.read<NotifyModel>().notify();
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Fluttertoast.showToast(msg: '過去の予定を削除しました。');
                        },
                      )),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('すべての予定を削除'),
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => ConfirmDialog(
                        content: 'すべての予定を削除します。よろしいですか？',
                        onPressedOk: () async {
                          final prefs = await SharedPreferences.getInstance();
                          prefs.clear();
                          localNotify.cancelAll();

                          context.read<NotifyModel>().notify();
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Fluttertoast.showToast(msg: 'すべての予定を削除しました。');
                        },
                      )),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('プライバシーポリシー'),
              onTap: () async {
                await launch('https://ki504178.github.io/simple_reminder/');
              },
            ),
          ],
        ),
      ),
      body: Consumer<NotifyModel>(
        builder: (context, model, _) {
          return Container(
            margin: const EdgeInsets.only(left: 5, right: 5),
            child: FutureBuilder(
              future: _remindList(context),
              builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                // 非同期ガード処理
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return snapshot.requireData;
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute<bool>(
                builder: (context) => const CreateRemind(),
              ));
          if (result is bool) {
            context.read<NotifyModel>().notify();
          }
        },
        tooltip: '予定を追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
