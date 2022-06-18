import 'package:intl/intl.dart';

class DateTimeFormatter {
  DateTimeFormatter._() {
    throw AssertionError('private Constructor');
  }

  static DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  static DateFormat timeFormat = DateFormat('HH:mm');

  /// 画面表示表の日時に変換する
  /// [list] タイトル、日付、時間が順番に入っているリスト
  /// return 日付 + 半角スペース + 時間
  static String displayDateTime(List<String> list) {
    final yyyyMMdd = list[1];
    final hhMM = list[2];
    return yyyyMMdd + ' ' + hhMM;
  }

  /// [list] タイトル、日付、時間が順番に入っているリストからDateTimeに変換する
  static DateTime dateTime(List<String> list) {
    return DateTime.parse(displayDateTime(list) + ':00');
  }
}
