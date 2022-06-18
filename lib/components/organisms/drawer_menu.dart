import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/src/provider.dart';
import 'package:sample/components/molucules/confirm_dialog.dart';
import 'package:sample/utils/date_time_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../notfiy_model.dart';

class DrawerMenu extends StatefulWidget {
  final FlutterLocalNotificationsPlugin localNotify;

  const DrawerMenu({Key? key, required this.localNotify}) : super(key: key);

  @override
  _DrawerMenuState createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                            final dateTime = DateTimeFormatter.dateTime(list);
                            final remainingSecond =
                                dateTime.difference(DateTime.now()).inSeconds;
                            if (remainingSecond <= 0) {
                              prefs.remove(key);
                              widget.localNotify.cancel(key.hashCode);
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
                        widget.localNotify.cancelAll();

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
    );
  }
}
