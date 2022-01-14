import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class CreateRemind extends StatefulWidget {
  const CreateRemind({Key? key}) : super(key: key);

  @override
  _CreateRemindState createState() => _CreateRemindState();
}

final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
final DateFormat timeFormat = DateFormat('HH:mm');
DateTime nowJp() => DateTime.now();

class _CreateRemindState extends State<CreateRemind> {
  String _title = '';

  DateTime _targetDate = nowJp();
  Future<void> _setDate(BuildContext context) async {
    var picked = await DatePicker.showDatePicker(
      context,
      currentTime: _targetDate,
      locale: LocaleType.jp,
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  DateTime _targetTime = nowJp();
  Future<void> _setTime(BuildContext context) async {
    var picked = await DatePicker.showTimePicker(
      context,
      currentTime: _targetTime,
      locale: LocaleType.jp,
      showSecondsColumn: false,
    );
    if (picked != null) {
      setState(() {
        _targetTime = picked;
      });
    }
  }

  AlertDialog _alertDialog(BuildContext context, String message) {
    return AlertDialog(
      title: const Text('Alert'),
      content: Text(message),
      actions: [
        MaterialButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('戻る'),
        )
      ],
    );
  }

  Future<void> _saveRemind(BuildContext context) async {
    if (_title == '') {
      final alert = _alertDialog(context, '何をする予定か入力してください。');
      showDialog(context: context, builder: (BuildContext context) => alert);
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final saveDate = dateFormat.format(_targetDate);
    final saveTime = timeFormat.format(_targetTime);
    final key = saveDate + saveTime + _title;
    final saved = prefs.getStringList(key);
    if (saved != null) {
      final alert = _alertDialog(context, '同一の予定を設定済です。');
      showDialog(context: context, builder: (BuildContext context) => alert);
      return;
    }

    final saveDateTime = DateTime.parse(saveDate + ' ' + saveTime + ':00');
    if (saveDateTime.difference(nowJp()).inSeconds <= 0) {
      final alert = _alertDialog(context, '現時点以降の日時を選択してください。');
      showDialog(context: context, builder: (BuildContext context) => alert);
      return;
    }

    await prefs.setStringList(key, [_title, saveDate, saveTime]);

    _scheduleNotification(key.hashCode, _title, saveDateTime);

    Navigator.pop(context, true);
    Fluttertoast.showToast(msg: '予定を作成しました。');
  }

  final remindJustBeforeMinute = -30;
  final remindPreviousDay = -1;

  void _scheduleNotification(int id, String title, DateTime dateTime) {
    final tzDateTime = tz.TZDateTime.from(dateTime, tz.local);

    if (nowJp().difference(dateTime).inMinutes <= remindJustBeforeMinute) {
      _notify30Minute(id, title, tzDateTime);
    }
    if (nowJp().difference(dateTime).inDays <= remindPreviousDay) {
      _notifyPreviousDay(id, title, tzDateTime);
    }
  }

  final notifyTitle = 'Simple Reminder';

  void _notify30Minute(int id, String title, tz.TZDateTime dateTime) {
    final localNotify = FlutterLocalNotificationsPlugin();
    localNotify.zonedSchedule(
      id,
      notifyTitle,
      '[30分前] $title',
      dateTime.add(Duration(minutes: remindJustBeforeMinute)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          '30Minute',
          '30分前リマインダー',
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: IOSNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _notifyPreviousDay(int id, String title, tz.TZDateTime dateTime) {
    final localNotify = FlutterLocalNotificationsPlugin();
    localNotify.zonedSchedule(
      id,
      notifyTitle,
      '[前日] $title',
      dateTime.add(Duration(days: remindPreviousDay)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'previousDay',
          '前日リマインダー',
        ),
        iOS: IOSNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予定作成'),
        actions: [
          IconButton(
            onPressed: () => _saveRemind(context),
            icon: const Icon(Icons.check_circle),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 5, top: 5, right: 5),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.info,
                  color: Colors.blue,
                ),
                Text(
                  'リマインドは予定日時前日と、30分前に通知されます。',
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            Flexible(
              child: Form(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                      child: TextField(
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: '何をする予定？',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _title = value;
                      });
                    },
                  )),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                          child: TextField(
                        readOnly: true,
                        onTap: () => _setDate(context),
                        controller: TextEditingController(
                            text: dateFormat.format(_targetDate)),
                        decoration: const InputDecoration(
                          labelText: '日付は？',
                        ),
                      )),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _setDate(context),
                      )
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                          child: TextField(
                        readOnly: true,
                        onTap: () => _setTime(context),
                        controller: TextEditingController(
                            text: timeFormat.format(_targetTime)),
                        decoration: const InputDecoration(
                          labelText: '時間は？',
                        ),
                      )),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () => _setTime(context),
                      )
                    ],
                  )
                ],
              )),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
