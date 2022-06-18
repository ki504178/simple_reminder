import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sample/components/molucules/confirm_dialog.dart';
import 'package:sample/components/organisms/drawer_menu.dart';
import 'package:sample/utils/date_time_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notfiy_model.dart';
import 'create_remind.dart';

class Top extends StatefulWidget {
  final FlutterLocalNotificationsPlugin localNotify;

  const Top({Key? key, required this.localNotify}) : super(key: key);

  @override
  _TopState createState() => _TopState();
}

class _TopState extends State<Top> {
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
            Icon(
              Icons.notifications_active,
              color: Colors.red,
              size: 100.0,
            ),
            Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                ),
                child: Text(
                  '''このアプリはアカウント登録やログイン不要です。
忘れがちな予定をサクッと追加して、
リマインドで気付けるようにしてくれます。
先ずは + ボタンからリマインドしたい予定を追加しましょう！！''',
                )),
          ],
        ),
      );
    }

    // 予定が近い順にソート
    keys.sort((a, b) {
      var listA = prefs.getStringList(a);
      var listB = prefs.getStringList(b);
      if (listA is List<String> && listB is List<String>) {
        final dateTimeA = DateTimeFormatter.dateTime(listA);
        final dateTimeB = DateTimeFormatter.dateTime(listB);

        return dateTimeA.compareTo(dateTimeB);
      }

      // 本来は入らないけどコンパイルエラー回避のため
      return 0;
    });

    return ListView(
        children: keys.map((key) {
      final list = prefs.getStringList(key);
      if (list is List<String>) {
        final dateTime = DateTimeFormatter.dateTime(list);
        final remainingHour = dateTime.difference(DateTime.now()).inHours;
        final remainingMinute = dateTime.difference(DateTime.now()).inMinutes;
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
          title: Text(DateTimeFormatter.displayDateTime(list)),
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
                      widget.localNotify.cancel(key.hashCode);

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
      drawer: DrawerMenu(localNotify: widget.localNotify),
      body: Consumer<NotifyModel>(
        builder: (context, model, _) {
          return Container(
            margin: const EdgeInsets.only(left: 5, right: 5),
            child: FutureBuilder(
              future: _remindList(context),
              builder: (_, AsyncSnapshot<Widget> snapshot) {
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
