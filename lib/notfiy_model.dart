import 'package:flutter/material.dart';

class NotifyModel extends ChangeNotifier {
  void notify() => notifyListeners();
}
